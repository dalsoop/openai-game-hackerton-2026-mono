extends Node2D

# 라이어 게임 — 서버 권위 멀티 파티게임 (3~8인).
# 매 라운드 한 명이 라이어. 나머지는 같은 제시어를 받는다.
# 턴제 설명 → 투표 → 라이어 적발 시 역추측 → 점수 10점 선착순 승.
# headless = 서버(ws :9110), 그 외 = 클라이언트.

const WS_PORT := 9110

func _ws_client_url() -> String:
	# 외부 허브(server-yjh-2026-hackertone-external-kr) · 로컬 개발 공용.
	# 로그인 없음. GAME_WS_URL 또는 웹 같은 origin /ws.
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

const MIN_PLAYERS := 3
const REVEAL_TIME := 7.0
const SPEAK_TIME := 12.0
const VOTE_TIME := 15.0
const GUESS_TIME := 12.0
const RESULT_TIME := 5.0
const WIN_SCORE := 7
const TICK := 0.05
const GUESS_GRID_COLS := 4
const GUESS_GRID_COUNT := 16

var peer := WebSocketMultiplayerPeer.new()
var is_server := false
var rng := RandomNumberGenerator.new()
var debug_mode := false
var bot_ids: Array = []
var bot_accum := 0.0

# ──── 제시어 DB ────
const TOPICS := {
	"동물": ["강아지","고양이","호랑이","코끼리","기린","팬더","펭귄","돌고래","독수리",
		"카피바라","악어","코알라","캥거루","다람쥐","문어","해파리","두더지","앵무새",
		"북극곰","치타","수달","비버","오리너구리","이구아나","카멜레온","고슴도치",
		"너구리","미어캣","알파카","플라밍고","하마","원숭이"],
	"음식": ["김치찌개","떡볶이","초밥","피자","햄버거","비빔밥","삼겹살","치킨","라면",
		"파스타","마라탕","냉면","짜장면","갈비찜","김밥","타코야끼","스테이크","카레",
		"쌀국수","딤섬","붕어빵","탕후루","크로플","마카롱","아이스크림","와플",
		"팟타이","리조또","규동","오므라이스","잔치국수","칼국수"],
	"장소": ["학교","병원","놀이공원","도서관","해변","공항","지하철","편의점","영화관",
		"카페","미술관","동물원","수족관","캠핑장","스키장","놀이터","볼링장","찜질방",
		"백화점","시장","경찰서","소방서","우체국","은행","대학교","교회","절",
		"수영장","축구장","야구장","호텔","기차역"],
	"직업": ["의사","소방관","경찰관","선생님","요리사","우주비행사","수의사","프로게이머",
		"연예인","유튜버","파일럿","탐정","마술사","운동선수","만화가","건축가",
		"과학자","간호사","변호사","판사","기자","사진작가","플로리스트","바리스타",
		"DJ","배우","가수","작곡가","애니메이터","게임개발자","목수","어부"],
	"스포츠": ["축구","농구","야구","배구","테니스","탁구","수영","스키","스노보드",
		"양궁","펜싱","태권도","유도","복싱","골프","볼링","배드민턴","마라톤",
		"피겨스케이팅","서핑","클라이밍","사격","체조","역도","카누","럭비",
		"핸드볼","하키","크리켓","스쿼시","다트","컬링"],
	"영화/드라마": ["해리포터","어벤져스","겨울왕국","기생충","인터스텔라","토이스토리",
		"라이온킹","스파이더맨","주토피아","짱구는못말려","원피스","나루토","슬램덩크",
		"오징어게임","이상한변호사우영우","도깨비","응답하라1988","미생","신서유기",
		"런닝맨","무한도전","스타워즈","쥬라기공원","반지의제왕","매트릭스",
		"타이타닉","백투더퓨처","위대한쇼맨","코코","인사이드아웃","모아나","알라딘"],
}

# ──── 서버 상태 ────
enum Phase { WAIT, REVEAL, SPEAK, VOTE, GUESS, RESULT }
var players := {}           # id -> {score, hue, spectator}
var phase: int = Phase.WAIT
var timer := 0.0
var round_num := 0

var liar_id := 0
var category := ""
var keyword := ""
var speaker_order: Array = []
var speaker_idx := 0

var votes := {}             # voter_id -> target_id
var guess := ""
var liar_guessed := false
var round_msg := ""
var winner_id := 0
var srv_guess_candidates: Array = []
var used_keywords: Array = []

var accum := 0.0
var srv_chat_log: Array = []
const MAX_CHAT := 30
const BOT_SPEAK_MSGS := ["음... 그거 알지?", "다들 아는 거 아닌가?", "힌트 하나 줄게...",
	"이건 좀 특별해", "생각보다 흔한 거야", "설명하기 어렵네", "한번 봤는데...",
	"어디서 본 적 있어", "꽤 유명한 거야", "음 뭐라 해야 하지"]
const BOT_LIAR_MSGS := ["아 그거... 맞지?", "당연히 알지", "다들 알잖아 그거",
	"흔한 건데...", "설명하면 너무 티 나잖아", "글쎄... 이건 좀 특이해"]
var bot_spoke := {}

# ──── 클라이언트 상태 ────
var snap := {}
var hud: Label
var tex_body: Texture2D
var tex_shirt: Texture2D
var tex_bg: Texture2D
var tex_icon_speech: Texture2D
var tex_icon_liar: Texture2D
var tex_icon_vote: Texture2D
var tex_title: Texture2D
var tex_card_word: Texture2D
var tex_card_liar: Texture2D
var tex_cat_animal: Texture2D
var tex_cat_food: Texture2D
var tex_cat_place: Texture2D
var tex_cat_job: Texture2D
var tex_cat_sports: Texture2D
var tex_cat_movie: Texture2D
var tex_scoreboard: Texture2D
var tex_trophy: Texture2D
var tex_parrot_speak: Texture2D
var tex_parrot_dead: Texture2D
var tex_banner_reveal: Texture2D
var tex_banner_speak: Texture2D
var tex_banner_vote_liar: Texture2D
var tex_btn_frame: Texture2D
var tex_spotlight: Texture2D
var my_vote := 0
var guess_candidates: Array = []
var guess_selected := -1
var anim_t := 0.0
var mouse_pos := Vector2.ZERO
var chat_log: Array = []
var chat_input: LineEdit
var chat_btn: Button
var click_pulse_id := 0
var click_pulse_t := 0.0
var phase_flash := 0.0
var phase_flash_text := ""
var shake_t := 0.0

