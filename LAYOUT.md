# TANMAK 레이아웃 명세

뷰포트 **720 × 1280**(세로 모바일), stretch mode `canvas_items` / aspect `expand`. 모든 UI 요소의 위치·사이즈·margin·z-order 명세.

## 1. 캔버스 계층 (z-order)

| z | 요소 | 비고 |
|---|---|---|
| 0 | Background ColorRect | 전체 720×1280, 색 `#0b0e16` |
| 10 | 탄막 (BulletPool) | autoload `Node2D`, 자식 Area2D |
| 15 | Enemy(보스) | 보스 웨이브만 |
| 20 | Player | Area2D |
| UI | HUD / Leaderboard / Screens / Joystick | CanvasLayer(별도 층, z 무관) |

## 2. 플레이 요소 (월드 좌표)

| 요소 | 위치(중심) | 사이즈 | 메모 |
|---|---|---|---|
| Player | (360, 1024) 하단 중앙 | 시각 r12 / 히트박스 r4 | 속도 560px/s, 화면 경계 클램프 r12 |
| Enemy(보스) | (360, 282) 상단 중앙 | r38 | 보스전(5의 배수 웨이브)만 표시 |
| 탄막 원형 소/중/대 | 동적 | r6 / r11 / r18 | 속도 380 / 270 / 175 px/s |
| 폭탄 | 동적 | 경고 r14 → 폭발 AOE r140 (0.55s) | 점멸 2.6s 후 기폭 |
| 산탄 | 동적 | 경고 r12 → 16발 분사 (r6, 320px/s) | 점멸 2.6s 후 기폭 |
| 조이스틱 | 터치 시작점 | 외곽 링 r90 / 핸들 r22 | 터치 중만 표시, `MAX_RADIUS=90` |

## 3. HUD (플레이 중, `HUD.gd`)
모두 `PRESET_FULL_RECT` + `vertical_alignment=TOP`, 데스크탑 좌우 margin 16px.

| 라벨 | 정렬 | offset_top | 폰트 | 색상 |
|---|---|---|---|---|
| SCORE | 중앙 | 12px | 42px | 흰색 |
| WAVE | 좌(margin 16) | 60px | 24px | 회색 (0.8,0.8,0.8) |
| 난이도 x배 | 우(margin 16) | 60px | 22px | 주황 (1.0,0.66,0.34) |

## 4. 타이틀/게임오버 오버레이 (`Screens.gd` + `Leaderboard.gd`)

세로 3-zone 구성:
- **Header** y=0~120 (title/gameover + score)
- **Body(Leaderboard)** y=130~874
- **Footer** y=896~1280 (congrats + 입력 + 안내)

### Screens 라벨 (`_make_label`: FULL_RECT, 중앙, TOP 정렬)

| 요소 | y(ratio) | px | 표시 |
|---|---|---|---|
| TANMAK 타이틀 | 32 (0.025) | 72 | 메뉴 |
| GAME OVER | 32 (0.025) | 56 | 게임오버 |
| Score/Best | 83 (0.065) | 30 | 게임오버 |
| CONGRATULATIONS | 896 (0.70) | 28(2줄) | 갱신 시 |
| subtitle 안내 | 1203 (0.94) | 34 | 항상 |

### 이름 입력 (갱신 시)

| 요소 | 위치(y) | 사이즈 | 환경 |
|---|---|---|---|
| HTML `<input>` | top 76% (≈973) | 240×56, 중앙 | 웹(카톡/모바일 네이티브 키보드) |
| LineEdit | 985 (0.77) | 260×52, 중앙 | 데스크탑/에디터 |
| SUBMIT 버튼 | 1088 (0.85) | 160×52, 중앙 | 데스크탑/에디터 |

### Leaderboard (`Leaderboard.gd`) — 10행
- anchor `(left 0, top 0, right 1, bottom 0)` → 가로 전체, 세로 top 기준 절대 위치
- **outer margin**: 좌우 24px (`offset_left=24`, `offset_right=-24`)
- 행: `top = 130 + i*76` → 130, 206, 282, … 814 / 행높이 60 / 폰트 40
- 전체 영역: **y 130~874** (화면 10%~68%, 헤더 아래~풋터 위 균형)
- 정렬: 중앙, 색상 — 1위 금/2위 은/3위 동/나머지 밝은 회색

```
y=0    ┌──────────── 720 ────────────┐
y=32   │         T A N M A K         │  72px (메뉴) / GAME OVER 56px
y=83   │     Score 1234 · Best 9999  │  30px (게임오버)
       │                             │
y=130  │      1.  AAA     9999       │  ┐ margin 24
y=206  │      2.  BBB     8888       │  │
  …    │      ...                     │  │ 10행, 간격 76, 폰트 40
y=814  │     10.  JJJ     1111       │  ┘
       │                             │
y=896  │ CONGRATULATIONS!! 3 PLACE   │  28px (갱신)
y=973  │      ┌── 240 ──┐             │  HTML input (웹)
y=985  │      ┌── 260 ──┐             │  LineEdit (PC)
y=1088 │      ┌── 160 ──┐             │  SUBMIT (PC)
y=1203 │       TAP TO START          │  34px
y=1280 └─────────────────────────────┘
```

## 5. 비플레이 요소 (시각 없음)
- `FieldSpawner`(autoload 없음, Main 자식 Node2D) — 필드 탄막 스폰 로직만
- `ScoreClient`(Main 자식 Node) — HTTPRequest, 시각 없음
- 싱글톤: EventBus / GameManager / WaveManager / BulletPool(시각=자식 탄막)

## 6. 튜닝 포인트
- 수치(속도/난이도/사이즈): `scripts/config/GameConfig.gd`
- Leaderboard 행 위치/간격/폰트: `scripts/ui/Leaderboard.gd` `_build_rows()`
- Screens 라벨 비율/입력창: `scripts/ui/Screens.gd` `_build()`
- HUD: `scripts/ui/HUD.gd`
- HTML 이름 입력창(웹): `deploy/deploy.sh` post-process(`top:76%` 등)
