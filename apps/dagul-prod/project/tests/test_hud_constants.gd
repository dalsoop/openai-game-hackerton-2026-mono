extends RefCounted
## HUD 스크립트가 로드·인스턴스화 가능하고 상수가 올바른지 검증한다.
## 파싱 에러가 있으면 load()가 null을 반환하고 UI가 통째로 안 뜬다.

const HUD_SCRIPTS := [
	"res://games/dagul/hud/hud.gd",
	"res://games/dagul/hud/hud_pjh.gd",
	"res://games/dagul/hud/hud_buffs.gd",
	"res://games/dagul/hud/hud_abilities.gd",
]

func run(t) -> void:
	_hud_loads(t)
	_hud_instantiates(t)
	_no_self_assign_all(t)
	_color_constants_valid(t)

func _hud_loads(t) -> void:
	for path in HUD_SCRIPTS:
		if not FileAccess.file_exists(path):
			continue
		var script = load(path)
		t.check("%s 로드 성공" % path.get_file(), script != null)

func _hud_instantiates(t) -> void:
	var script = load("res://games/dagul/hud/hud.gd")
	if script == null:
		t.check("hud.gd 인스턴스화", false)
		return
	var inst = script.new()
	t.check("hud.gd 인스턴스화 성공", inst != null)
	if inst is Node:
		inst.queue_free()

func _no_self_assign_all(t) -> void:
	var dirs := ["res://games/dagul/hud", "res://core/autoload", "res://core/contract"]
	for dir_path in dirs:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var file := dir.get_next()
		while file != "":
			if file.ends_with(".gd"):
				_scan_self_assign(t, dir_path + "/" + file)
			file = dir.get_next()

func _scan_self_assign(t, path: String) -> void:
	var src := FileAccess.get_file_as_string(path)
	if src == "":
		return
	for line in src.split("\n"):
		var stripped := line.strip_edges()
		if not stripped.begins_with("const ") and not stripped.begins_with("var "):
			continue
		if stripped.find(":=") < 0:
			continue
		var parts := stripped.split(":=")
		if parts.size() != 2:
			continue
		var vname := parts[0].replace("const ", "").replace("var ", "").strip_edges()
		var value := parts[1].strip_edges()
		t.check("%s: %s 자기 참조 없음" % [path.get_file(), vname], vname != value)

func _color_constants_valid(t) -> void:
	var hud = load("res://games/dagul/hud/hud.gd")
	if hud == null:
		t.check("HUD 색상 상수 검증 불가 (로드 실패)", false)
		return
	for cname in ["PANEL_BG", "ZONE_PURPLE"]:
		var val = hud.get(cname)
		t.check("%s 는 Color 타입" % cname, val is Color)