func _ready() -> void:
	rng.randomize()
	is_server = DisplayServer.get_name() == "headless"
	if is_server:
		_start_server()
	else:
		_start_client()

# ═══════════════════════ SERVER ═══════════════════════

func _start_server() -> void:
	debug_mode = "--debug" in OS.get_cmdline_user_args() or "--debug" in OS.get_cmdline_args()
	peer.create_server(WS_PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_join)
	multiplayer.peer_disconnected.connect(_on_leave)
	if debug_mode:
		print("liar-game server [DEBUG MODE] on ws://localhost:%d" % WS_PORT)
		_spawn_bots(2)
	else:
		print("liar-game server on ws://localhost:%d" % WS_PORT)

func _spawn_bots(count: int) -> void:
	for i in count:
		var bid := -(i + 1)
		bot_ids.append(bid)
		players[bid] = {"score": 0, "hue": rng.randf(), "spectator": false}
	print("  spawned %d bots: %s" % [count, str(bot_ids)])
	if phase == Phase.WAIT and players.size() >= MIN_PLAYERS:
		_new_round()

func _bot_act(delta: float) -> void:
	if not debug_mode or bot_ids.is_empty():
		return
	bot_accum += delta
	if bot_accum < 1.0:
		return
	bot_accum = 0.0
	for bid in bot_ids:
		if not players.has(bid) or players[bid].get("spectator", false):
			continue
		if phase == Phase.SPEAK and speaker_idx < speaker_order.size() and speaker_order[speaker_idx] == bid:
			var spoke_count: int = bot_spoke.get(bid, 0) if bot_spoke.has(bid) else 0
			if spoke_count < 2:
				bot_spoke[bid] = spoke_count + 1
				var pool: Array = BOT_LIAR_MSGS if bid == liar_id else BOT_SPEAK_MSGS
				var msg: String = pool[rng.randi_range(0, pool.size() - 1)]
				_srv_broadcast_chat(bid, msg)
		if phase == Phase.VOTE and not votes.has(bid):
			var targets := _active_ids()
			targets.erase(bid)
			var non_spec_targets := []
			for t in targets:
				if not players[t].get("spectator", false):
					non_spec_targets.append(t)
			if non_spec_targets.size() > 0:
				votes[bid] = non_spec_targets[rng.randi_range(0, non_spec_targets.size() - 1)]
		elif phase == Phase.GUESS and bid == liar_id and not liar_guessed:
			if srv_guess_candidates.size() > 0:
				guess = srv_guess_candidates[rng.randi_range(0, srv_guess_candidates.size() - 1)]
				liar_guessed = true

func _on_join(id: int) -> void:
	players[id] = {"score": 0, "hue": rng.randf(), "spectator": phase != Phase.WAIT}
	if phase == Phase.WAIT and winner_id == 0 and players.size() >= MIN_PLAYERS:
		_new_round()

func _on_leave(id: int) -> void:
	players.erase(id)
	votes.erase(id)
	var stale_voters := []
	for vid in votes:
		if votes[vid] == id:
			stale_voters.append(vid)
	for vid in stale_voters:
		votes.erase(vid)
	if phase == Phase.WAIT:
		return
	if id == liar_id and phase != Phase.RESULT:
		round_msg = "라이어가 나갔습니다! 라운드 무효"
		phase = Phase.RESULT
		timer = RESULT_TIME
		return
	if speaker_order.has(id) and (phase == Phase.REVEAL or phase == Phase.SPEAK):
		var idx := speaker_order.find(id)
		speaker_order.erase(id)
		if idx < speaker_idx:
			speaker_idx -= 1
		elif idx == speaker_idx:
			timer = SPEAK_TIME
		if speaker_order.is_empty() or speaker_idx >= speaker_order.size():
			phase = Phase.VOTE
			timer = VOTE_TIME
			votes.clear()
	if players.size() < MIN_PLAYERS:
		phase = Phase.WAIT
		round_msg = ""

func _active_ids() -> Array:
	var out := []
	for id in players:
		if not players[id].get("spectator", false):
			out.append(id)
	return out

func _new_round() -> void:
	round_num += 1
	for id in players:
		players[id]["spectator"] = false
	var ids := players.keys()
	liar_id = ids[rng.randi_range(0, ids.size() - 1)]
	var cats := TOPICS.keys()
	category = cats[rng.randi_range(0, cats.size() - 1)]
	var words: Array = TOPICS[category].duplicate()
	for used in used_keywords:
		words.erase(used)
	if words.is_empty():
		used_keywords.clear()
		words = TOPICS[category].duplicate()
	keyword = words[rng.randi_range(0, words.size() - 1)]
	used_keywords.append(keyword)
	speaker_order = ids.duplicate()
	speaker_order.shuffle()
	speaker_idx = 0
	votes.clear()
	guess = ""
	liar_guessed = false
	round_msg = ""
	bot_spoke.clear()
	phase = Phase.REVEAL
	timer = REVEAL_TIME

func _advance_speaker() -> void:
	speaker_idx += 1
	while speaker_idx < speaker_order.size():
		var sid: int = speaker_order[speaker_idx]
		if players.has(sid) and not players[sid].get("spectator", false):
			break
		speaker_idx += 1
	if speaker_idx >= speaker_order.size():
		phase = Phase.VOTE
		timer = VOTE_TIME
		votes.clear()
	else:
		timer = SPEAK_TIME

