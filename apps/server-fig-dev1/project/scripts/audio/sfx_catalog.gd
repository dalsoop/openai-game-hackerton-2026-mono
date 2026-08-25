class_name SfxCatalog
extends RefCounted

const SOUNDS := {
	"gun_fire": "res://assets/sfx/gun_fire.wav",
	"gun_reload": "res://assets/sfx/gun_reload.wav",
	"hit_marker": "res://assets/sfx/hit_marker.wav",
	"explosion": "res://assets/sfx/explosion.wav",
	"skill_use": "res://assets/sfx/skill_use.wav",
	"down": "res://assets/sfx/down.wav",
	"eliminate": "res://assets/sfx/eliminate.wav",
	"pickup": "res://assets/sfx/pickup.wav",
	"ui_click": "res://assets/sfx/ui_click.wav",
	"match_start": "res://assets/sfx/match_start.wav",
	"match_end": "res://assets/sfx/match_end.wav",
	"dash": "res://assets/sfx/dash.wav",
	"ultimate": "res://assets/sfx/ultimate.wav",
	"wall_bounce": "res://assets/sfx/wall_bounce.wav",
	"core_hit": "res://assets/sfx/core_hit.wav",
	"gun_upgrade": "res://assets/sfx/gun_upgrade.wav",
	"medkit": "res://assets/sfx/medkit.wav",
}

const MUSIC := {
	"lobby": "res://assets/music/lobby.ogg",
	"match": "res://assets/music/match.ogg",
	"victory": "res://assets/music/victory.ogg",
}

static func stream_for(sound_id: String) -> AudioStream:
	var path: String = SOUNDS.get(sound_id, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)

static func music_for(track: String) -> AudioStream:
	var path: String = MUSIC.get(track, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)
