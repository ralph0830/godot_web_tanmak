class_name Player
extends Area2D
## 플레이어 — 가상 조이스틱 입력으로 이동, 작은 히트박스, 피격 시 1HP 즉사.
## 공격 기능은 없다(순수 회피). 비플레이 중(MENU/GAME_OVER)에는 숨김.

var move_vector := Vector2.ZERO    # 조이스틱이 설정하는 정규화 이동 벡터 (-1.0 ~ 1.0)
var velocity := Vector2.ZERO
var is_alive := false               # 게임 시작 전엔 비활성

@onready var _hit_box: CollisionShape2D = $HitBox


func _ready() -> void:
	add_to_group("player")   # Enemy/FieldSpawner 가 플레이어를 찾기 위한 그룹
	z_index = GameConfig.Z_PLAYER
	# Area2D 충돌 신호 연결 (탄막 영역/본체 진입 → 피격)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)
	_reset_position()
	# 비플레이 중에는 판정 끔 + 숨김
	visible = false
	if _hit_box:
		_hit_box.set_deferred("disabled", true)


# 게임 시작 시 상태 초기화
func _on_game_started() -> void:
	is_alive = true
	move_vector = Vector2.ZERO
	velocity = Vector2.ZERO
	_reset_position()
	visible = true
	if _hit_box:
		_hit_box.set_deferred("disabled", false)
	queue_redraw()


func _on_game_over(_final_score: int) -> void:
	is_alive = false
	move_vector = Vector2.ZERO
	velocity = Vector2.ZERO
	visible = false
	if _hit_box:
		_hit_box.set_deferred("disabled", true)
	queue_redraw()


func _reset_position() -> void:
	# 화면 하단 중앙 배치
	position = Vector2(GameConfig.VIEWPORT_WIDTH / 2.0, GameConfig.VIEWPORT_HEIGHT * 0.8)


func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	# 조이스틱 벡터 → 속도 → 위치 (직접 이동, 물리 시뮬레이션 불필요)
	velocity = move_vector * GameConfig.PLAYER_SPEED
	position += velocity * delta
	# 화면 경계 클램프 (탄막 게임 특성상 화면 밖 이탈 금지)
	var r := GameConfig.PLAYER_RADIUS
	position.x = clamp(position.x, r, GameConfig.VIEWPORT_WIDTH - r)
	position.y = clamp(position.y, r, GameConfig.VIEWPORT_HEIGHT - r)
	queue_redraw()


# 시각 표현 (프로시저럴 도형 — 외부 스프라이트 없이 구현)
func _draw() -> void:
	var r := GameConfig.PLAYER_RADIUS
	var col := GameConfig.COLOR_PLAYER if is_alive else Color(0.5, 0.5, 0.5, 0.4)
	# 외곽 원
	draw_circle(Vector2.ZERO, r * 0.95, col)
	# 코어(밝은 중심)
	draw_circle(Vector2.ZERO, r * 0.42, GameConfig.COLOR_PLAYER_CORE)


# ------------------------------------------------------------
# 피격 처리
# ------------------------------------------------------------
func _on_area_entered(_area: Area2D) -> void:
	_notify_hit()

func _on_body_entered(_body: Node) -> void:
	_notify_hit()

func _notify_hit() -> void:
	# 중복 트리거 가드 (양쪽 Area2D가 동시 신호 보낼 수 있음)
	if not is_alive:
		return
	is_alive = false
	if _hit_box:
		_hit_box.set_deferred("disabled", true)
	EventBus.player_hit.emit()