func _physics_process(delta: float) -> void:
	if not is_server:
		return
	if phase == Phase.WAIT:
		if winner_id > 0:
			timer -= delta
			if timer <= 0.0:
				for pid in players:
					players[pid]["score"] = 0
				winner_id = 0
				used_keywords.clear()
				if players.size() >= MIN_PLAYERS:
					_new_round()
	elif phase == Phase.REVEAL:
		timer -= delta
		if timer <= 0.0:
			phase = Phase.SPEAK
			timer = SPEAK_TIME
			# skip spectators/disconnected in speaker_order
			while speaker_idx < speaker_order.size():
				var sid: int = speaker_order[speaker_idx]
				if players.has(sid) and not players[sid].get("spectator", false):
					break
				speaker_idx += 1
			if speaker_idx >= speaker_order.size():
				phase = Phase.VOTE
				timer = VOTE_TIME
				votes.clear()
	elif phase == Phase.SPEAK:
		timer -= delta
		if timer <= 0.0:
			_advance_speaker()
	elif phase == Phase.VOTE:
		timer -= delta
		var active := _active_ids()
		if votes.size() >= active.size() or timer <= 0.0:
			_resolve_vote()
	elif phase == Phase.GUESS:
		timer -= delta
		if liar_guessed or timer <= 0.0:
			_resolve_guess()
	elif phase == Phase.RESULT:
		timer -= delta
		if timer <= 0.0:
			var won := false
			for id in players:
				if players[id]["score"] >= WIN_SCORE:
					winner_id = id
					won = true
					break
			if won:
				phase = Phase.WAIT
				timer = 5.0
			elif players.size() >= MIN_PLAYERS:
				_new_round()
			else:
				phase = Phase.WAIT

	_bot_act(delta)
	accum += delta
	if accum >= TICK:
		accum = 0.0
		_broadcast()

func _resolve_vote() -> void:
	if not players.has(liar_id):
		round_msg = "라이어가 나갔습니다! 라운드 무효"
		phase = Phase.RESULT
		timer = RESULT_TIME
		return
	var tally := {}
	for vid in votes.values():
		tally[vid] = tally.get(vid, 0) + 1
	if tally.is_empty():
		players[liar_id]["score"] += 2
		round_msg = "아무도 투표하지 않음! 라이어 %s 탈출! +2점 (제시어: %s)" % [_pname(liar_id), keyword]
		phase = Phase.RESULT
		timer = RESULT_TIME
		return
	var max_votes := 0
	var suspected := 0
	var tie := false
	for id in tally:
		if tally[id] > max_votes:
			max_votes = tally[id]
			suspected = id
			tie = false
		elif tally[id] == max_votes:
			tie = true
	if tie:
		players[liar_id]["score"] += 2
		round_msg = "동표! 라이어 %s 탈출 성공! +2점 (제시어: %s)" % [_pname(liar_id), keyword]
		phase = Phase.RESULT
		timer = RESULT_TIME
		return
	if suspected == liar_id:
		phase = Phase.GUESS
		timer = GUESS_TIME
		round_msg = "라이어 지목 성공! %s 가 라이어입니다!" % _pname(liar_id)
		srv_guess_candidates = _build_srv_guess_candidates()
	else:
		players[liar_id]["score"] += 2
		round_msg = "오지목! 라이어 %s 탈출 성공! +2점 (제시어: %s)" % [_pname(liar_id), keyword]
		phase = Phase.RESULT
		timer = RESULT_TIME

func _build_srv_guess_candidates() -> Array:
	if not TOPICS.has(category):
		return [keyword]
	var pool: Array = TOPICS[category].duplicate()
	pool.erase(keyword)
	pool.shuffle()
	var picks := pool.slice(0, mini(GUESS_GRID_COUNT - 1, pool.size()))
	picks.append(keyword)
	picks.shuffle()
	return picks

func _resolve_guess() -> void:
	if not players.has(liar_id):
		round_msg = "라이어가 나갔습니다!"
		phase = Phase.RESULT
		timer = RESULT_TIME
		return
	# correct voters always get +1 for catching liar
	var correct_voters := 0
	for vid in votes:
		if votes[vid] == liar_id and players.has(vid):
			players[vid]["score"] += 1
			correct_voters += 1
	if guess.strip_edges().to_lower() == keyword.to_lower():
		players[liar_id]["score"] += 2
		round_msg = "라이어 %s 역추측 성공! '%s' 맞춤! +2점 (투표자도 +1)" % [_pname(liar_id), keyword]
	else:
		var guess_shown := guess.strip_edges() if guess.strip_edges().length() > 0 else "(시간 초과)"
		round_msg = "라이어 %s 역추측 실패! ('%s' → 정답: '%s') 투표 성공자 %d명 +1점" % [_pname(liar_id), guess_shown, keyword, correct_voters]
	phase = Phase.RESULT
	timer = RESULT_TIME

func _pname(id: int) -> String:
	var ids := players.keys()
	ids.sort()
	var idx := ids.find(id)
	if idx < 0:
		return "??"
	return "P%d" % (idx + 1)

func _broadcast() -> void:
	var ids := players.keys()
	ids.sort()
	var scores := {}
	for id in ids:
		scores[id] = players[id].duplicate()
	var cur_speaker := 0
	if speaker_idx < speaker_order.size():
		cur_speaker = speaker_order[speaker_idx]

	var vote_tally := {}
	if phase == Phase.VOTE or phase == Phase.RESULT or phase == Phase.GUESS:
		for vid in votes.values():
			vote_tally[vid] = vote_tally.get(vid, 0) + 1

	for id in ids:
		if id < 0:
			continue
		var my_word := ""
		var is_spectator: bool = players[id].get("spectator", false)
		if is_spectator:
			my_word = "(관전 중 — 다음 라운드부터 참여)"
		elif phase == Phase.REVEAL or phase == Phase.SPEAK or phase == Phase.VOTE:
			my_word = "" if id == liar_id else keyword
		elif phase == Phase.RESULT:
			my_word = keyword
		elif phase == Phase.GUESS:
			my_word = "" if id == liar_id else keyword
		var is_liar_flag: bool = (id == liar_id) and phase != Phase.WAIT
		var revealed := liar_id if int(phase) >= Phase.GUESS else 0
		var gc: Array = srv_guess_candidates.duplicate() if phase == Phase.GUESS and id == liar_id else []
		cl_state.rpc_id(id, scores, int(phase), timer, category, my_word,
			speaker_order.duplicate(), speaker_idx, cur_speaker,
			votes.duplicate(true), round_msg, revealed,
			round_num, winner_id, is_liar_flag, vote_tally.duplicate(), gc)

@rpc("any_peer", "call_remote", "reliable")
func srv_vote(target: int) -> void:
	if not is_server or phase != Phase.VOTE:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not players.has(sender) or not players.has(target) or sender == target:
		return
	if players[sender].get("spectator", false):
		return
	if players[target].get("spectator", false):
		return
	if not votes.has(sender):
		votes[sender] = target

@rpc("any_peer", "call_remote", "reliable")
func srv_guess(word: String) -> void:
	if not is_server or phase != Phase.GUESS:
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender != liar_id or liar_guessed:
		return
	if not srv_guess_candidates.has(word):
		return
	guess = word
	liar_guessed = true

