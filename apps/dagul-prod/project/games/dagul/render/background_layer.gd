extends Node2D
## 섬(바다+잔디) 전용 레이어. 타일 범위·줌·텍스처가 바뀔 때만 queue_redraw.

const RenderEnvScript = preload("res://games/dagul/render/render_environment.gd")
const ZOOM_RATIO := 0.01
const FALLBACK_CELL := 192.0

var world
var grass_tile_textures: Array[Texture2D] = []
var _view: Node2D
var _env
var _last_tiles := Rect2i(2147483647, 0, 0, 0)
var _last_zoom := -1.0
var _last_tex_n := -1
var _last_world := 0


func setup(view: Node2D) -> void:
	_view = view
	_env = RenderEnvScript.new(self)
	name = "BackgroundLayer"
	show_behind_parent = true
	z_index = -1
	z_as_relative = true


func visible_world_rect() -> Rect2:
	if _view != null and _view.has_method("visible_world_rect"):
		return _view.visible_world_rect()
	return Rect2(-1.0e7, -1.0e7, 2.0e7, 2.0e7)


func grass_cell() -> float:
	if grass_tile_textures.is_empty():
		return FALLBACK_CELL
	return grass_tile_textures[0].get_size().x * 6.0


func sync() -> void:
	_copy_from_view()
	if not _is_dirty():
		return
	_store_stamp()
	queue_redraw()


func _copy_from_view() -> void:
	if _view == null:
		return
	world = _view.world
	grass_tile_textures = _view.grass_tile_textures


func _is_dirty() -> bool:
	var tiles := RenderEnvScript.vis_tile_rect(visible_world_rect(), grass_cell())
	if tiles != _last_tiles:
		return true
	if grass_tile_textures.size() != _last_tex_n:
		return true
	if _obj_id(world) != _last_world:
		return true
	return _zoom_changed(_camera_zoom())


func _zoom_changed(zoom: float) -> bool:
	if _last_zoom < 0.0:
		return true
	return absf(zoom - _last_zoom) >= maxf(_last_zoom, 0.001) * ZOOM_RATIO


func _store_stamp() -> void:
	_last_tiles = RenderEnvScript.vis_tile_rect(visible_world_rect(), grass_cell())
	_last_zoom = _camera_zoom()
	_last_tex_n = grass_tile_textures.size()
	_last_world = _obj_id(world)


func _obj_id(obj) -> int:
	if obj == null:
		return 0
	return int(obj.get_instance_id())


func _camera_zoom() -> float:
	if not is_inside_tree():
		return 1.0
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return 1.0
	return cam.zoom.x


func _draw() -> void:
	if world == null or _env == null:
		return
	_env.world = world
	_env.draw_island()
