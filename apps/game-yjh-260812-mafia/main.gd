extends Node2D

# 마피아 게임 — 서버 권위 멀티. 4~10인 파티.
# headless = 서버(ws :9109), 그 외 = 클라이언트.
# 페이즈: Lobby → Role Reveal → Night → Day → Vote → Result

const WS_PORT := 9109

func _ws_client_url() -> String:
	var env := OS.get_environment("GAME_WS_URL")
	if env != "":
		return env
	if OS.has_feature("web"):
		var url = JavaScriptBridge.eval(
			"(function(){if(window.__GAME_WS_URL__)return window.__GAME_WS_URL__;"
			+ "var p=location.protocol==='https:'?'wss:':'ws:';"
			+ "var base=location.pathname.replace(/\\/?(index\\.html)?$/,'');"
			+ "return p+'//'+location.host+base+'/ws';})()"
		)
		if typeof(url) == TYPE_STRING and not str(url).is_empty() and str(url) != "null":
			return str(url)
	return "ws://127.0.0.1:%d" % WS_PORT

const MIN_PLAYERS := 4
const NIGHT_TIME := 10.0
const DAY_TIME := 25.0
const VOTE_TIME := 15.0
const RESULT_TIME := 4.0
const TICK := 0.05

enum Phase { LOBBY, ROLE_REVEAL, NIGHT, DAY, VOTE, RESULT, GAME_OVER }
const ROLE_REVEAL_TIME := 3.0
enum Role { CITIZEN, MAFIA, POLICE, DOCTOR }

var peer := WebSocketMultiplayerPeer.new()
var is_server := false
var rng := RandomNumberGenerator.new()
var debug_mode := false
var bot_ids: Array = []
var bot_accum := 0.0
var bot_chat_accum := 0.0
const BOT_CHAT_MSGS := ["흠...", "의심스러운데?", "난 시민이야!", "마피아 아닌데...",
	"투표하자!", "누구지?", "밤에 뭔가 이상했어", "경찰 결과 어때?",
	"조용한 사람이 마피아야", "나 믿어줘!", "증거 있어?", "수상해..."]

# --- server state ---
var players := {}
var phase: Phase = Phase.LOBBY
var timer := 0.0
var accum := 0.0
var night_actions := {}
var votes := {}
var kill_target := -1
var save_target := -1
var investigated := {}
var last_killed := -1
var last_executed := -1
var last_saved := false
var winner := ""
var round_num := 0
var doctor_self_saved := false

# --- client state ---
var snap := {}
var hud: Label
var chat_input: LineEdit
var chat_log: Array = []
const CHAT_MAX := 15
var my_action_done := false
var death_flash := 0.0
var death_flash_id := -1
var click_pulse_id := -1
var click_pulse_t := 0.0
var click_ok := false
var phase_announce := ""
var phase_announce_t := 0.0
var phase_flash := 0.0
var anim_t := 0.0
var tex_body: Texture2D
var tex_shirt: Texture2D
var tex_bg_night: Texture2D
var tex_bg_day: Texture2D
var tex_icon_mafia: Texture2D
var tex_icon_police: Texture2D
var tex_icon_doctor: Texture2D
var tex_icon_citizen: Texture2D
var tex_title: Texture2D
var tex_card_mafia: Texture2D
var tex_card_police: Texture2D
var tex_card_doctor: Texture2D
var tex_card_citizen: Texture2D
var tex_moon: Texture2D
var tex_sun: Texture2D
var tex_banner_win: Texture2D
var tex_banner_lose: Texture2D
var tex_bubble: Texture2D
var tex_icon_vote: Texture2D
var tex_icon_kill: Texture2D
# new visual assets
var tex_frame_hud: Texture2D
var tex_frame_chat: Texture2D
var tex_frame_nameplate: Texture2D
var tex_frame_timer: Texture2D
var tex_fx_kill: Texture2D
var tex_fx_save: Texture2D
var tex_fx_investigate: Texture2D
var tex_fx_ghost: Texture2D
var tex_fx_vote_hand: Texture2D
var tex_fox_dead: Texture2D
var tex_fox_speak: Texture2D
var tex_banner_night: Texture2D
var tex_banner_day_phase: Texture2D
var tex_banner_vote_phase: Texture2D
var tex_badge_round: Texture2D
var fx_kill_t := 0.0
var fx_kill_target := -1
var fx_save_t := 0.0
var fx_save_target := -1
var last_chat_sender := -1
const SPRITE_SZ := 120.0
const SPRITE_HALF := 60.0
const ICON_SZ := 44.0

func _ready() -> void:
	rng.randomize()
	is_server = DisplayServer.get_name() == "headless"
	if is_server:
		_start_server()
	else:
		_start_client()

# ==================== SERVER ====================

func _start_server() -> void:
	debug_mode = "--debug" in OS.get_cmdline_user_args() or "--debug" in OS.get_cmdline_args()
	peer.create_server(WS_PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_join)
	multiplayer.peer_disconnected.connect(_on_leave)
	if debug_mode:
		print("mafia server [DEBUG MODE] on ws://localhost:%d" % WS_PORT)
		_spawn_bots(3)
	else:
		print("mafia server on ws://localhost:%d" % WS_PORT)

func _spawn_bots(count: int) -> void:
	for i in count:
		var bid := -(i + 1)
		bot_ids.append(bid)
		players[bid] = {"role": Role.CITIZEN, "alive": true, "hue": rng.randf(), "spectator": false}
	print("  spawned %d bots: %s" % [count, str(bot_ids)])
	_check_auto_start()