@rpc("any_peer", "call_remote", "reliable")
func srv_chat(msg: String) -> void:
	if not is_server:
		return
	var sender := multiplayer.get_remote_sender_id()
	if not players.has(sender):
		return
	if phase == Phase.REVEAL:
		return
	if msg.strip_edges().is_empty() or msg.length() > 200:
		return
	_srv_broadcast_chat(sender, msg.strip_edges())

func _srv_broadcast_chat(sender_id: int, msg: String) -> void:
	var entry := {"id": sender_id, "msg": msg}
	srv_chat_log.append(entry)
	if srv_chat_log.size() > MAX_CHAT:
		srv_chat_log.pop_front()
	for pid in players:
		if pid > 0:
			cl_chat.rpc_id(pid, sender_id, msg)

@rpc("authority", "call_remote", "reliable")
func cl_chat(sender_id: int, msg: String) -> void:
	chat_log.append({"id": sender_id, "msg": msg})
	if chat_log.size() > 20:
		chat_log.pop_front()

@rpc("authority", "call_remote", "unreliable")
func cl_state(sc: Dictionary, ph: int, tm: float, cat: String, word: String,
		sp_order: Array, sp_idx: int, cur_sp: int, vt: Dictionary,
		msg: String, revealed_liar: int, rnd: int, win: int,
		is_liar: bool, vote_tally: Dictionary, gc: Array = []) -> void:
	var prev_phase: int = snap.get("phase", Phase.WAIT)
	var prev_round: int = snap.get("round", 0)
	snap = {"scores": sc, "phase": ph, "timer": tm, "category": cat, "word": word,
		"speaker_order": sp_order, "speaker_idx": sp_idx, "cur_speaker": cur_sp,
		"votes": vt, "msg": msg, "liar_id": revealed_liar, "round": rnd, "winner": win,
		"is_liar": is_liar, "vote_tally": vote_tally}
	if rnd != prev_round or (ph == Phase.VOTE and prev_phase != Phase.VOTE):
		my_vote = 0
	if ph == Phase.VOTE and my_vote > 0:
		var my_id := multiplayer.get_unique_id()
		if not vt.has(my_id):
			my_vote = 0
	if ph == Phase.REVEAL and prev_phase != Phase.REVEAL:
		my_vote = 0
		guess_selected = -1
		guess_candidates = []
	if ph == Phase.GUESS and prev_phase != Phase.GUESS and is_liar:
		guess_selected = -1
		guess_candidates = gc
	if ph != prev_phase:
		phase_flash = 1.0
		match ph:
			Phase.REVEAL: phase_flash_text = "제시어 공개!"
			Phase.SPEAK: phase_flash_text = "설명 시작!"
			Phase.VOTE: phase_flash_text = "투표!"
			Phase.GUESS: phase_flash_text = "라이어 추측!"
			Phase.RESULT: phase_flash_text = "결과!"
			_: phase_flash_text = ""


# ═══════════════════════ CLIENT ═══════════════════════

func _start_client() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(20, 14)
	hud.add_theme_font_size_override("font_size", 28)
	canvas.add_child(hud)
	hud.text = "접속 중..."
	# chat input
	chat_input = LineEdit.new()
	chat_input.position = Vector2(20, 656)
	chat_input.size = Vector2(360, 50)
	chat_input.placeholder_text = "채팅 입력..."
	chat_input.add_theme_font_size_override("font_size", 24)
	canvas.add_child(chat_input)
	chat_btn = Button.new()
	chat_btn.position = Vector2(385, 656)
	chat_btn.size = Vector2(80, 50)
	chat_btn.text = "전송"
	chat_btn.add_theme_font_size_override("font_size", 22)
	chat_btn.pressed.connect(_on_chat_submit)
	canvas.add_child(chat_btn)
	chat_input.text_submitted.connect(func(_t: String): _on_chat_submit())
	tex_body = load("res://assets/parrot_body.png")
	tex_shirt = load("res://assets/parrot_shirt_mask.png")
	tex_bg = load("res://assets/bg_stage.png")
	tex_icon_speech = load("res://assets/icon_speech.png")
	tex_icon_liar = load("res://assets/icon_liar.png")
	tex_icon_vote = load("res://assets/icon_vote.png")
	tex_title = load("res://assets/title_liar.png")
	tex_card_word = load("res://assets/card_word.png")
	tex_card_liar = load("res://assets/card_liar.png")
	tex_cat_animal = load("res://assets/cat_animal.png")
	tex_cat_food = load("res://assets/cat_food.png")
	tex_cat_place = load("res://assets/cat_place.png")
	tex_cat_job = load("res://assets/cat_job.png")
	tex_cat_sports = load("res://assets/cat_sports.png")
	tex_cat_movie = load("res://assets/cat_movie.png")
	tex_scoreboard = load("res://assets/scoreboard.png")
	tex_trophy = load("res://assets/trophy.png")
	tex_parrot_speak = load("res://assets/parrot_speak.png")
	tex_parrot_dead = load("res://assets/parrot_dead.png")
	tex_banner_reveal = load("res://assets/banner_reveal.png")
	tex_banner_speak = load("res://assets/banner_speak.png")
	tex_banner_vote_liar = load("res://assets/banner_vote_liar.png")
	tex_btn_frame = load("res://assets/btn_frame.png")
	tex_spotlight = load("res://assets/spotlight_beam.png")
	peer.create_client(_ws_client_url())
	multiplayer.multiplayer_peer = peer

func _on_chat_submit() -> void:
	var msg := chat_input.text.strip_edges()
	if msg.is_empty():
		return
	srv_chat.rpc_id(1, msg)
	chat_input.text = ""
	chat_input.grab_focus()

func _seat_positions() -> Dictionary:
	if snap.is_empty() or not snap.has("scores"):
		return {}
	var ids: Array = snap["scores"].keys()
	ids.sort()
	if ids.is_empty():
		return {}
	var vp := get_viewport_rect().size
	var center := vp / 2.0 + Vector2(0, 20)
	var r := minf(vp.x, vp.y) * 0.27
	var out := {}
	for i in ids.size():
		var a := TAU * float(i) / float(ids.size()) - PI / 2.0
		out[ids[i]] = center + Vector2.from_angle(a) * r
	return out

func _cl_pname(id: int) -> String:
	if snap.is_empty() or not snap.has("scores"):
		return "??"
	var ids: Array = snap["scores"].keys()
	ids.sort()
	var idx := ids.find(id)
	if idx < 0:
		return "??"
	return "P%d" % (idx + 1)

