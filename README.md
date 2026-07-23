# TANMAK — Godot 웹 탄막 회피 슈팅

Godot 4.7 기반 **웹 브라우저용 탄막 회피 슈팅 게임**. 화면 어디든 터치해 가상 조이스틱으로 플레이어를 움직이며, 시간이 지날수록 WAVE가 올라가고 난이도가 상승한다. 순수 회피(공격 없음, 1HP 즉사) 구조이며, 새 탄막·웨이브를 쉽게 추가할 수 있는 **open-structure**로 설계했다.

## 특징

- **탄막 5종**(확장 가능)
  - 원형(소) / 원형(중) / 원형(대) — 직선 이동, 크기·속도·판정 차등
  - 폭탄 — 점멸(telegraph) 경고 → 점점 빠르게 깜빡임 → 범위(AOE) 폭발
  - 산탄 — 점멸 경고 → 가속 → 중심에서 원형으로 작은 총알 N개 분사
- **WAVE 시스템** — 일정 시간마다 웨이브 진행, 절차적 난이도 곡선(속도·스폰 빈도 상승). 5의 배수 웨이브는 **보스전**(필드 스폰 중지 + 회전 나선 탄막)
- **가상 조이스틱** — 화면 어디든 터치하면 그 점이 조이스틱 중심. 모바일 터치와 데스크탑 마우스 모두 지원
- **1HP 즉사 + 생존 시간 점수** — 클래식 탄막 슈팅. 최고 점수 로컬 저장
- **객체 풀링** — 웹 성능 확보

## 요구사항

- [Godot 4.7](https://godotengine.org/) (stable)
- 웹 내보내기용 **Web template**(nothreads) — 에디터에서 1회 설치

## 실행 (에디터)

1. Godot 에디터로 프로젝트 폴더 열기
2. `F5` 실행 (메인 씬: `scenes/Main.tscn`)
3. 시작 화면에서 화면 클릭/터치 → 게임 시작. 드래그로 이동

## 웹 빌드

1. 에디터 메뉴 **[Editor] → [Manage Export Templates...]** → **Web** 의 nothreads template 다운로드
2. **[Project] → [Export...]** → `Web` 프리셋 확인 → **Export Project**
3. 산출물: `web/index.html`, `index.js`, `index.wasm`, `index.pck`
4. 로컬 테스트:
   ```bash
   cd web
   python -m http.server 8000
   # 브라우저에서 http://localhost:8000
   ```

## 배포 (우분투 + Nginx Proxy Manager)

자세한 절차는 [DEPLOY.md](DEPLOY.md) 참조. 요약:
1. `.env` 에 SSH/서버 정보 작성 (`cp .env.example .env`)
2. 서버에 nginx 설정(`deploy/nginx_tanmak.conf`, 포트 2713) 1회 설치
3. NPM에서 Proxy Host(도메인 → `http://서버IP:2713`) 등록
4. 로컬에서:
   ```bash
   bash deploy/deploy.sh
   ```

## 프로젝트 구조

```
project.godot               # 설정 + Autoload(싱글톤) + 입력 매핑
export_presets.cfg          # Web 내보내기 프리셋 (nothreads)
scripts/
  core/                     # 싱글톤 — EventBus/GameManager/WaveManager/BulletPool
  config/GameConfig.gd      # ★ 튜닝 포인트(속도/난이도 곡선/색상 등 모든 상수)
  data/wave_data.gd         # ★ WAVE 데이터(탄막 해금/패턴 스케줄)
  player/                   # Player.gd, VirtualJoystick.gd
  enemy/                    # Enemy.gd(보스), FieldSpawner.gd
  bullets/                  # ★ BulletBase 상속 트리 + BulletSpawner
  ui/                       # HUD.gd, Screens.gd
scenes/                     # Main.tscn + Player/Bullet/씬
deploy/                     # deploy.sh, nginx_tanmak.conf
```

## 확장 가이드 (open-structure)

**새 탄막 추가** (예: 레이저)
1. `scripts/bullets/LaserBullet.gd` — `BulletBase`(또는 `TelegraphBullet`) 상속, `_reset/_tick/_draw` 구현
2. `scripts/core/BulletPool.gd` — `BulletType` enum에 한 줄 추가 + `_instantiate` 분기
3. `scripts/data/wave_data.gd` — `UNLOCK_AT_WAVE` 에 해금 시점 추가
4. 씬 파일 생성 후 `BulletPool` preload 경로에 등록

**새 WAVE 패턴 / 밸런스 튜닝**
- 난이도 곡선·탄막 속도·스폰 주기 → `scripts/config/GameConfig.gd`
- 웨이브별 등장 탄막·필드 패턴 → `scripts/data/wave_data.gd`

## 라이선스

MIT
