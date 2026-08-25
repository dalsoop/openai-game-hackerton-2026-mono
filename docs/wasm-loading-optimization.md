# WASM 로딩 최적화 보고서

## 현재 상태

| 파일 | 크기 |
|---|---|
| index.wasm | 38 MB |
| index.pck | 28 MB |
| **합계** | **66 MB** |

브라우저에서 66MB를 다운로드하고 WASM을 컴파일해야 하므로 로딩이 매우 느리고, 그 동안 메인 스레드가 멈춤.

## 근본 원인 분석

### PCK 28MB 내역

| 에셋 경로 | 크기 | 비고 |
|---|---|---|
| assets/ui/ | 19 MB | lobby_row(4.3M), lobby_bg(2.6M), lobby_create(2.6M), banner_select(2.4M), 모드 이미지 5종(6.4M) |
| assets/fx/ | 7.8 MB | 동물 궁극기 이펙트 (1MB 급 PNG 다수) |
| assets/hud/ | 4.8 MB | HUD 에셋 |
| assets/fonts/ | 852 KB | GmarketSansMedium.otf |
| 나머지 | ~1 MB | sprites, items, world, data |

**즉시 절감 가능**: 모드 이미지 4종(classic/gun-semi/gun-auto/item) = **5.2MB 제거** (full 모드만 남았으므로)

### WASM 38MB

- Godot 4.7 GL Compatibility 렌더러의 기본 WASM 크기
- `export_filter="all_resources"` 설정 → 사용하지 않는 리소스도 포함
- `vram_texture_compression/for_desktop=true` → 데스크톱 GPU 텍스처 포함
- Thread support = false (올바름, 이게 없으면 SharedArrayBuffer 불필요)

## 해결책

### 즉시 적용 (배포 설정)

#### 1. 서버 gzip/brotli 압축 (효과: 60~70% 절감)
WASM과 PCK는 압축률이 매우 높음.
- gzip: 38MB → ~12MB, 28MB → ~9MB → 합계 ~21MB
- brotli: 38MB → ~8MB, 28MB → ~7MB → 합계 ~15MB

nginx/Caddy 설정에서 .wasm, .pck 파일에 대해 압축 전송을 활성화하거나,
미리 압축된 파일(.wasm.gz, .pck.gz)을 배포하고 Content-Encoding: gzip 헤더를 설정.

Caddy 예시:
```
encode gzip {
    match {
        path *.wasm *.pck *.js
    }
}
```

#### 2. 사용하지 않는 모드 에셋 제거 (효과: ~5MB 절감)
모드가 full 1종만 남았으므로 다음 파일을 exclude하거나 삭제:
- assets/ui/mode_classic.png (1.3MB)
- assets/ui/mode_gun_semi.png (1.3MB)
- assets/ui/mode_gun_auto.png (1.1MB)
- assets/ui/mode_item.png (1.3MB)

export_presets.cfg에서:
```
exclude_filter="assets/ui/mode_classic.png, assets/ui/mode_gun_semi.png, assets/ui/mode_gun_auto.png, assets/ui/mode_item.png"
```

#### 3. export_filter 변경 (효과: 수 MB 절감)
`export_filter="all_resources"` → `export_filter="resources"` 또는 `export_filter="scenes"`로 변경하면 사용하지 않는 리소스가 PCK에서 제외됨.

### 중기 적용

#### 4. PNG → WebP 변환 (효과: 50~80% 절감)
35MB의 에셋 대부분이 PNG. WebP로 변환하면:
- lobby_row.png 4.3MB → ~500KB
- lobby_bg.png 2.6MB → ~300KB
- 동물 이펙트 PNG → 각 100~300KB

Godot import 설정에서 `compress/mode=lossy`, `lossy_quality=0.75` 설정.

#### 5. 텍스처 해상도 제한
웹 내보내기에서 텍스처를 1024x1024 또는 512x512로 제한:
project.godot에서:
```
[rendering]
textures/canvas_textures/default_texture_filter=0
```

#### 6. WASM 크기 축소
커스텀 export template 빌드 (3D/Physics 제거):
- 2D 전용이므로 3D 렌더러, 3D Physics, Navigation 등을 컴파일에서 제외
- 효과: 38MB → ~15~20MB

### 로딩 UX (현재 custom_shell.html 분석)

현재 custom_shell.html은 이미 다음을 포함:
- ✅ 타이틀 "다굴 같이하기"
- ✅ 부제 "8명 · 한 판 · 마지막 한 명"
- ✅ 프로그레스 바 (onProgress 콜백)
- ✅ 0.4초 페이드아웃 전환

**문제**: 프로그레스 바가 WASM 컴파일 중에는 진행하지 않음 (다운로드만 추적). WASM 컴파일은 수 초~수십 초 걸리는데 이 동안 바가 멈춤.

#### 개선: 다운로드 완료 후 "게임 준비 중..." 텍스트 표시

```javascript
'onProgress': function (current, total) {
    if (current > 0 && total > 0) {
        statusProgress.value = current;
        statusProgress.max = total;
        if (current === total) {
            // 다운로드 완료, WASM 컴파일 중
            document.getElementById('boot-copy').querySelector('em').textContent = '게임을 준비하는 중입니다...';
        }
    }
}
```

#### 개선: 다운로드 용량 표시

```javascript
const sizeMB = (current / 1024 / 1024).toFixed(1);
const totalMB = (total / 1024 / 1024).toFixed(1);
document.getElementById('boot-copy').querySelector('em').textContent = 
    `다운로드 중 ${sizeMB}/${totalMB} MB`;
```

## 메인 스레드 블로킹 문제

### 원인
Godot WASM이 싱글 스레드 모드(`thread_support=false`)로 실행되므로, 게임 루프가 메인 스레드에서 돌아감. 이것 자체는 정상이고 SharedArrayBuffer 없이도 동작하는 올바른 설정.

### 로딩 중 멈추는 이유
WASM 컴파일이 메인 스레드에서 동기적으로 실행됨. 브라우저가 `WebAssembly.compileStreaming()`을 사용하면 비동기적이지만, 38MB WASM은 컴파일 자체가 수 초 걸림.

### 해소
- gzip/brotli 압축으로 다운로드 시간 단축 → 체감 로딩 시간 감소
- 커스텀 template으로 WASM 크기 자체를 줄이면 컴파일 시간도 감소
- 로딩 UX 개선으로 "멈춘 것처럼 보이는" 문제 완화

## 우선순위 정리

| 순위 | 작업 | 효과 | 난이도 |
|---|---|---|---|
| 1 | 서버 gzip/brotli 압축 | 66MB → ~15~21MB | 서버 설정만 |
| 2 | 불필요 모드 에셋 제거 | ~5MB 절감 | export_presets 변경 |
| 3 | 로딩 UX 개선 (용량 표시 + 준비 중 메시지) | 체감 개선 | custom_shell.html |
| 4 | PNG → WebP 변환 | 에셋 50~80% 절감 | import 설정 |
| 5 | 커스텀 export template (3D 제거) | WASM 38→15MB | 빌드 환경 필요 |
