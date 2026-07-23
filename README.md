# TANMAK — Godot 웹 탄막 회피 슈팅

Godot 4.7 기반 **웹 브라우저용 탄막 회피 슈팅 게임**. 화면 어디든 터치해 가상 조이스틱으로 플레이어를 움직이며, 시간이 지날수록 WAVE가 올라가고 난이도가 상승한다. 순수 회피(공격 없음, 1HP 즉사) 구조이며, 게임오버 시 **오락실 스타일 순위표(서버 저장)** 가 표시된다. 새 탄막·웨이브를 쉽게 추가할 수 있는 **open-structure**로 설계했다.

🎮 데모: **https://tanmak.ralphpark.com**

## 특징

- **탄막 5종**(확장 가능)
  - 원형(소/중/대) — 직선 이동, 크기·속도·판정 차등
  - 폭탄 — 점멸(telegraph) 경고 → 점점 빠르게 깜빡임 → 범위(AOE) 폭발
  - 산탄 — 점멸 경고 → 가속 → 중심에서 원형으로 작은 총알 N개 분사
- **WAVE 시스템** — 첫 웨이브 10초(초반 쉬운 구간 단축), 이후 20초마다 웨이브 진행 + 절차적 난이도 곡선. 5의 배수 웨이브는 **보스전**(필드 스폰 중지 + 회전 나선 탄막)
- **가상 조이스틱** — 화면 어디든 터치하면 그 점이 조이스틱 중심. 모바일 터치·데스크탑 마우스 모두 지원
- **1HP 즉사 + 생존 시간 점수** — 최고 점수 로컬 저장
- **오락실 순위표** — 게임오버 시 상위 10위 표시, 순위권 진입 시 "CONGRATULATIONS!! N PLACE" + 이름 3자 입력 → **서버 저장**(FastAPI + JSON). 타이틀 화면에서도 순위 표시
- **모바일 네이티브 키보드** — 카톡 등 인앱 브라우저 WebView 대응(HTML `<input>` 오버레이)
- **객체 풀링** — 웹 성능 확보

## 아키텍처

```
[브라우저] ──HTTPS──▶ [NPM(openresty):443 tanmak.ralphpark.com]
                          │
              ┌───────────┴────────────┐
              ▼                        ▼
       nginx:2713                FastAPI:2715
       (Godot 웹 정적)            (순위 API /api/scores)
```

- **프론트**: Godot 4.7 웹(WebGL2, nothreads) — 게임 캔버스
- **백엔드**: FastAPI(uvicorn, systemd) — 순위 CRUD, JSON 파일 저장
- **nginx**: 정적 서빙(2713) + `/api/` → 백엔드(2715) 역프록시 + COOP/COEP 헤더
- **NPM**: 도메인/HTTPS 종료

## 요구사항

- [Godot 4.7](https://godotengine.org/) (stable)
- 웹 내보내기용 **Web template**(nothreads) — 에디터에서 1회 설치
- (배포 서버) 우분투 + nginx + Python 3.12(uv)

## 실행 (에디터)

1. Godot 에디터로 프로젝트 폴더 열기
2. `F5` 실행 (메인 씬: `scenes/Main.tscn`)
3. 시작 화면에서 화면 클릭/터치 → 게임 시작. 드래그로 이동

> 에디터/데스크탑에서는 순위 API가 `http://localhost:2713` 으로 호출됨(`ScoreClient.DEV_BASE_URL`). 서버 없이도 게임 자체는 동작(순위 로드 실패 시 건너뜀).

## 웹 빌드

1. 에디터 **[Editor] → [Manage Export Templates...]** → **Web** 의 nothreads template 다운로드
2. **[Project] → [Export...]** → `Web` 프리셋 → **Export Project**
3. 산출물: `web/` (`index.html`, `index.js`, `index.wasm`, `index.pck`)
4. 로컬 테스트: `cd web && python -m http.server 8000` → `http://localhost:8000`

## 배포 (우분투 + Nginx Proxy Manager)

상세: [DEPLOY.md](DEPLOY.md). 요약:
1. `.env` 에 SSH/서버 정보 (`cp .env.example .env`)
2. 서버 nginx(2713) + 백엔드 systemd(tanmak-api:2715) 1회 설치
3. NPM에서 Proxy Host(도메인 → `http://서버IP:2713`) 등록
4. 로컬에서 `bash deploy/deploy.sh` (빌드 + 회색 post-process + 업로드 + 헬스체크)

## 프로젝트 구조

```
project.godot               # 설정 + Autoload(싱글톤) + 입력 매핑
export_presets.cfg          # Web 내보내기 프리셋 (nothreads, 가상키보드 ON)
scripts/
  core/                     # 싱글톤 — EventBus/GameManager/WaveManager/BulletPool(Node2D)
  config/GameConfig.gd      # ★ 튜닝 포인트(속도/난이도/색상/z-order 등 모든 상수)
  data/wave_data.gd         # ★ WAVE 데이터(탄막 해금/패턴 스케줄)
  player/                   # Player.gd, VirtualJoystick.gd
  enemy/                    # Enemy.gd(보스), FieldSpawner.gd
  bullets/                  # ★ BulletBase 상속 트리 + BulletSpawner
  ui/                       # HUD.gd, Screens.gd(메뉴/게임오버/순위/입력), Leaderboard.gd
scenes/                     # Main.tscn + Player/Bullet/씬
backend/                    # FastAPI 순위 API (main.py, pyproject.toml)
deploy/                     # deploy.sh, nginx_tanmak.conf, tanmak-api.service
LAYOUT.md                   # ★ 전체 레이아웃 명세(위치/사이즈/margin/z)
DEPLOY.md                   # 배포 가이드
```

## 백엔드 (순위 API)

상세: [backend/README.md](backend/README.md)

| 메서드 | 경로 | 설명 |
|---|---|---|
| GET | `/api/scores` | 상위 10위 조회 |
| POST | `/api/scores` | `{name, score}` 제출 → 이름 3자(`^[A-Za-z0-9]{3}$`) 검증 → 저장 → 순위 반환 |

로컬 실행: `cd backend && uv run uvicorn main:app --port 2715`

## 확장 가이드 (open-structure)

**새 탄막 추가** (예: 레이저)
1. `scripts/bullets/LaserBullet.gd` — `BulletBase`(또는 `TelegraphBullet`) 상속, `_reset/_tick/_draw` 구현 + `queue_redraw()`
2. `scripts/core/BulletPool.gd` — `BulletType` enum 1줄 + `_instantiate` 분기
3. `scripts/data/wave_data.gd` — `UNLOCK_AT_WAVE` 해금 시점 추가
4. 씬 파일 생성 후 `BulletPool` preload 경로 등록

**밸런스 튜닝** — `scripts/config/GameConfig.gd` (난이도 곡선·탄막 속도·스폰 주기·WAVE 지속시간)
**레이아웃 조정** — [LAYOUT.md](LAYOUT.md) 참고, 해당 스크립트 수치 수정

## 문서

- [LAYOUT.md](LAYOUT.md) — UI 요소 전체 위치/사이즈/margin/z-order 명세
- [DEPLOY.md](DEPLOY.md) — 우분투 + NPM 배포 가이드
- [backend/README.md](backend/README.md) — 순위 API 명세

## 라이선스

MIT