func _bot_act(delta: float) -> void:
	if not debug_mode or bot_ids.is_empty():
		return
	bot_accum += delta
	if bot_accum < 0.8:
		return
	bot_accum = 0.0
	for bid in bot_ids:
		if not players.has(bid) or not players[bid]["alive"]:
			continue
		if phase == Phase.NIGHT and players[bid]["role"] != Role.CITIZEN and not night_actions.has(bid):
			var targets := _alive_ids()
			targets.erase(bid)
			if players[bid]["role"] == Role.DOCTOR:
				targets.append(bid)
			if targets.size() > 0:
				night_actions[bid] = targets[rng.randi_range(0, targets.size() - 1)]
				_check_night_skip()
		elif phase == Phase.VOTE and not votes.has(bid):
			var targets := _alive_ids()
			targets.erase(bid)
			if targets.size() > 0:
				var pick: int
				if players[bid]["role"] == Role.MAFIA:
					# mafia bots never vote for each other
					var safe := []
					for t in targets:
						if players.has(t) and players[t]["role"] != Role.MAFIA:
							safe.append(t)
					pick = safe[rng.randi_range(0, safe.size() - 1)] if safe.size() > 0 else targets[0]
				elif players[bid]["role"] == Role.POLICE and investigated.has(bid):
					# police bot votes for confirmed mafia
					var inv: Dictionary = investigated[bid]
					if inv.get("is_mafia", false) and targets.has(inv["target"]):
						pick = inv["target"]
					else:
						pick = targets[rng.randi_range(0, targets.size() - 1)]
				else:
					pick = targets[rng.randi_range(0, targets.size() - 1)]
				votes[bid] = pick
				_check_vote_skip()
	# bot chat during DAY
	bot_chat_accum += delta
	if phase == Phase.DAY and bot_chat_accum > 3.0:
		bot_chat_accum = 0.0
		var alive_bots := []
		for bid in bot_ids:
			if players.has(bid) and players[bid]["alive"]:
				alive_bots.append(bid)
		if alive_bots.size() > 0:
			var talker: int = alive_bots[rng.randi_range(0, alive_bots.size() - 1)]
			var msg: String = BOT_CHAT_MSGS[rng.randi_range(0, BOT_CHAT_MSGS.size() - 1)]
			_srv_broadcast_chat(talker, msg)

func _on_join(id: int) -> void:
	if phase != Phase.LOBBY and phase != Phase.GAME_OVER:
		players[id] = {"role": Role.CITIZEN, "alive": false, "hue": rng.randf(), "spectator": true}
		return
	players[id] = {"role": Role.CITIZEN, "alive": true, "hue": rng.randf(), "spectator": false}
	_check_auto_start()

func _on_leave(id: int) -> void:
	players.erase(id)
	night_actions.erase(id)
	votes.erase(id)
	if phase == Phase.LOBBY or phase == Phase.GAME_OVER or phase == Phase.ROLE_REVEAL:
		return
	if _alive_count() < 3:
		phase = Phase.LOBBY
		_reset_game()
		_check_auto_start()
		return
	if _check_win():
		return
	if phase == Phase.NIGHT:
		_check_night_skip()
	elif phase == Phase.VOTE:
		_check_vote_skip()

func _check_auto_start() -> void:
	if players.size() >= MIN_PLAYERS and phase == Phase.LOBBY:
		_start_game()

func _start_game() -> void:
	round_num = 0
	winner = ""
	var ids := players.keys()
	ids.shuffle()
	var n := ids.size()
	# 4p=1, 5-6p=2, 7-8p=2, 9-10p=3
	var mafia_count := 1
	if n >= 5:
		mafia_count = 2
	if n >= 9:
		mafia_count = 3
	for i in n:
		players[ids[i]]["alive"] = true
		if i < mafia_count:
			players[ids[i]]["role"] = Role.MAFIA
		elif i == mafia_count:
			players[ids[i]]["role"] = Role.POLICE
		elif i == mafia_count + 1 and n >= 5:
			players[ids[i]]["role"] = Role.DOCTOR
		else:
			players[ids[i]]["role"] = Role.CITIZEN
	phase = Phase.ROLE_REVEAL
	timer = ROLE_REVEAL_TIME

func _enter_night() -> void:
	round_num += 1
	phase = Phase.NIGHT
	timer = NIGHT_TIME
	night_actions.clear()
	investigated.clear()
	last_killed = -1
	last_executed = -1
	last_saved = false

func _enter_day() -> void:
	_resolve_night()
	if _check_win():
		return
	phase = Phase.DAY
	timer = DAY_TIME

func _resolve_night() -> void:
	var mafia_votes := {}
	for id in night_actions:
		if players.has(id) and players[id]["role"] == Role.MAFIA:
			var t: int = night_actions[id]
			if players.has(t) and players[t]["alive"]:
				mafia_votes[t] = mafia_votes.get(t, 0) + 1
	kill_target = -1
	var best := 0
	var tie := false
	for t in mafia_votes:
		if mafia_votes[t] > best:
			best = mafia_votes[t]
			kill_target = t
			tie = false
		elif mafia_votes[t] == best:
			tie = true
	if tie:
		kill_target = -1
	save_target = -1
	for id in night_actions:
		if players.has(id) and players[id]["role"] == Role.DOCTOR and players[id]["alive"]:
			save_target = night_actions[id]
			break
	for id in night_actions:
		if players.has(id) and players[id]["role"] == Role.POLICE and players[id]["alive"]:
			var t: int = night_actions[id]
			if players.has(t):
				investigated[id] = {"target": t, "is_mafia": players[t]["role"] == Role.MAFIA}
	last_saved = (kill_target == save_target and kill_target != -1)
	# track doctor self-save
	for id in night_actions:
		if players.has(id) and players[id]["role"] == Role.DOCTOR and night_actions[id] == id:
			doctor_self_saved = true
	if kill_target != -1 and not last_saved:
		if players.has(kill_target):
			players[kill_target]["alive"] = false
			last_killed = kill_target
	else:
		last_killed = -1

func _enter_vote() -> void:
	phase = Phase.VOTE
	timer = VOTE_TIME
	votes.clear()

func _resolve_vote() -> void:
	var tally := {}
	for voter in votes:
		var t: int = votes[voter]
		if players.has(t):
			tally[t] = tally.get(t, 0) + 1
	var best_count := 0
	var best_id := -1
	var tie := false
	for t in tally:
		if tally[t] > best_count:
			best_count = tally[t]
			best_id = t
			tie = false
		elif tally[t] == best_count:
			tie = true
	if tie or best_id == -1:
		last_executed = -1
	else:
		last_executed = best_id
		if players.has(best_id):
			players[best_id]["alive"] = false