func _category_tex(cat: String) -> Texture2D:
	match cat:
		"동물": return tex_cat_animal
		"음식": return tex_cat_food
		"장소": return tex_cat_place
		"직업": return tex_cat_job
		"스포츠": return tex_cat_sports
		"영화/드라마": return tex_cat_movie
		_: return null

func _guess_btn_rect(i: int) -> Rect2:
	var vp := get_viewport_rect().size
	var btn_w := 180.0
	var btn_h := 48.0
	var gap := 10.0
	var grid_w := float(GUESS_GRID_COLS) * (btn_w + gap) - gap
	var start_x := (vp.x - grid_w) / 2.0
	var start_y := vp.y - 170.0
	var col := i % GUESS_GRID_COLS
	var row := i / GUESS_GRID_COLS
	return Rect2(start_x + float(col) * (btn_w + gap),
		start_y + float(row) * (btn_h + gap), btn_w, btn_h)

func _unhandled_input(event: InputEvent) -> void:
	if is_server or snap.is_empty():
		return
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		OS.create_process(OS.get_executable_path(), ["--path", ProjectSettings.globalize_path("res://")])
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var my_id := multiplayer.get_unique_id()
	var ph: int = snap.get("phase", Phase.WAIT)

	if ph == Phase.VOTE and my_vote == 0:
		var sc: Dictionary = snap.get("scores", {})
		var seats := _seat_positions()
		for id in seats:
			if id == my_id:
				continue
			if sc.has(id) and sc[id].get("spectator", false):
				continue
			if seats[id].distance_to(event.position) < 48.0:
				my_vote = id
				click_pulse_id = id
				click_pulse_t = 0.4
				srv_vote.rpc_id(1, id)
				return

	if ph == Phase.GUESS and snap.get("is_liar", false) and guess_selected < 0:
		for i in guess_candidates.size():
			if _guess_btn_rect(i).has_point(event.position):
				guess_selected = i
				click_pulse_t = 0.3
				srv_guess.rpc_id(1, guess_candidates[i])
				return

func _process(delta: float) -> void:
	if is_server or snap.is_empty():
		return
	anim_t += delta
	click_pulse_t = maxf(0.0, click_pulse_t - delta * 3.0)
	phase_flash = maxf(0.0, phase_flash - delta * 1.2)
	shake_t = maxf(0.0, shake_t - delta * 4.0)
	_update_hud()
	queue_redraw()

func _update_hud() -> void:
	var my_id := multiplayer.get_unique_id()
	if not snap.has("scores"):
		hud.text = "접속 중..."
		return
	var sc: Dictionary = snap["scores"]
	var ph: int = snap.get("phase", Phase.WAIT)
	var lines := ""

	if sc.size() < MIN_PLAYERS:
		lines = "대기중... (%d/%d명, 라이어 게임)" % [sc.size(), MIN_PLAYERS]
		hud.text = lines
		return

	var is_spec: bool = sc.has(my_id) and sc[my_id].get("spectator", false)

	match ph:
		Phase.WAIT:
			if snap.get("winner", 0) > 0:
				var wid: int = snap["winner"]
				lines = "%s 최종 승리! (%d점 달성)\n새 게임 준비 중..." % [
					"내가" if wid == my_id else _cl_pname(wid), WIN_SCORE]
			else:
				lines = "대기중... (%d명)" % sc.size()
		Phase.REVEAL:
			lines = "라운드 %d — [%s]\n" % [snap.get("round", 0), snap.get("category", "")]
			if is_spec:
				lines += "(관전 중)"
			elif snap.get("is_liar", false):
				lines += "!! 당신은 라이어입니다 !!"
			else:
				lines += "제시어: %s" % snap.get("word", "")
			lines += "  (%.0f초)" % snap.get("timer", 0)
		Phase.SPEAK:
			var speaker: int = snap.get("cur_speaker", 0)
			lines = "라운드 %d — [%s] 설명 차례\n" % [snap.get("round", 0), snap.get("category", "")]
			if snap.get("is_liar", false):
				lines += "🤥 라이어! | "
			elif not is_spec:
				lines += "제시어: %s | " % snap.get("word", "")
			if speaker == my_id:
				lines += ">> 내 차례! 제시어를 설명하세요 <<"
			else:
				lines += "%s 설명 중..." % _cl_pname(speaker)
			var sp_order: Array = snap.get("speaker_order", [])
			var sp_idx: int = snap.get("speaker_idx", 0)
			lines += "  (%d/%d, %.0f초)" % [sp_idx + 1, sp_order.size(), snap.get("timer", 0)]
			if sp_idx + 1 < sp_order.size():
				lines += "\n다음: %s" % _cl_pname(sp_order[sp_idx + 1])
		Phase.VOTE:
			lines = "[투표] 라이어를 클릭! (%.0f초)" % snap.get("timer", 0)
			if snap.get("is_liar", false):
				lines += "\n🤥 당신은 라이어입니다"
			elif not is_spec:
				lines += "\n제시어: %s" % snap.get("word", "")
			if is_spec:
				lines += "\n(관전 중 — 투표 불가)"
			elif my_vote > 0:
				lines += "\n내 투표: %s ✓" % _cl_pname(my_vote)
		Phase.GUESS:
			lines = snap.get("msg", "") + "\n"
			if snap.get("is_liar", false):
				if guess_selected >= 0 and guess_selected < guess_candidates.size():
					lines += "선택: %s (%.0f초)" % [guess_candidates[guess_selected], snap.get("timer", 0)]
				else:
					lines += "아래에서 제시어를 클릭! (%.0f초)" % snap.get("timer", 0)
			else:
				lines += "라이어가 추측 중... (%.0f초)" % snap.get("timer", 0)
		Phase.RESULT:
			lines = snap.get("msg", "")

	# 점수 (정렬)
	var sorted_ids: Array = sc.keys()
	sorted_ids.sort_custom(func(a, b): return sc[b].get("score", 0) < sc[a].get("score", 0))
	lines += "\n── 점수 ──"
	for id in sorted_ids:
		var s: int = sc[id].get("score", 0)
		var spec: bool = sc[id].get("spectator", false)
		var tag := " (나)" if id == my_id else (" 👀" if spec else "")
		lines += "  %s:%d%s" % [_cl_pname(id), s, tag]
	hud.text = lines

