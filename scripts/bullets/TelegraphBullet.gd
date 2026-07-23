class_name TelegraphBullet
extends BulletBase
## 점멸 경고 → 점멸 가속 → 기폭 3단계 베이스 (폭탄/산탄 공통).
## 위치 고정(이동 없음). 점멸 주기가 총 시간에 비례해 점점 짧아진 뒤 _detonate() 로 기폭.

enum Phase { TELEGRAPH, DETONATE }

const FADE_ON := 1.0
const FADE_OFF := 0.25

var _phase := Phase.TELEGRAPH
var _elapsed := 0.0          # 점멸 시작 후 경과
var _blink_timer := 0.0
var _blink_interval := 0.45  # 현재 점멸 주기
var _blink_visible := true


func _reset() -> void:
	super._reset()
	_phase = Phase.TELEGRAPH
	_elapsed = 0.0
	_blink_timer = 0.0
	_blink_interval = GameConfig.TELEGRAPH_INITIAL_INTERVAL
	_blink_visible = true
	# 점멸(경고) 단계에서는 피격 판정 없음
	if _hit_box:
		_hit_box.set_deferred("disabled", true)


func _tick(delta: float) -> void:
	_elapsed += delta
	# 점멸 주기: 총 시간 대비 진행도에 따라 최소 주기로 선형 수렴(점점 빠르게 깜빡임)
	var progress := clampf(_elapsed / GameConfig.TELEGRAPH_TOTAL_DURATION, 0.0, 1.0)
	_blink_interval = lerpf(GameConfig.TELEGRAPH_INITIAL_INTERVAL, GameConfig.TELEGRAPH_MIN_INTERVAL, progress)
	_blink_timer += delta
	if _blink_timer >= _blink_interval:
		_blink_timer = 0.0
		_blink_visible = not _blink_visible
		queue_redraw()
	# 기폭 시점 도달
	if _elapsed >= GameConfig.TELEGRAPH_TOTAL_DURATION:
		_detonate()


# 기폭 — 서브클래스 구현 (폭탄: AOE / 산탄: 원형 분사). 기본은 제거.
func _detonate() -> void:
	_despawn()
