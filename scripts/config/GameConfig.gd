class_name GameConfig
extends RefCounted
## 게임 전역 상수/난이도 곡선 정의 (정적 설정 — 튜닝 포인트).
## 모든 매직넘버를 한 곳에 모아 확장/밸런싱을 쉽게 한다.

# ============================================================
# 화면 / 뷰포트
# ============================================================
const VIEWPORT_WIDTH := 720
const VIEWPORT_HEIGHT := 1280

# ============================================================
# 플레이어
# ============================================================
const PLAYER_SPEED := 560.0          # 최대 이동 속도 (픽셀/초)
const PLAYER_RADIUS := 12.0          # 피격 판정 반경 (관대한 회피 판정)
const PLAYER_INNER_SAFE := 4.0       # 시각적 코어보다 히트박스를 작게 (탄막 특유 관대함)

# ============================================================
# 탄막 공통
# ============================================================
const BULLET_LIFETIME := 9.0         # 화면 밖 미처리 안전장치 수명(초)
const BULLET_POOL_SIZE := 180        # 타입별 풀 사이즈

# 원형 탄막 3종 프리셋 (반경 / 속도 / 색상)
enum CircleSize { SMALL, MEDIUM, LARGE }
const CIRCLE_PRESETS := {
	CircleSize.SMALL:  { "radius": 6.0,  "speed": 380.0, "color": Color(1.00, 0.48, 0.45) },
	CircleSize.MEDIUM: { "radius": 11.0, "speed": 270.0, "color": Color(1.00, 0.66, 0.34) },
	CircleSize.LARGE:  { "radius": 18.0, "speed": 175.0, "color": Color(0.55, 0.85, 1.00) },
}

# ============================================================
# 폭탄 / 산탄 (Telegraph → 가속 → 기폭)
# ============================================================
const TELEGRAPH_TOTAL_DURATION := 2.6   # 점멸 시작부터 기폭까지 총 시간(초)
const TELEGRAPH_INITIAL_INTERVAL := 0.45 # 점멸 시작 주기(초, 느림)
const TELEGRAPH_MIN_INTERVAL := 0.05     # 가속 후 도달하는 최소 주기(초, 매우 빠름)

const BOMB_EXPLOSION_RADIUS := 140.0     # 폭탄 폭발 AOE 반경
const BOMB_EXPLOSION_DURATION := 0.55    # AOE 지속 시간(초)

const SCATTER_FRAGMENT_COUNT := 16       # 산탄 기폭 시 원형 분사 개수
const SCATTER_FRAGMENT_SPEED := 320.0    # 분사 파편 속도

# ============================================================
# WAVE / 난이도 곡선
# ============================================================
const WAVE_DURATION := 10.0           # 웨이브 지속 시간(초) — 짧게 해 난이도 상승을 빠르게
const BOSS_WAVE_INTERVAL := 5         # 5의 배수 웨이브 = 보스전
const DIFFICULTY_BASE := 1.0          # 시작 난이도 배수
const DIFFICULTY_GROWTH := 0.13       # 웨이브당 난이도 선형 증가율
const SPAWN_INTERVAL_BASE := 0.65     # 필드 스폰 주기 시작값(초) — 작을수록 빈번(초반 밀도)
const MAX_DIFFICULTY := 4.0           # 난이도 상한 (무한 증가 방지)

# ============================================================
# 점수
# ============================================================
const SCORE_PER_SECOND := 10          # 생존 초당 점수
const SCORE_PER_WAVE := 500           # 웨이브 통과 보너스

# === 순위표 (오락실 스타일) ===
const LEADERBOARD_SIZE := 10          # 순위 표시 개수
const NAME_LENGTH := 3                # 이름 글자 수 (정확히 3자)
const SCORE_API_PATH := "/api/scores" # 순위 API 경로 (same-origin)

# ============================================================
# 색상 팔레트
# ============================================================
const COLOR_PLAYER := Color(0.345, 0.651, 1.000)
const COLOR_PLAYER_CORE := Color(0.92, 0.96, 1.0)
const COLOR_BG := Color(0.045, 0.058, 0.086)
const COLOR_TELEGRAPH := Color(1.0, 0.20, 0.20, 0.55)
const COLOR_EXPLOSION := Color(1.0, 0.55, 0.20, 0.75)
const COLOR_JOYSTICK := Color(1.0, 1.0, 1.0, 0.18)
const COLOR_JOYSTICK_ACTIVE := Color(0.345, 0.651, 1.0, 0.45)

# === Z-Order (그리기 우선순위 — Background 위에 탄막/적/플레이어) ===
const Z_BACKGROUND := 0
const Z_BULLET := 10
const Z_ENEMY := 15
const Z_PLAYER := 20


# ------------------------------------------------------------
# 웨이브 → 난이도 배수 (선형 곡선, 상한 적용)
# ------------------------------------------------------------
static func difficulty_for_wave(wave: int) -> float:
	var value := DIFFICULTY_BASE + float(max(wave - 1, 0)) * DIFFICULTY_GROWTH
	return min(value, MAX_DIFFICULTY)