func _draw() -> void:
	if is_server or snap.is_empty() or not snap.has("scores"):
		return
	var vp := get_viewport_rect().size
	var my_id := multiplayer.get_unique_id()
	var sc: Dictionary = snap["scores"]
	var ph: int = snap.get("phase", Phase.WAIT)

	# 배경 — 게임쇼 무대
	if tex_bg != null:
		draw_texture_rect(tex_bg, Rect2(Vector2.ZERO, vp), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.10, 0.11, 0.16))
	# 페이즈별 오버레이
	var overlay_col := Color(0, 0, 0, 0.25)
	if ph == Phase.VOTE:
		overlay_col = Color(0.3, 0.05, 0.05, 0.35)
	elif ph == Phase.GUESS:
		overlay_col = Color(0.1, 0.0, 0.2, 0.4)
	elif ph == Phase.RESULT:
		overlay_col = Color(0.05, 0.05, 0.15, 0.3)
	elif ph == Phase.REVEAL:
		overlay_col = Color(0, 0, 0, 0.15)
	draw_rect(Rect2(Vector2.ZERO, vp), overlay_col)

	# WAIT / 대기 화면 — 타이틀 + 트로피
	if sc.size() < MIN_PLAYERS or ph == Phase.WAIT:
		if tex_title != null:
			var title_w := minf(vp.x * 0.7, 640.0)
			var title_h := title_w * 0.667
			var title_rect := Rect2(Vector2((vp.x - title_w) / 2.0, vp.y * 0.1), Vector2(title_w, title_h))
			draw_texture_rect(tex_title, title_rect, false)
		var wait_y := vp.y * 0.65
		if sc.size() < MIN_PLAYERS:
			draw_string(ThemeDB.fallback_font, Vector2(vp.x / 2.0 - 140, wait_y),
				"대기중... (%d/%d명)" % [sc.size(), MIN_PLAYERS],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 1, 1, 0.8))
		elif snap.get("winner", 0) > 0:
			var win_id: int = snap.get("winner", 0)
			if tex_trophy != null:
				var pulse := 0.7 + sin(anim_t * 3.0) * 0.3
				draw_texture_rect(tex_trophy, Rect2(Vector2(vp.x / 2.0 - 40, wait_y - 50), Vector2(80, 80)),
					false, Color(1, 1, 1, pulse))
			var win_name := _cl_pname(win_id) if win_id > 0 else "?"
			draw_string(ThemeDB.fallback_font, Vector2(vp.x / 2.0 - 100, wait_y + 50),
				"%s 우승! 🎉" % win_name,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(1, 0.85, 0.3))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(vp.x / 2.0 - 100, wait_y),
				"잠시 후 시작...",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 1, 1, 0.8))
		if ph == Phase.WAIT:
			return

	var center := vp / 2.0 + Vector2(0, 20)

	# 라운드 + 카테고리 — 무대 테이블 위
	if ph != Phase.WAIT:
		# 반투명 패널 배경
		var panel_w := 360.0
		var panel_h := 110.0
		var panel_rect := Rect2(center - Vector2(panel_w / 2.0, 50), Vector2(panel_w, panel_h))
		draw_rect(panel_rect, Color(0, 0, 0, 0.45), true)
		draw_rect(panel_rect, Color(1, 0.85, 0.3, 0.5), false, 2.0)
		var rnd_text := "ROUND %d" % snap.get("round", 0)
		draw_string(ThemeDB.fallback_font, center + Vector2(-56, -36),
			rnd_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 0.85, 0.4))
		var cat_text: String = snap.get("category", "")
		if cat_text.length() > 0:
			var cat_icon := _category_tex(cat_text)
			if cat_icon != null:
				draw_texture_rect(cat_icon, Rect2(center + Vector2(-panel_w / 2.0 + 10, -48), Vector2(56, 56)), false)
				draw_string(ThemeDB.fallback_font, center + Vector2(-panel_w / 2.0 + 72, -10),
					cat_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(1, 1, 1, 0.95))
			else:
				draw_string(ThemeDB.fallback_font, center + Vector2(-cat_text.length() * 10, 2),
					cat_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(1, 1, 1, 0.95))
		if ph == Phase.REVEAL:
			var word_text: String = snap.get("word", "")
			var card_sz := 200.0
			var card_rect := Rect2(center + Vector2(-card_sz / 2.0, 50), Vector2(card_sz, card_sz))
			if snap.get("is_liar", false):
				if tex_card_liar != null:
					var pulse := 0.7 + sin(anim_t * 4.0) * 0.3
					draw_texture_rect(tex_card_liar, card_rect, false, Color(1, 1, 1, pulse))
				draw_string(ThemeDB.fallback_font, center + Vector2(-110, card_sz + 70),
					"당신은 라이어!", HORIZONTAL_ALIGNMENT_LEFT, -1, 34,
					Color(1, 0.3, 0.3))
			else:
				if tex_card_word != null:
					draw_texture_rect(tex_card_word, card_rect, false)
				if word_text.length() > 0:
					draw_string(ThemeDB.fallback_font, center + Vector2(-word_text.length() * 9, card_sz / 2.0 + 60),
						word_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0.3, 1.0, 0.5))

	# 플레이어들
	var seats := _seat_positions()
	for id in seats:
		if not sc.has(id):
			continue
		var pos: Vector2 = seats[id]
		var hue: float = sc[id].get("hue", 0.0)
		var is_spec: bool = sc[id].get("spectator", false)
		var team_col := Color.from_hsv(hue, 0.7, 0.95)
		var sprite_alpha := 0.4 if is_spec else 1.0
		var sz := 120.0
		var half := 60.0
		var sprite_rect := Rect2(pos - Vector2(half, half), Vector2(sz, sz))

		# 현재 발언자 — 스포트라이트 + 펄싱 글로우 + 말풍선 아이콘
		var is_speaking: bool = ph == Phase.SPEAK and id == snap.get("cur_speaker", 0)
		if is_speaking:
			if tex_spotlight != null:
				var sway := sin(anim_t * 1.5) * 12.0
				draw_texture_rect(tex_spotlight, Rect2(pos.x - 50 + sway, pos.y - half - 180, 100, 200), false, Color(1, 1, 1, 0.35))
			var pulse := 0.5 + sin(anim_t * 5.0) * 0.3
			draw_circle(pos, half + 10.0, Color(1, 0.9, 0.2, pulse * 0.2))
			draw_arc(pos, half + 8.0, 0.0, TAU, 32, Color(1, 0.9, 0.2, pulse), 3.0)
			if tex_icon_speech != null:
				draw_texture_rect(tex_icon_speech, Rect2(pos + Vector2(half - 6, -half - 36), Vector2(48, 48)), false, Color(1, 1, 1, pulse))

		# 내 투표 대상
		if ph == Phase.VOTE and my_vote == id:
			draw_arc(pos, half + 6.0, 0.0, TAU, 32, Color(1, 0.3, 0.3, 0.8), 3.0)

		# 라이어 공개 — 마스크 아이콘
		if (ph == Phase.GUESS or ph == Phase.RESULT) and snap.get("liar_id", 0) == id:
			var pulse := 0.6 + sin(anim_t * 3.0) * 0.4
			draw_arc(pos, half + 8.0, 0.0, TAU, 32, Color(1, 0.1, 0.1, pulse), 3.5)
			if tex_icon_liar != null:
				draw_texture_rect(tex_icon_liar, Rect2(pos + Vector2(-28, half + 4), Vector2(56, 56)), false, Color(1, 1, 1, pulse))
			else:
				draw_string(ThemeDB.fallback_font, pos + Vector2(-36, half + 18),
					"LIAR!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 0.2, 0.2))

		# 캐릭터 스프라이트 (상태별 변형)
		var body_mod := Color(1, 1, 1, sprite_alpha)
		var use_tex := tex_body
		var is_liar_revealed: bool = (ph == Phase.GUESS or ph == Phase.RESULT) and snap.get("liar_id", 0) == id
		if is_speaking and tex_parrot_speak != null:
			use_tex = tex_parrot_speak
		elif is_liar_revealed and tex_parrot_dead != null:
			use_tex = tex_parrot_dead
		if use_tex != null:
			draw_texture_rect(use_tex, sprite_rect, false, body_mod)
		if tex_shirt != null:
			var shirt_mod := Color(team_col.r, team_col.g, team_col.b, sprite_alpha)
			draw_texture_rect(tex_shirt, sprite_rect, false, shirt_mod)

		# 자신 표시
		if id == my_id:
			draw_arc(pos, half + 2.0, 0.0, TAU, 32, Color.WHITE, 2.5)

		# 이름
		var name_str := _cl_pname(id)
		draw_rect(Rect2(pos + Vector2(-24, -10), Vector2(60, 26)), Color(0, 0, 0, 0.4), true)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-20, 10),
			name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
			Color(1, 1, 1, 0.9) if not is_spec else Color(0.5, 0.5, 0.5, 0.6))

		# 점수 뱃지
		var badge_pos := pos + Vector2(40, -46)
		var score_val: int = sc[id].get("score", 0)
		var badge_col := Color(0.2, 0.2, 0.3, 0.9) if score_val < WIN_SCORE else Color(0.7, 0.5, 0.1, 0.9)
		draw_circle(badge_pos, 18.0, badge_col)
		draw_string(ThemeDB.fallback_font, badge_pos + Vector2(-9, 7),
			str(score_val), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

		# 투표 득표 수 표시 + 투표 아이콘
		if (ph == Phase.VOTE or ph == Phase.RESULT) and snap.has("vote_tally"):
			var vt: Dictionary = snap["vote_tally"]
			if vt.has(id):
				var vc: int = vt[id]
				if tex_icon_vote != null:
					draw_texture_rect(tex_icon_vote, Rect2(pos + Vector2(-half + 2, -half - 40), Vector2(32, 32)), false)
				draw_string(ThemeDB.fallback_font, pos + Vector2(-half + 36, -half - 14),
					"%d표" % vc, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.8, 0.2))

		# 관전자 표시
		if is_spec:
			draw_string(ThemeDB.fallback_font, pos + Vector2(-14, half + 14),
				"👀", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)

	# 투표 화살표
	if ph == Phase.VOTE and snap.has("votes"):
		for vid in snap["votes"]:
			var target_id: int = snap["votes"][vid]
			if seats.has(vid) and seats.has(target_id):
				var from_pos: Vector2 = seats[vid]
				var to_pos: Vector2 = seats[int(target_id)]
				var dir := (to_pos - from_pos).normalized()
				draw_line(from_pos + dir * 50.0, to_pos - dir * 50.0,
					Color(1, 0.3, 0.3, 0.35), 2.0)

	# 역추측 클릭 그리드
	if ph == Phase.GUESS and snap.get("is_liar", false) and guess_candidates.size() > 0:
		var label_pos := _guess_btn_rect(0).position + Vector2(0, -16)
		draw_string(ThemeDB.fallback_font, label_pos,
			"제시어를 클릭하세요!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.7, 0.75, 0.85))
		for i in guess_candidates.size():
			var r := _guess_btn_rect(i)
			var is_hover := r.has_point(mouse_pos) and guess_selected < 0
			var btn_tint: Color
			if guess_selected == i:
				btn_tint = Color(0.4, 1.0, 0.5)
			elif is_hover:
				btn_tint = Color(1.0, 1.0, 1.0)
			else:
				btn_tint = Color(0.8, 0.8, 0.85)
			if tex_btn_frame != null:
				draw_texture_rect(tex_btn_frame, r, false, btn_tint)
			else:
				draw_rect(r, Color(0.22, 0.24, 0.32), true)
				draw_rect(r, Color(0.35, 0.37, 0.45), false, 1.0)
			draw_string(ThemeDB.fallback_font, r.position + Vector2(10, 30),
				guess_candidates[i], HORIZONTAL_ALIGNMENT_LEFT, int(r.size.x - 20), 22, Color.WHITE)

	# 결과 화면 — 점수판 배경 + 결과 메시지
	if ph == Phase.RESULT:
		var sb_w := 280.0
		var sb_h := 200.0
		var sb_x := vp.x - sb_w - 20.0
		var sb_y := 60.0
		if tex_scoreboard != null:
			draw_texture_rect(tex_scoreboard, Rect2(Vector2(sb_x, sb_y), Vector2(sb_w, sb_h)), false, Color(1, 1, 1, 0.85))
		else:
			draw_rect(Rect2(Vector2(sb_x, sb_y), Vector2(sb_w, sb_h)), Color(0, 0, 0, 0.5), true)
			draw_rect(Rect2(Vector2(sb_x, sb_y), Vector2(sb_w, sb_h)), Color(1, 0.85, 0.3, 0.4), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(sb_x + 20, sb_y + 32),
			"점수판", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 0.9, 0.4))
		var sorted_ids: Array = sc.keys()
		sorted_ids.sort_custom(func(a, b): return sc[a].get("score", 0) > sc[b].get("score", 0))
		var row_y := sb_y + 48.0
		for sid in sorted_ids:
			if row_y > sb_y + sb_h - 10:
				break
			var s_val: int = sc[sid].get("score", 0)
			var is_me: bool = sid == my_id
			var row_col := Color(1, 0.9, 0.3) if is_me else Color(1, 1, 1, 0.85)
			draw_string(ThemeDB.fallback_font, Vector2(sb_x + 20, row_y),
				"%s  %d점%s" % [_cl_pname(sid), s_val, " ★" if is_me else ""],
				HORIZONTAL_ALIGNMENT_LEFT, int(sb_w - 40), 22, row_col)
			row_y += 28.0
		var msg: String = snap.get("msg", "")
		if msg.length() > 0:
			var msg_rect := Rect2(Vector2(20, vp.y - 80), Vector2(vp.x - sb_w - 60, 40))
			draw_rect(msg_rect, Color(0, 0, 0, 0.6), true)
			draw_string(ThemeDB.fallback_font, msg_rect.position + Vector2(10, 30),
				msg, HORIZONTAL_ALIGNMENT_LEFT, int(msg_rect.size.x - 20), 22, Color(1, 1, 1, 0.9))

	# 타이머 바
	if ph != Phase.WAIT:
		var max_t := REVEAL_TIME
		match ph:
			Phase.SPEAK: max_t = SPEAK_TIME
			Phase.VOTE: max_t = VOTE_TIME
			Phase.GUESS: max_t = GUESS_TIME
			Phase.RESULT: max_t = RESULT_TIME
		var t_val: float = snap.get("timer", 0)
		var ratio := clampf(t_val / max_t, 0.0, 1.0)
		var bar_w := vp.x - 40.0
		draw_rect(Rect2(Vector2(14, vp.y - 36), Vector2(bar_w + 12, 24)), Color(0, 0, 0, 0.4), true)
		draw_rect(Rect2(Vector2(20, vp.y - 30), Vector2(bar_w, 14)), Color(0.18, 0.19, 0.24))
		var tcol := Color(0.3, 0.9, 0.4) if ratio > 0.3 else Color(1, 0.3, 0.2)
		draw_rect(Rect2(Vector2(20, vp.y - 30), Vector2(bar_w * ratio, 14)), tcol)

	# 채팅 로그 (좌하단)
	if chat_log.size() > 0:
		var chat_x := 20.0
		var chat_y := vp.y - 170.0
		var chat_h := minf(chat_log.size() * 26.0 + 16.0, 220.0)
		draw_rect(Rect2(chat_x - 6, chat_y - chat_h, 420.0, chat_h + 6), Color(0, 0, 0, 0.5), true)
		var cy := chat_y
		var start := maxi(0, chat_log.size() - 8)
		for ci in range(start, chat_log.size()):
			var entry: Dictionary = chat_log[ci]
			var name_str := _cl_pname(entry.get("id", 0))
			var chat_msg: String = entry.get("msg", "")
			var sc_entry: Dictionary = snap.get("scores", {})
			var hue_val := 0.0
			if sc_entry.has(entry.get("id", 0)):
				hue_val = sc_entry[entry.get("id", 0)].get("hue", 0.0)
			var name_col := Color.from_hsv(hue_val, 0.7, 0.95)
			draw_string(ThemeDB.fallback_font, Vector2(chat_x, cy),
				"%s: %s" % [name_str, chat_msg],
				HORIZONTAL_ALIGNMENT_LEFT, 400, 20, name_col)
			cy -= 26.0

	# 클릭 펄스 이펙트
	if click_pulse_t > 0.0 and click_pulse_id != 0 and seats.has(click_pulse_id):
		var pulse_pos: Vector2 = seats[click_pulse_id]
		var pulse_r := 48.0 + (1.0 - click_pulse_t) * 30.0
		draw_arc(pulse_pos, pulse_r, 0.0, TAU, 24, Color(1, 1, 0.3, click_pulse_t), 3.0)

	# 페이즈 전환 플래시 + 배너
	if phase_flash > 0.0 and phase_flash_text.length() > 0:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(1, 1, 1, phase_flash * 0.08))
		var banner_tex: Texture2D = null
		if phase_flash_text == "제시어 공개!":
			banner_tex = tex_banner_reveal
		elif phase_flash_text == "설명 시작!":
			banner_tex = tex_banner_speak
		elif phase_flash_text == "투표!":
			banner_tex = tex_banner_vote_liar
		if banner_tex != null:
			var bw := minf(vp.x * 0.7, 700.0)
			var bh := bw * 0.5625
			draw_texture_rect(banner_tex, Rect2(vp.x / 2.0 - bw / 2.0, vp.y / 2.0 - bh / 2.0 - 30, bw, bh), false, Color(1, 1, 1, phase_flash))
		var flash_size := 48
		var text_w := phase_flash_text.length() * 22
		draw_rect(Rect2(vp.x / 2.0 - float(text_w) / 2.0 - 30, vp.y / 2.0 + 30, float(text_w) + 60, 60),
			Color(0, 0, 0, phase_flash * 0.6), true)
		draw_string(ThemeDB.fallback_font,
			Vector2(vp.x / 2.0 - float(text_w) / 2.0, vp.y / 2.0 + 72),
			phase_flash_text, HORIZONTAL_ALIGNMENT_LEFT, -1, flash_size,
			Color(1, 0.9, 0.3, phase_flash))

	# 페이즈 표시 (우상단)
	var phase_label := ""
	match ph:
		Phase.WAIT: phase_label = "대기"
		Phase.REVEAL: phase_label = "공개"
		Phase.SPEAK: phase_label = "설명"
		Phase.VOTE: phase_label = "투표"
		Phase.GUESS: phase_label = "역추측"
		Phase.RESULT: phase_label = "결과"
	draw_rect(Rect2(vp.x - 150, 10, 140, 42), Color(0, 0, 0, 0.4), true)
	draw_string(ThemeDB.fallback_font, Vector2(vp.x - 142, 40),
		phase_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 1, 1, 0.85))
