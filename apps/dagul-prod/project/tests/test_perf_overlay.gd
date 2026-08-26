extends RefCounted
## 프레임 프로파일 오버레이 — 기본 꺼짐, F3 토글, sessionStorage 부트 플래그.

const PerfOverlayScript := preload("res://games/dagul/render/perf_overlay.gd")


func run(t) -> void:
	var overlay = PerfOverlayScript.new()
	t.check("기본 꺼짐", overlay.enabled == false)
	overlay.toggle()
	t.check("토글 켜짐", overlay.enabled == true)
	t.check("켜면 보임", overlay.visible == true)
	overlay.toggle()
	t.check("토글 꺼짐", overlay.enabled == false)
	t.check("끄면 숨김", overlay.visible == false)
	overlay.set_enabled(true)
	t.check("set_enabled 켜짐", overlay.enabled == true)
	overlay.set_enabled(false)
	t.check("set_enabled 꺼짐", overlay.enabled == false)
	t.check("ls 1은 시작 켜짐", PerfOverlayScript.boot_on_from_ls("1") == true)
	t.check("ls 빈값은 꺼짐", PerfOverlayScript.boot_on_from_ls("") == false)
	t.check("ls 0은 꺼짐", PerfOverlayScript.boot_on_from_ls("0") == false)
	t.check("ls 공백 1은 켜짐", PerfOverlayScript.boot_on_from_ls(" 1 ") == true)
	overlay.free()