func _enter_result() -> void:
	phase = Phase.RESULT
	timer = RESULT_TIME

func _check_win() -> bool:
	var mafia_alive := 0
	var citizen_alive := 0
	for id in players:
		if players[id]["alive"]:
			if players[id]["role"] == Role.MAFIA:
				mafia_alive += 1
			else:
				citizen_alive += 1
	if mafia_alive == 0:
		winner = "citizen"
		phase = Phase.GAME_OVER
		timer = 10.0
		return true
	if mafia_alive >= citizen_alive:
		winner = "mafia"
		phase = Phase.GAME_OVER
		timer = 10.0
		return true
	return false

func _alive_count() -> int:
	var c := 0
	for id in players:
		if players[id]["alive"]:
			c += 1
	return c

func _alive_ids() -> Array:
	var out := []
	for id in players:
		if players[id]["alive"]:
			out.append(id)
	return out

func _reset_game() -> void:
	for id in players:
		players[id]["alive"] = true
		players[id]["role"] = Role.CITIZEN
		players[id]["spectator"] = false
	round_num = 0
	winner = ""
	doctor_self_saved = false

func _check_night_skip() -> void:
	var all_done := true
	for pid in players:
		if players[pid]["alive"] and players[pid]["role"] != Role.CITIZEN:
			if not night_actions.has(pid):
				all_done = false
				break
	if all_done and timer > 0.5:
		timer = 0.5

func _check_vote_skip() -> void:
	var all_voted := true
	for pid in players:
		if players[pid]["alive"] and not votes.has(pid):
			all_voted = false
			break
	if all_voted and timer > 1.0:
		timer = 1.0

func _physics_process(delta: float) -> void:
	if not is_server:
		return
	if phase == Phase.LOBBY:
		pass
	elif phase == Phase.ROLE_REVEAL:
		timer -= delta
		if timer <= 0.0:
			_enter_night()
	elif phase != Phase.GAME_OVER:
		timer -= delta
		if timer <= 0.0:
			match phase:
				Phase.NIGHT:
					_enter_day()
				Phase.DAY:
					_enter_vote()
				Phase.VOTE:
					_resolve_vote()
					_enter_result()
				Phase.RESULT:
					if not _check_win():
						_enter_night()
	else:
		timer -= delta
		if timer <= 0.0:
			phase = Phase.LOBBY
			_reset_game()
			_check_auto_start()
	_bot_act(delta)
	accum += delta
	if accum >= TICK:
		accum = 0.0
		_broadcast()

func _broadcast() -> void:
	var vote_tally := {}
	var vote_map := {}
	if phase == Phase.VOTE or phase == Phase.RESULT:
		for voter in votes:
			var t: int = votes[voter]
			vote_tally[t] = vote_tally.get(t, 0) + 1
		vote_map = votes.duplicate(true)
	var total_alive := 0
	for pid in players:
		if players[pid]["alive"]:
			total_alive += 1
	for id in players:
		if id < 0:
			continue
		var p_visible := {}
		for pid in players:
			var d: Dictionary = players[pid]
			var role_val: int = Role.CITIZEN
			if pid == id:
				role_val = d["role"]
			elif phase == Phase.GAME_OVER or not d["alive"]:
				role_val = d["role"]
			elif d["role"] == Role.MAFIA and players.has(id) and players[id]["role"] == Role.MAFIA:
				role_val = Role.MAFIA
			p_visible[pid] = [role_val, d["alive"], d["hue"], d.get("spectator", false)]
		var invest_info := {}
		if investigated.has(id):
			invest_info = investigated[id]
		var acted_flag := false
		if phase == Phase.NIGHT:
			acted_flag = night_actions.has(id)
		elif phase == Phase.VOTE:
			acted_flag = votes.has(id)
		cl_state.rpc_id(id, p_visible, phase, timer, last_killed, last_executed,
			last_saved, winner, round_num, invest_info, vote_tally,
			acted_flag, vote_map, total_alive)

func _srv_broadcast_chat(sender_id: int, msg: String) -> void:
	for id in players:
		if id < 0:
			continue
		cl_chat.rpc_id(id, sender_id, msg)

@rpc("any_peer", "call_remote", "reliable")
func srv_chat(msg: String) -> void:
	if not is_server:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not players.has(sender):
		return
	if msg.strip_edges().is_empty() or msg.length() > 100:
		return
	var text := msg.strip_edges()
	if not players[sender]["alive"]:
		text = "[유령] " + text
	if phase == Phase.NIGHT and players[sender]["alive"]:
		return
	_srv_broadcast_chat(sender, text)

@rpc("any_peer", "call_remote", "reliable")
func srv_night_action(target: int) -> void:
	if not is_server or phase != Phase.NIGHT:
		return
	var id := multiplayer.get_remote_sender_id()
	if not players.has(id) or not players[id]["alive"]:
		return
	if players[id]["role"] == Role.CITIZEN:
		return
	if not players.has(target) or not players[target]["alive"]:
		return
	if target == id and players[id]["role"] != Role.DOCTOR:
		return
	if target == id and players[id]["role"] == Role.DOCTOR and doctor_self_saved:
		return
	night_actions[id] = target
	_check_night_skip()

@rpc("any_peer", "call_remote", "reliable")
func srv_vote(target: int) -> void:
	if not is_server or phase != Phase.VOTE:
		return
	var id := multiplayer.get_remote_sender_id()
	if not players.has(id) or not players[id]["alive"]:
		return
	if not players.has(target) or not players[target]["alive"] or target == id:
		return
	votes[id] = target
	_check_vote_skip()

