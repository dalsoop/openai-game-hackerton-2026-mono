class_name SfxCatalog
extends RefCounted

const SOUNDS := {
	"gun_fire": "res://assets/sfx/gun_fire.wav",
	"gun_fire_pistol": "res://assets/sfx/gun_fire_pistol.wav",
	"gun_fire_smg": "res://assets/sfx/gun_fire_smg.wav",
	"gun_fire_rifle": "res://assets/sfx/gun_fire_rifle.wav",
	"gun_fire_lmg": "res://assets/sfx/gun_fire_lmg.wav",
	"gun_fire_shotgun": "res://assets/sfx/gun_fire_shotgun.wav",
	"gun_fire_sniper": "res://assets/sfx/gun_fire_sniper.wav",
	"gun_fire_launcher": "res://assets/sfx/gun_fire_launcher.wav",
	"gun_reload": "res://assets/sfx/gun_reload.wav",
	"gun_reload_light": "res://assets/sfx/gun_reload_light.wav",
	"gun_reload_heavy": "res://assets/sfx/gun_reload_heavy.wav",
	"stone_hit": "res://assets/sfx/stone_hit.wav",
	"gun_hit": "res://assets/sfx/gun_hit.wav",
	"stone_tick": "res://assets/sfx/stone_tick.wav",
	"gun_ricochet": "res://assets/sfx/gun_ricochet.wav",
	"ult_dragon": "res://assets/sfx/ult_dragon.wav",
	"ult_pig": "res://assets/sfx/ult_pig.wav",
	"ult_monkey": "res://assets/sfx/ult_monkey.wav",
	"ult_ox": "res://assets/sfx/ult_ox.wav",
	"ult_tiger": "res://assets/sfx/ult_tiger.wav",
	"ult_rabbit_in": "res://assets/sfx/ult_rabbit_in.wav",
	"ult_rabbit_out": "res://assets/sfx/ult_rabbit_out.wav",
	"ult_snake": "res://assets/sfx/ult_snake.wav",
	"ult_goat": "res://assets/sfx/ult_goat.wav",
	"ult_horse": "res://assets/sfx/ult_horse.wav",
	"ult_dog": "res://assets/sfx/ult_dog.wav",
	"ult_rooster": "res://assets/sfx/ult_rooster.wav",
	"ult_rat": "res://assets/sfx/ult_rat.wav",
	"ult_rat_1": "res://assets/sfx/ult_rat_1.wav",
	"ult_rat_2": "res://assets/sfx/ult_rat_2.wav",
	"ult_rat_3": "res://assets/sfx/ult_rat_3.wav",
	"ult_rat_4": "res://assets/sfx/ult_rat_4.wav",
	"hit_marker": "res://assets/sfx/hit_marker.wav",
	"explosion": "res://assets/sfx/explosion.wav",
	"skill_use": "res://assets/sfx/skill_use.wav",
	"down": "res://assets/sfx/down.wav",
	"eliminate": "res://assets/sfx/eliminate.wav",
	"pickup": "res://assets/sfx/pickup.wav",
	"ui_click": "res://assets/sfx/ui_click.wav",
	"match_start": "res://assets/sfx/match_start.wav",
	"match_end": "res://assets/sfx/match_end.wav",
	"dash": "res://assets/sfx/dash_1.wav",
	"dash_1": "res://assets/sfx/dash_1.wav",
	"dash_2": "res://assets/sfx/dash_2.wav",
	"ultimate": "res://assets/sfx/ultimate.wav",
	"wall_bounce": "res://assets/sfx/wall_bounce_1.wav",
	"wall_bounce_1": "res://assets/sfx/wall_bounce_1.wav",
	"wall_bounce_2": "res://assets/sfx/wall_bounce_2.wav",
	"wall_bounce_3": "res://assets/sfx/wall_bounce_3.wav",
	"core_hit": "res://assets/sfx/core_hit.wav",
	"gun_upgrade": "res://assets/sfx/gun_upgrade.wav",
	"medkit": "res://assets/sfx/medkit.wav",
	"potion": "res://assets/sfx/potion.wav",
	"respawn": "res://assets/sfx/respawn.wav",
	"zone_shrink": "res://assets/sfx/zone_shrink.wav",
	"zone_tick": "res://assets/sfx/zone_tick.wav",
	"finisher": "res://assets/sfx/finisher.wav",
	"victory": "res://assets/sfx/victory.wav",
	"lose": "res://assets/sfx/lose.wav",
	"kill_fanfare": "res://assets/sfx/kill_fanfare.wav",
	"countdown": "res://assets/sfx/countdown.wav",
	"ready_to_fight": "res://assets/sfx/ready_to_fight.wav",
	"roulette": "res://assets/sfx/roulette.wav",
	"power_up": "res://assets/sfx/power_up.wav",
	"down_kill": "res://assets/sfx/down_kill.wav",
}

