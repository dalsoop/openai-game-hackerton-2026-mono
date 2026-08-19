# deploy/

개발자는 `apps/`만 푸시한다. PVE `hackertone` 러너가 Godot 웹 익스포트·허브 이미지·Helm을 올리고, Cloudflare 퍼지는 GitHub 호스트가 한다. wasm/pck는 git에 넣지 않는다.

- 보드: `https://server-board.external.kr/`
- Actions: https://github.com/dalsoop/openai-game-hackerton-2026-mono/actions/workflows/apps.yml
- 퍼지만: 그 워크플로에서 `purge_only`로 실행

정본은 Actions `Apps ship`이다.

## 한 번만 붙이면 되는 것

1. PVE에 GitHub 러너 `pve-hackertone` (라벨 `hackertone`). `docker`와 `10.0.50.100` SSH가 되면 된다. Godot 4.7.1이 없으면 ship이 받아서 웹을 익스포트한다.
2. 시크릿 `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ZONE_ID` (퍼지)

## 웹 캐시

wasm·pck는 브라우저가 들고 있고, 배포가 끝나면 CI가 Cloudflare를 퍼지한다. 개발 중에 캐시를 직접 비울 필요는 없다. 자기 브라우저만 이상하면 강력 새로고침(`Cmd+Shift+R`)이면 된다.

로컬에서 급히 올릴 때:

```bash
python3 deploy/scripts/apply-apps.py hub server-yjh-dev1
python3 deploy/scripts/apply-apps.py helm
```