@rpc("authority", "call_remote", "unreliable")
func cl_state(p: Dictionary, ph: int, t: float, lk: int, le: int,
		ls: bool, win: String, rn: int, inv: Dictionary, vt: Dictionary,
		acted: bool, vm: Dictionary = {}, alive_total: int = 0) -> void:
	var prev_phase: int = snap.get("phase", Phase.LOBBY)
	var prev_killed: int = snap.get("last_killed", -1)
	var prev_executed: int = snap.get("last_executed", -1)
	snap = {"players": p, "phase": ph, "timer": t, "last_killed": lk,
		"last_executed": le, "last_saved": ls, "winner": win, "round": rn,
		"investigate": inv, "vote_tally": vt, "acted": acted,
		"vote_map": vm, "alive_total": alive_total}
	if ph == Phase.NIGHT and not acted:
		my_action_done = false
	elif ph == Phase.VOTE and not acted:
		my_action_done = false
	if ph == Phase.DAY and prev_phase == Phase.NIGHT:
		if lk != -1 and prev_killed != lk:
			death_flash = 1.0
			death_flash_id = lk
			fx_kill_t = 0.6
			fx_kill_target = lk
		if ls:
			fx_save_t = 0.8
			fx_save_target = -1
	if ph == Phase.RESULT and le != -1 and prev_executed != le:
		death_flash = 1.0
		death_flash_id = le
		fx_kill_t = 0.6
		fx_kill_target = le
	if ph != prev_phase:
		phase_flash = 0.15
		match ph:
			Phase.NIGHT: phase_announce = "밤이 되었습니다"
			Phase.DAY: phase_announce = "낮이 밝았습니다"
			Phase.VOTE: phase_announce = "투표 시간"
			Phase.RESULT: phase_announce = "결과 발표"
			Phase.GAME_OVER:
				phase_announce = "마피아 승리!" if win == "mafia" else "시민 승리!"
			Phase.ROLE_REVEAL: phase_announce = "역할 공개"
			_: phase_announce = ""
		phase_announce_t = 2.5

@rpc("authority", "call_remote", "reliable")
func cl_chat(sender_id: int, msg: String) -> void:
	var hue := 0.0
	if not snap.is_empty() and snap.has("players"):
		var ps: Dictionary = snap["players"]
		if ps.has(sender_id) and ps[sender_id] is Array and ps[sender_id].size() > 2:
			hue = ps[sender_id][2]
	last_chat_sender = sender_id
	chat_log.append({"id": sender_id, "msg": msg, "hue": hue, "t": 8.0})
	if chat_log.size() > CHAT_MAX:
		chat_log.pop_front()

# ==================== CLIENT ====================

func _start_client() -> void:
	tex_body = load("res://assets/fox_body.png")
	tex_shirt = load("res://assets/fox_shirt_mask.png")
	tex_bg_night = load("res://assets/bg_night.png")
	tex_bg_day = load("res://assets/bg_day.png")
	tex_icon_mafia = load("res://assets/icon_mafia.png")
	tex_icon_police = load("res://assets/icon_police.png")
	tex_icon_doctor = load("res://assets/icon_doctor.png")
	tex_icon_citizen = load("res://assets/icon_citizen.png")
	tex_title = load("res://assets/title_mafia.png")
	tex_card_mafia = load("res://assets/card_mafia.png")
	tex_card_police = load("res://assets/card_police.png")
	tex_card_doctor = load("res://assets/card_doctor.png")
	tex_card_citizen = load("res://assets/card_citizen.png")
	tex_moon = load("res://assets/moon.png")
	tex_sun = load("res://assets/sun.png")
	tex_banner_win = load("res://assets/banner_win.png")
	tex_banner_lose = load("res://assets/banner_lose.png")
	tex_bubble = load("res://assets/bubble_discuss.png")
	tex_icon_vote = load("res://assets/icon_vote.png")
	tex_icon_kill = load("res://assets/icon_kill.png")
	tex_frame_hud = load("res://assets/frame_hud.png")
	tex_frame_chat = load("res://assets/frame_chat.png")
	tex_frame_nameplate = load("res://assets/frame_nameplate.png")
	tex_frame_timer = load("res://assets/frame_timer.png")
	tex_fx_kill = load("res://assets/fx_kill_slash.png")
	tex_fx_save = load("res://assets/fx_save_shield.png")
	tex_fx_investigate = load("res://assets/fx_investigate.png")
	tex_fx_ghost = load("res://assets/fx_death_ghost.png")
	tex_fx_vote_hand = load("res://assets/fx_vote_hand.png")
	tex_fox_dead = load("res://assets/fox_dead.png")
	tex_fox_speak = load("res://assets/fox_speak.png")
	tex_banner_night = load("res://assets/banner_night.png")
	tex_banner_day_phase = load("res://assets/banner_day.png")
	tex_banner_vote_phase = load("res://assets/banner_vote.png")
	tex_badge_round = load("res://assets/badge_round.png")
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(20, 14)
	hud.add_theme_font_size_override("font_size", 28)
	canvas.add_child(hud)
	hud.text = "접속 중..."
	# chat input
	chat_input = LineEdit.new()
	chat_input.placeholder_text = "채팅 입력... (Enter로 전송)"
	chat_input.position = Vector2(20, 660)
	chat_input.size = Vector2(460, 50)
	chat_input.add_theme_font_size_override("font_size", 24)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.5)
	sb.border_color = Color(1, 1, 1, 0.2)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	chat_input.add_theme_stylebox_override("normal", sb)
	chat_input.add_theme_color_override("font_color", Color.WHITE)
	chat_input.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.4))
	canvas.add_child(chat_input)
	chat_input.text_submitted.connect(_on_chat_submit)
	peer.create_client(_ws_client_url())
	multiplayer.multiplayer_peer = peer