const MUSIC := {
	"lobby": "res://assets/music/lobby.ogg",
	"match": "res://assets/music/match.ogg",
	"victory": "res://assets/music/victory.ogg",
}

static func stream_for(sound_id: String) -> AudioStream:
	var path: String = SOUNDS.get(sound_id, "")
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			return res
	return _load_wav_raw(path)

static func _load_wav_raw(path: String) -> AudioStreamWAV:
	var abs_path := ProjectSettings.globalize_path(path)
	var file := FileAccess.open(abs_path, FileAccess.READ)
	if file == null:
		print("[gangup] wav miss %s" % path)
		return null
	var bytes := file.get_buffer(file.get_length())
	file.close()
	if bytes.size() < 44:
		print("[gangup] wav short %s" % path)
		return null
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = true
	stream.data = bytes.slice(44)
	print("[gangup] wav raw %s bytes=%s" % [path, stream.data.size()])
	return stream

static func music_for(track: String) -> AudioStream:
	var path: String = MUSIC.get(track, "")
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			_enable_loop(res)
			print("[gangup] music load %s" % path)
			return res
	if path.ends_with(".ogg"):
		var abs_path := ProjectSettings.globalize_path(path)
		var s = AudioStreamOggVorbis.load_from_file(abs_path)
		if s != null:
			s.loop = true
			print("[gangup] ogg raw %s" % path)
			return s
	print("[gangup] music miss %s" % path)
	return null

static func _enable_loop(res: AudioStream) -> void:
	if res is AudioStreamOggVorbis:
		res.loop = true

const GUN_CLASS := {
	"burst": "pistol",
	"brawler": "pistol",
	"leech": "smg",
	"blade": "smg",
	"spear": "rifle",
	"chain": "rifle",
	"breaker": "lmg",
	"scatter": "shotgun",
	"bomb": "shotgun",
	"shield": "rifle",
	"rail": "sniper",
	"mortar": "launcher",
}

# 0 rat .. 11 pig, same order as GunSig.equipment_for_animal
const ANIMAL_ULT := {
	0: "ult_rat",
	1: "ult_ox",
	2: "ult_tiger",
	3: "ult_rabbit_in",
	5: "ult_snake",
	6: "ult_horse",
	7: "ult_goat",
	4: "ult_dragon",
	8: "ult_monkey",
	9: "ult_rooster",
	10: "ult_dog",
	11: "ult_pig",
}

static func gun_class_of(equipment_id: String) -> String:
	return str(GUN_CLASS.get(equipment_id, "rifle"))

static func fire_id_for(equipment_id: String) -> String:
	var cid := "gun_fire_%s" % gun_class_of(equipment_id)
	if SOUNDS.has(cid):
		return cid
	return "gun_fire"

static func reload_id_for(equipment_id: String) -> String:
	var klass := gun_class_of(equipment_id)
	if klass == "pistol" or klass == "smg":
		return "gun_reload_light" if SOUNDS.has("gun_reload_light") else "gun_reload"
	return "gun_reload_heavy" if SOUNDS.has("gun_reload_heavy") else "gun_reload"

static func ult_id_for(animal: int) -> String:
	var cid := str(ANIMAL_ULT.get(animal, ""))
	if cid != "" and SOUNDS.has(cid):
		return cid
	return "ultimate"
