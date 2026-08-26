class_name PlayChrome
extends RefCounted
## 플레이 중 마우스·터치 표시. 설정이 열리면 커서를 되돌리고 패드를 숨긴다.


static func mouse_hidden(playing: bool, settings_open: bool) -> bool:
	return playing and not settings_open


static func touch_playing(playing: bool, settings_open: bool) -> bool:
	return playing and not settings_open
