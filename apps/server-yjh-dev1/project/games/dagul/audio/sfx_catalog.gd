class_name SfxCatalog
extends RefCounted

const SOUNDS := {
	"gun_fire": "res://games/dagul/assets/sfx/gun_fire.wav",
	"gun_reload": "res://games/dagul/assets/sfx/gun_reload.wav",
	"hit_marker": "res://games/dagul/assets/sfx/hit_marker.wav",
	"explosion": "res://games/dagul/assets/sfx/explosion.wav",
	"skill_use": "res://games/dagul/assets/sfx/skill_use.wav",
	"down": "res://games/dagul/assets/sfx/down.wav",
	"eliminate": "res://games/dagul/assets/sfx/eliminate.wav",
	"pickup": "res://games/dagul/assets/sfx/pickup.wav",
	"ui_click": "res://games/dagul/assets/sfx/ui_click.wav",
	"match_start": "res://games/dagul/assets/sfx/match_start.wav",
	"match_end": "res://games/dagul/assets/sfx/match_end.wav",
	"dash": "res://games/dagul/assets/sfx/dash.wav",
	"ultimate": "res://games/dagul/assets/sfx/ultimate.wav",
	"wall_bounce": "res://games/dagul/assets/sfx/wall_bounce.wav",
	"core_hit": "res://games/dagul/assets/sfx/core_hit.wav",
	"gun_upgrade": "res://games/dagul/assets/sfx/gun_upgrade.wav",
	"medkit": "res://games/dagul/assets/sfx/medkit.wav",
}

const MUSIC := {
	"lobby": "res://games/dagul/assets/music/lobby.ogg",
	"match": "res://games/dagul/assets/music/match.ogg",
	"victory": "res://games/dagul/assets/music/victory.ogg",
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
