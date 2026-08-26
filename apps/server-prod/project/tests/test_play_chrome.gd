extends RefCounted
## 설정이 열리면 커서를 보이고 패드를 끈다.

const Chrome := preload("res://core/shell/play_chrome.gd")

func run(t) -> void:
	t.check("플레이 중 커서는 숨김", Chrome.mouse_hidden(true, false) == true)
	t.check("설정 중 커서는 보임", Chrome.mouse_hidden(true, true) == false)
	t.check("부팅은 커서 보임", Chrome.mouse_hidden(false, false) == false)
	t.check("플레이 중 패드 켬", Chrome.touch_playing(true, false) == true)
	t.check("설정 중 패드 끔", Chrome.touch_playing(true, true) == false)
