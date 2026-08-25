class_name SfxCatalog
extends RefCounted

const PREFIX := "res://games/dagul/assets/"

const SOUNDS := {
	"gun_fire": PREFIX + "sfx/gun_fire.wav",
	"gun_fire_pistol": PREFIX + "sfx/gun_fire_pistol.wav",
	"gun_fire_smg": PREFIX + "sfx/gun_fire_smg.wav",
	"gun_fire_rifle": PREFIX + "sfx/gun_fire_rifle.wav",
	"gun_fire_lmg": PREFIX + "sfx/gun_fire_lmg.wav",
	"gun_fire_shotgun": PREFIX + "sfx/gun_fire_shotgun.wav",
	"gun_fire_sniper": PREFIX + "sfx/gun_fire_sniper.wav",
	"gun_fire_launcher": PREFIX + "sfx/gun_fire_launcher.wav",
	"gun_reload": PREFIX + "sfx/gun_reload.wav",
	"gun_reload_light": PREFIX + "sfx/gun_reload_light.wav",
	"gun_reload_heavy": PREFIX + "sfx/gun_reload_heavy.wav",
	"stone_hit": PREFIX + "sfx/stone_hit.wav",
	"gun_hit": PREFIX + "sfx/gun_hit.wav",
	"stone_tick": PREFIX + "sfx/stone_tick.wav",
	"gun_ricochet": PREFIX + "sfx/gun_ricochet.wav",
	"ult_dragon": PREFIX + "sfx/ult_dragon.wav",
	"ult_pig": PREFIX + "sfx/ult_pig.wav",
	"ult_monkey": PREFIX + "sfx/ult_monkey.wav",
	"ult_ox": PREFIX + "sfx/ult_ox.wav",
	"ult_tiger": PREFIX + "sfx/ult_tiger.wav",
	"ult_rabbit_in": PREFIX + "sfx/ult_rabbit_in.wav",
	"ult_rabbit_out": PREFIX + "sfx/ult_rabbit_out.wav",
	"ult_snake": PREFIX + "sfx/ult_snake.wav",
	"ult_goat": PREFIX + "sfx/ult_goat.wav",
	"ult_horse": PREFIX + "sfx/ult_horse.wav",
	"ult_dog": PREFIX + "sfx/ult_dog.wav",
	"ult_rooster": PREFIX + "sfx/ult_rooster.wav",
	"ult_rat": PREFIX + "sfx/ult_rat.wav",
	"ult_rat_1": PREFIX + "sfx/ult_rat_1.wav",
	"ult_rat_2": PREFIX + "sfx/ult_rat_2.wav",
	"ult_rat_3": PREFIX + "sfx/ult_rat_3.wav",
	"ult_rat_4": PREFIX + "sfx/ult_rat_4.wav",
	"hit_marker": PREFIX + "sfx/gun_hit.wav",
	"explosion": PREFIX + "sfx/stone_hit.wav",
	"skill_use": PREFIX + "sfx/power_up.wav",
	"down": PREFIX + "sfx/down_kill.wav",
	"eliminate": PREFIX + "sfx/down_kill.wav",
	"pickup": PREFIX + "sfx/potion.wav",
	"ui_click": PREFIX + "sfx/ui_click.wav",
	"match_start": PREFIX + "sfx/ready_to_fight.wav",
	"match_end": PREFIX + "sfx/victory.wav",
	"dash": PREFIX + "sfx/dash_1.wav",
	"dash_1": PREFIX + "sfx/dash_1.wav",
	"dash_2": PREFIX + "sfx/dash_2.wav",
	"ultimate": PREFIX + "sfx/ult_dragon.wav",
	"wall_bounce": PREFIX + "sfx/wall_bounce_1.wav",
	"wall_bounce_1": PREFIX + "sfx/wall_bounce_1.wav",
	"wall_bounce_2": PREFIX + "sfx/wall_bounce_2.wav",
	"wall_bounce_3": PREFIX + "sfx/wall_bounce_3.wav",
	"core_hit": PREFIX + "sfx/stone_hit.wav",
	"gun_upgrade": PREFIX + "sfx/power_up.wav",
	"medkit": PREFIX + "sfx/potion.wav",
	"potion": PREFIX + "sfx/potion.wav",
	"respawn": PREFIX + "sfx/respawn.wav",
	"zone_shrink": PREFIX + "sfx/zone_shrink.wav",
	"zone_tick": PREFIX + "sfx/zone_tick.wav",
	"finisher": PREFIX + "sfx/finisher.wav",
	"victory": PREFIX + "sfx/victory.wav",
	"lose": PREFIX + "sfx/lose.wav",
	"kill_fanfare": PREFIX + "sfx/kill_fanfare.wav",
	"countdown": PREFIX + "sfx/countdown.wav",
	"ready_to_fight": PREFIX + "sfx/ready_to_fight.wav",
	"roulette": PREFIX + "sfx/roulette.wav",
	"power_up": PREFIX + "sfx/power_up.wav",
	"down_kill": PREFIX + "sfx/down_kill.wav",
}

const MUSIC := {
	"lobby": PREFIX + "music/lobby.ogg",
	"match": PREFIX + "music/match.ogg",
	"victory": PREFIX + "music/victory.ogg",
}

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

const ANIMAL_ULT := {
	0: "ult_rat",
	1: "ult_ox",
	2: "ult_tiger",
	3: "ult_rabbit_in",
	4: "ult_dragon",
	5: "ult_snake",
	6: "ult_horse",
	7: "ult_goat",
	8: "ult_monkey",
	9: "ult_rooster",
	10: "ult_dog",
	11: "ult_pig",
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
		return null
	var bytes := file.get_buffer(file.get_length())
	file.close()
	if bytes.size() < 44:
		return null
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = true
	stream.data = bytes.slice(44)
	return stream

static func music_for(track: String) -> AudioStream:
	var path: String = MUSIC.get(track, "")
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			_enable_loop(res)
			return res
	if path.ends_with(".ogg"):
		var abs_path := ProjectSettings.globalize_path(path)
		var stream = AudioStreamOggVorbis.load_from_file(abs_path)
		if stream != null:
			stream.loop = true
			return stream
	return null

static func _enable_loop(res: AudioStream) -> void:
	if res is AudioStreamOggVorbis:
		res.loop = true

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