func _on_chat_submit(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	srv_chat.rpc_id(1, text.strip_edges())
	chat_input.clear()

func _pname(id: int) -> String:
	return "P%d" % (id % 1000)

func _role_name(r: int) -> String:
	match r:
		Role.MAFIA: return "마피아"
		Role.POLICE: return "경찰"
		Role.DOCTOR: return "의사"
		_: return "시민"

func _role_icon(r: int) -> String:
	match r:
		Role.MAFIA: return "🔪"
		Role.POLICE: return "🔍"
		Role.DOCTOR: return "💊"
		_: return "👤"

func _role_tex(r: int) -> Texture2D:
	match r:
		Role.MAFIA: return tex_icon_mafia
		Role.POLICE: return tex_icon_police
		Role.DOCTOR: return tex_icon_doctor
		_: return tex_icon_citizen

func _role_card_tex(r: int) -> Texture2D:
	match r:
		Role.MAFIA: return tex_card_mafia
		Role.POLICE: return tex_card_police
		Role.DOCTOR: return tex_card_doctor
		_: return tex_card_citizen

func _role_color(r: int) -> Color:
	match r:
		Role.MAFIA: return Color(1.0, 0.3, 0.3)
		Role.POLICE: return Color(0.3, 0.5, 1.0)
		Role.DOCTOR: return Color(0.3, 1.0, 0.5)
		_: return Color(0.85, 0.85, 0.85)

func _seat_positions() -> Dictionary:
	if snap.is_empty() or not snap.has("players"):
		return {}
	var ids: Array = snap["players"].keys()
	ids.sort()
	var vp := get_viewport_rect().size
	var center := vp / 2.0 + Vector2(0, 0)
	var r := minf(vp.x, vp.y) * 0.26
	var out := {}
	for i in ids.size():
		var a := TAU * float(i) / float(ids.size()) - PI / 2.0
		out[ids[i]] = center + Vector2.from_angle(a) * r
	return out

func _unhandled_input(event: InputEvent) -> void:
	if is_server or snap.is_empty():
		return
	# F5 = spawn another client
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		var exe := OS.get_executable_path()
		var path := ProjectSettings.globalize_path("res://")
		OS.create_process(exe, ["--path", path])
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var my_id := multiplayer.get_unique_id()
	var ps: Dictionary = snap["players"]
	if not ps.has(my_id) or not ps[my_id][1]:
		return
	var ph: int = snap["phase"]
	var seats := _seat_positions()

	if ph == Phase.NIGHT and not my_action_done:
		var my_role: int = ps[my_id][0]
		if my_role == Role.CITIZEN:
			return
		for id in seats:
			if seats[id].distance_to(event.position) < SPRITE_HALF:
				if not ps.has(id) or not ps[id][1]:
					_click_feedback(id, false)
					return
				if id == my_id and my_role != Role.DOCTOR:
					_click_feedback(id, false)
					return
				srv_night_action.rpc_id(1, id)
				my_action_done = true
				_click_feedback(id, true)
				return

	elif ph == Phase.VOTE and not my_action_done:
		for id in seats:
			if seats[id].distance_to(event.position) < SPRITE_HALF:
				if id == my_id or not ps.has(id) or not ps[id][1]:
					_click_feedback(id, false)
					return
				srv_vote.rpc_id(1, id)
				my_action_done = true
				_click_feedback(id, true)
				return

func _click_feedback(id: int, ok: bool) -> void:
	click_pulse_id = id
	click_pulse_t = 0.25
	click_ok = ok

func _process(delta: float) -> void:
	if is_server or snap.is_empty():
		return
	anim_t += delta
	death_flash = maxf(0.0, death_flash - 2.5 * delta)
	fx_kill_t = maxf(0.0, fx_kill_t - delta)
	fx_save_t = maxf(0.0, fx_save_t - delta)
	click_pulse_t = maxf(0.0, click_pulse_t - delta)
	phase_announce_t = maxf(0.0, phase_announce_t - delta)
	phase_flash = maxf(0.0, phase_flash - delta)
	# decay chat ttl
	for c in chat_log:
		c["t"] -= delta
	_update_hud()
	queue_redraw()

func _update_hud() -> void:
	var my_id := multiplayer.get_unique_id()
	if snap.is_empty() or not snap.has("players"):
		hud.text = "접속 중..."
		return
	var ps: Dictionary = snap["players"]
	var ph: int = snap["phase"]
	var t: float = snap["timer"]
	var lines := ""
	if not ps.has(my_id):
		hud.text = "접속 중..."
		return
	var my_role: int = ps[my_id][0]
	var alive: bool = ps[my_id][1]
	match ph:
		Phase.LOBBY:
			lines = ""
		Phase.ROLE_REVEAL:
			lines = ""
		Phase.NIGHT:
			lines = "🌙 밤 %d — %.0f초" % [snap["round"], t]
			if not alive:
				lines += "\n(사망 — 관전 중)"
			elif my_role == Role.MAFIA:
				lines += "\n🔪 죽일 대상 클릭"
				if snap["acted"]:
					lines += " ✓"
			elif my_role == Role.POLICE:
				lines += "\n🔍 조사 대상 클릭"
				if snap["acted"]:
					lines += " ✓"
			elif my_role == Role.DOCTOR:
				lines += "\n💊 보호 대상 클릭"
				if snap["acted"]:
					lines += " ✓"
			else:
				lines += "\n밤이 지나가길..."
		Phase.DAY:
			lines = "☀️ 낮 %d — %.0f초 [채팅으로 토론]" % [snap["round"], t]
			if snap["last_killed"] != -1:
				lines += "\n💀 %s 살해됨!" % _pname(snap["last_killed"])
			elif snap["last_saved"]:
				lines += "\n💊 의사가 살림!"
			else:
				lines += "\n평화로운 밤"
			if not snap["investigate"].is_empty():
				var inv: Dictionary = snap["investigate"]
				if inv.has("target") and inv.has("is_mafia"):
					lines += "\n🔍 %s → %s" % [_pname(inv["target"]), "마피아!" if inv["is_mafia"] else "아님"]
		Phase.VOTE:
			lines = "🗳️ 투표 — %.0f초" % t
			if snap["acted"]:
				lines += " ✓"
		Phase.RESULT:
			lines = "📋 결과"
			if snap["last_executed"] != -1:
				var eid: int = snap["last_executed"]
				var er: int = ps[eid][0] if ps.has(eid) else Role.CITIZEN
				lines += "\n%s 처형 — %s" % [_pname(eid), _role_name(er)]
			else:
				lines += "\n무효 — 처형 없음"
		Phase.GAME_OVER:
			if snap["winner"] == "mafia":
				lines = "🔪 마피아 승리!"
			else:
				lines = "🎉 시민 승리!"
	if ph != Phase.LOBBY and ph != Phase.GAME_OVER and ph != Phase.ROLE_REVEAL:
		var at: int = snap.get("alive_total", 0)
		lines += "\n생존 %d명 | %s %s" % [at, _role_icon(my_role), _role_name(my_role)]
	hud.text = lines

func _draw() -> void:
	if is_server or snap.is_empty():
		return
	var vp := get_viewport_rect().size
	var ph: int = snap["phase"]
	var my_id := multiplayer.get_unique_id()
	var ps: Dictionary = snap.get("players", {})
	var bg_rect := Rect2(Vector2.ZERO, vp)
	var center := vp / 2.0

	# === BACKGROUND ===
	if ph == Phase.NIGHT and tex_bg_night != null:
		draw_texture_rect(tex_bg_night, bg_rect, false)
		draw_rect(bg_rect, Color(0, 0, 0, 0.35))
	elif ph == Phase.ROLE_REVEAL or ph == Phase.LOBBY:
		draw_rect(bg_rect, Color(0.08, 0.08, 0.14))
	elif tex_bg_day != null:
		draw_texture_rect(tex_bg_day, bg_rect, false)
		if ph == Phase.GAME_OVER:
			var tint := Color(0.6, 0.1, 0.1, 0.3) if snap["winner"] == "mafia" else Color(0.1, 0.5, 0.1, 0.25)
			draw_rect(bg_rect, tint)
		elif ph == Phase.VOTE:
			draw_rect(bg_rect, Color(0, 0, 0, 0.15))
	else:
		draw_rect(bg_rect, Color(0.10, 0.11, 0.16))

	if not ps.has(my_id):
		return

	# === HUD backing panel ===
	var hud_h := hud.get_line_count() * 24 + 20
	if tex_frame_hud != null:
		draw_texture_rect(tex_frame_hud, Rect2(6, 2, 420, hud_h), false, Color(1, 1, 1, 0.85))
	else:
		draw_rect(Rect2(12, 8, 400, hud_h), Color(0, 0, 0, 0.45), true)

	# === LOBBY: title ===
	if ph == Phase.LOBBY:
		if tex_title != null:
			var tw := minf(vp.x * 0.6, 500.0)
			var th := tw * 0.667
			draw_texture_rect(tex_title, Rect2(center - Vector2(tw / 2.0, th / 2.0 + 20), Vector2(tw, th)), false)
		var cnt := ps.size()
		var wait_text := "%d명 접속 중 (%d명 이상 시작)" % [cnt, MIN_PLAYERS]
		draw_rect(Rect2(center.x - 180, center.y + 120, 360, 44), Color(0, 0, 0, 0.6), true)
		draw_string(ThemeDB.fallback_font, center + Vector2(-170, 150),
			wait_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.9))

	# === ROLE_REVEAL ===
	if ph == Phase.ROLE_REVEAL:
		var my_role: int = ps[my_id][0]
		var card_tex := _role_card_tex(my_role)
		var reveal_alpha := clampf((ROLE_REVEAL_TIME - snap["timer"]) / 0.5, 0.0, 1.0)
		if card_tex != null:
			var csz := 220.0
			draw_texture_rect(card_tex, Rect2(center - Vector2(csz / 2, csz / 2), Vector2(csz, csz)), false,
				Color(1, 1, 1, reveal_alpha))
		draw_rect(Rect2(center.x - 160, center.y + 130, 320, 52), Color(0, 0, 0, 0.6 * reveal_alpha), true)
		var rc := _role_color(my_role)
		rc.a = reveal_alpha
		draw_string(ThemeDB.fallback_font, center + Vector2(-140, 164),
			"당신은 %s %s" % [_role_icon(my_role), _role_name(my_role)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 32, rc)

	# === GAME_OVER banner ===
	if ph == Phase.GAME_OVER:
		var banner := tex_banner_win if snap["winner"] == "citizen" else tex_banner_lose
		if banner != null:
			var bw := minf(vp.x * 0.45, 360.0)
			var bh := bw * 0.667
			draw_texture_rect(banner, Rect2(center - Vector2(bw / 2, bh / 2), Vector2(bw, bh)), false)
		# role list
		draw_rect(Rect2(center.x - 140, center.y + 100, 280, ps.size() * 30 + 20), Color(0, 0, 0, 0.6), true)
		var ids: Array = ps.keys()
		ids.sort()
		for i in ids.size():
			if ps.has(ids[i]):
				draw_string(ThemeDB.fallback_font, center + Vector2(-130, 124 + i * 30),
					"%s: %s %s" % [_pname(ids[i]), _role_icon(ps[ids[i]][0]), _role_name(ps[ids[i]][0])],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)

	# === NIGHT moon / DAY sun ===
	if ph == Phase.NIGHT and tex_moon != null:
		var moon_y := 30.0 + sin(anim_t * 0.8) * 8.0
		draw_texture_rect(tex_moon, Rect2(vp.x - 100, moon_y, 64, 64), false)
	if ph == Phase.DAY and tex_sun != null:
		draw_set_transform(Vector2(vp.x - 68, 56), anim_t * 0.3, Vector2.ONE)
		draw_texture_rect(tex_sun, Rect2(-32, -32, 64, 64), false)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# === Phase icons ===
	if ph == Phase.DAY and tex_bubble != null:
		draw_texture_rect(tex_bubble, Rect2(vp.x - 240, 12, 40, 40), false)
	if ph == Phase.VOTE and tex_icon_vote != null:
		draw_texture_rect(tex_icon_vote, Rect2(vp.x - 240, 12, 40, 40), false)
	if ph == Phase.DAY and snap["last_killed"] != -1 and tex_icon_kill != null:
		draw_texture_rect(tex_icon_kill, Rect2(420, 36, 36, 36), false)

	# === Players ===
	var seats := _seat_positions()
	if ph != Phase.LOBBY and ph != Phase.ROLE_REVEAL:
		if tex_badge_round != null:
			draw_texture_rect(tex_badge_round, Rect2(center - Vector2(28, 28), Vector2(56, 56)), false, Color(1, 1, 1, 0.3))
		draw_string(ThemeDB.fallback_font, center + Vector2(-12, 10),
			"%d" % snap["round"], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 1, 1, 0.25))

	var vm: Dictionary = snap.get("vote_map", {})
	if (ph == Phase.VOTE or ph == Phase.RESULT) and not vm.is_empty():
		for voter_id in vm:
			var target_id: int = vm[voter_id]
			if seats.has(voter_id) and seats.has(target_id):
				var from_pos: Vector2 = seats[voter_id]
				var to_pos: Vector2 = seats[target_id]
				var dir := (to_pos - from_pos).normalized()
				var acol := Color(1.0, 0.4, 0.3, 0.4)
				if int(voter_id) == my_id:
					acol = Color(1.0, 0.8, 0.2, 0.6)
				draw_line(from_pos + dir * SPRITE_HALF, to_pos - dir * SPRITE_HALF, acol, 2.0)

	for id in seats:
		if not ps.has(id):
			continue
		var pos: Vector2 = seats[id]
		var info: Array = ps[id]
		var role: int = info[0]
		var alive_p: bool = info[1]
		var hue: float = info[2]
		var team_col := Color.from_hsv(hue, 0.7, 0.95)
		var body_mod := Color.WHITE
		if not alive_p:
			body_mod = Color(0.45, 0.45, 0.45)
			team_col = Color(0.4, 0.4, 0.42)
		if death_flash > 0.0 and death_flash_id == id:
			body_mod = body_mod.lerp(Color(1, 0.2, 0.2), death_flash * 0.7)
			team_col = team_col.lerp(Color(1, 0.2, 0.2), death_flash * 0.7)

		# click pulse scale
		var scale := 1.0
		if click_pulse_id == id and click_pulse_t > 0.0:
			scale = 1.0 + 0.15 * (click_pulse_t / 0.25)
		var sz := SPRITE_SZ * scale
		var half := sz / 2.0
		var sprite_rect := Rect2(pos - Vector2(half, half), Vector2(sz, sz))

		# choose body texture variant
		var body_tex := tex_body
		if not alive_p and tex_fox_dead != null:
			body_tex = tex_fox_dead
		elif ph == Phase.DAY and alive_p and id == last_chat_sender and tex_fox_speak != null:
			body_tex = tex_fox_speak
		if body_tex != null:
			draw_texture_rect(body_tex, Rect2(pos - Vector2(half - 3, half - 4), Vector2(sz, sz)), false, Color(0, 0, 0, 0.2))
			draw_texture_rect(body_tex, sprite_rect, false, body_mod)
		if tex_shirt != null:
			draw_texture_rect(tex_shirt, sprite_rect, false, team_col)

		# click feedback overlay
		if click_pulse_id == id and click_pulse_t > 0.0:
			if click_ok:
				draw_string(ThemeDB.fallback_font, pos + Vector2(-10, -half - 10), "✓",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.2, 1.0, 0.3, click_pulse_t * 4.0))
			else:
				draw_string(ThemeDB.fallback_font, pos + Vector2(-10, -half - 10), "✗",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1.0, 0.2, 0.2, click_pulse_t * 4.0))

		if not alive_p:
			var is_spec: bool = info[3] if info.size() > 3 else false
			if is_spec:
				draw_string(ThemeDB.fallback_font, pos + Vector2(-14, -half - 8),
					"👀", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 1, 0.5))
			else:
				if tex_fx_ghost != null:
					var ghost_y := pos.y - half - 30.0 + sin(anim_t * 1.5) * 6.0
					draw_texture_rect(tex_fx_ghost, Rect2(pos.x - 20, ghost_y, 40, 40), false, Color(1, 1, 1, 0.6))

		if id == my_id:
			draw_arc(pos, half + 4, 0, TAU, 32, Color.WHITE, 2.5)

		var show_role: bool = (id == my_id) or (ph == Phase.GAME_OVER) or not alive_p
		if show_role and ph != Phase.LOBBY and ph != Phase.ROLE_REVEAL:
			var badge_pos := pos + Vector2(half - 12, -half + 4)
			var icon_tex := _role_tex(role)
			if icon_tex != null:
				draw_rect(Rect2(badge_pos - Vector2(2, 2), Vector2(ICON_SZ + 4, ICON_SZ + 4)), Color(0, 0, 0, 0.5), true)
				draw_texture_rect(icon_tex, Rect2(badge_pos, Vector2(ICON_SZ, ICON_SZ)), false)

		if ph == Phase.NIGHT and role == Role.MAFIA and id != my_id and alive_p:
			if ps.has(my_id) and ps[my_id][0] == Role.MAFIA:
				draw_arc(pos, half + 2, 0, TAU, 32, Color(1, 0.3, 0.3, 0.4), 2.5)

		# name plate
		var name_pos := pos + Vector2(-28, half + 18)
		if tex_frame_nameplate != null:
			draw_texture_rect(tex_frame_nameplate, Rect2(name_pos - Vector2(10, 22), Vector2(80, 30)), false, Color(1, 1, 1, 0.8))
		else:
			draw_rect(Rect2(name_pos - Vector2(6, 20), Vector2(68, 26)), Color(0, 0, 0, 0.4), true)
		draw_string(ThemeDB.fallback_font, name_pos,
			_pname(id), HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
			Color(1, 1, 1, 0.9) if alive_p else Color(0.6, 0.6, 0.6, 0.6))

		if (ph == Phase.VOTE or ph == Phase.RESULT) and alive_p:
			var vt: Dictionary = snap.get("vote_tally", {})
			if vt.has(id):
				var vc: int = vt[id]
				draw_circle(pos + Vector2(-half + 8, -half + 8), 16.0, Color(0.8, 0.2, 0.1, 0.85))
				draw_string(ThemeDB.fallback_font, pos + Vector2(-half + 1, -half + 14),
					str(vc), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

	# === Kill slash effect ===
	if fx_kill_t > 0.0 and tex_fx_kill != null and seats.has(fx_kill_target):
		var fxp: Vector2 = seats[fx_kill_target]
		var fxa := fx_kill_t / 0.6
		draw_texture_rect(tex_fx_kill, Rect2(fxp - Vector2(60, 60), Vector2(120, 120)), false, Color(1, 1, 1, fxa))

	# === Save shield effect ===
	if fx_save_t > 0.0 and tex_fx_save != null:
		var fxa2 := fx_save_t / 0.8
		draw_texture_rect(tex_fx_save, Rect2(center - Vector2(50, 50), Vector2(100, 100)), false, Color(1, 1, 1, fxa2))

	# === Vote hand effect on voted players ===
	if ph == Phase.VOTE and tex_fx_vote_hand != null:
		var vt: Dictionary = snap.get("vote_tally", {})
		for vid in vt:
			if seats.has(vid):
				var vpos: Vector2 = seats[vid]
				draw_texture_rect(tex_fx_vote_hand, Rect2(vpos + Vector2(-50, -SPRITE_HALF - 40), Vector2(36, 36)), false, Color(1, 1, 1, 0.6))

	# === Death flash overlay ===
	if death_flash > 0.0:
		draw_rect(bg_rect, Color(1, 0.1, 0.1, death_flash * 0.15))

	# === Phase transition flash ===
	if phase_flash > 0.0:
		draw_rect(bg_rect, Color(1, 1, 1, phase_flash * 3.0))

	# === Phase announce with banner texture ===
	if phase_announce_t > 0.0 and phase_announce.length() > 0:
		var alpha := clampf(phase_announce_t / 1.0, 0.0, 1.0)
		var banner_tex: Texture2D = null
		if phase_announce == "밤이 되었습니다":
			banner_tex = tex_banner_night
		elif phase_announce == "낮이 밝았습니다":
			banner_tex = tex_banner_day_phase
		elif phase_announce == "투표 시간":
			banner_tex = tex_banner_vote_phase
		if banner_tex != null:
			var bw := vp.x * 0.7
			var bh := bw * 0.4
			draw_texture_rect(banner_tex, Rect2(center.x - bw / 2, center.y - bh / 2 - 20, bw, bh), false, Color(1, 1, 1, alpha))
		draw_rect(Rect2(center.x - 200, center.y + 30, 400, 60), Color(0, 0, 0, 0.5 * alpha), true)
		draw_string(ThemeDB.fallback_font, center + Vector2(-180, 70),
			phase_announce, HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(1, 1, 1, alpha))

	# === Chat panel (bottom-left) ===
	var chat_x := 20.0
	var chat_y := vp.y - 80.0
	var visible_chats := []
	for c in chat_log:
		if c["t"] > 0.0:
			visible_chats.append(c)
	if visible_chats.size() > 0:
		var panel_h := visible_chats.size() * 28 + 12
		if tex_frame_chat != null:
			draw_texture_rect(tex_frame_chat, Rect2(chat_x - 10, chat_y - panel_h - 4, 500, panel_h + 8), false, Color(1, 1, 1, 0.7))
		else:
			draw_rect(Rect2(chat_x - 6, chat_y - panel_h, 480, panel_h), Color(0, 0, 0, 0.5), true)
		for i in visible_chats.size():
			var c: Dictionary = visible_chats[i]
			var cy := chat_y - (visible_chats.size() - i) * 28
			var col := Color.from_hsv(c["hue"], 0.6, 0.95, clampf(c["t"] / 2.0, 0.0, 1.0))
			var tcol := Color(1, 1, 1, clampf(c["t"] / 2.0, 0.0, 1.0))
			draw_string(ThemeDB.fallback_font, Vector2(chat_x, cy),
				"%s:" % _pname(c["id"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)
			draw_string(ThemeDB.fallback_font, Vector2(chat_x + 70, cy),
				c["msg"], HORIZONTAL_ALIGNMENT_LEFT, 400, 20, tcol)

	# === Phase indicator top-right ===
	var phase_text := ""
	match ph:
		Phase.LOBBY: phase_text = "대기실"
		Phase.ROLE_REVEAL: phase_text = "역할 공개"
		Phase.NIGHT: phase_text = "🌙 밤"
		Phase.DAY: phase_text = "☀️ 낮"
		Phase.VOTE: phase_text = "🗳️ 투표"
		Phase.RESULT: phase_text = "📋 결과"
		Phase.GAME_OVER: phase_text = "게임 종료"
	if tex_frame_hud != null:
		draw_texture_rect(tex_frame_hud, Rect2(vp.x - 196, 6, 190, 48), false, Color(1, 1, 1, 0.85))
	else:
		draw_rect(Rect2(vp.x - 190, 10, 180, 42), Color(0, 0, 0, 0.5), true)
	draw_string(ThemeDB.fallback_font, Vector2(vp.x - 182, 40),
		phase_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 1, 1, 0.9))

	# === Timer bar ===
	if ph != Phase.LOBBY and ph != Phase.GAME_OVER and ph != Phase.ROLE_REVEAL:
		var max_t := NIGHT_TIME
		match ph:
			Phase.DAY: max_t = DAY_TIME
			Phase.VOTE: max_t = VOTE_TIME
			Phase.RESULT: max_t = RESULT_TIME
		var ratio := clampf(snap["timer"] / max_t, 0.0, 1.0)
		var bar_w := vp.x - 40.0
		if tex_frame_timer != null:
			draw_texture_rect(tex_frame_timer, Rect2(10, vp.y - 54, bar_w + 20, 30), false, Color(1, 1, 1, 0.8))
		else:
			draw_rect(Rect2(14, vp.y - 50, bar_w + 12, 24), Color(0, 0, 0, 0.4), true)
		draw_rect(Rect2(20, vp.y - 44, bar_w, 14), Color(1, 1, 1, 0.1))
		var bar_col := Color(0.3, 0.8, 0.4) if ratio > 0.3 else Color(0.9, 0.3, 0.2)
		draw_rect(Rect2(20, vp.y - 44, bar_w * ratio, 14), bar_col)
