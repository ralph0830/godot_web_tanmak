class_name BulletBase
extends Area2D
## 탄막 베이스 — 수명/이동/충돌/풀 반납 공통 로직.
## 새 탄막은 BulletBase(또는 LinearBullet/TelegraphBullet)를 상속해 _reset/_tick/_draw 만 구현.
## 풀 인터페이스: _on_acquire() 활성화 / _on_release() 비활성화 (BulletPool 이 호출).

var bullet_type: int = -1        # BulletPool.BulletType
var velocity := Vector2.ZERO
var _lifetime := 0.0
var _active := false

@onready var _hit_box: CollisionShape2D = $HitBox


func _ready() -> void:
	z_index = GameConfig.Z_BULLET   # Background 위에 그려지도록
	# 충돌 신호 연결 (플레이어 영역 진입)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	# 풀에 추가되기 전/반납 상태는 비활성
	visible = false
	set_process(false)
	set_physics_process(false)
	if _hit_box:
		_hit_box.set_deferred("disabled", true)


# 풀에서 획득(활성화) — BulletPool.acquire 가 호출
func _on_acquire() -> void:
	visible = true
	set_process(true)
	set_physics_process(true)
	_active = true
	_lifetime = 0.0
	_reset()
	queue_redraw()   # _draw() 즉시 1회 실행 (활성화 직후 표시)


# 풀 반납(비활성화) — BulletPool.release 가 호출
func _on_release() -> void:
	_active = false
	visible = false
	set_process(false)
	set_physics_process(false)
	if _hit_box:
		_hit_box.set_deferred("disabled", true)


# 서브클래스 초기화 훅 (위치/속도/시각/히트박스 설정)
func _reset() -> void:
	velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_lifetime += delta
	position += velocity * delta
	_tick(delta)
	queue_redraw()   # 위치/상태 갱신마다 _draw() 재실행 (탄막 표시)
	# 수명 초과 또는 화면 밖(여유 폭 포함)이면 자동 제거
	if _lifetime > GameConfig.BULLET_LIFETIME or _is_out_of_bounds():
		_despawn()


# 서브클래스 매 프레임 로직 (점멸/가속 등). 기본은 아무 것도 안 함.
func _tick(_delta: float) -> void:
	pass


# 화면 밖 판정 (여유 120px — 화면 밖에서 생성/분해 고려)
func _is_out_of_bounds() -> bool:
	var m := 120.0
	return position.x < -m or position.x > GameConfig.VIEWPORT_WIDTH + m \
		or position.y < -m or position.y > GameConfig.VIEWPORT_HEIGHT + m


# 풀로 반납
func _despawn() -> void:
	BulletPool.release(self)


# 플레이어 접촉 — 플레이어가 player_hit 처리하므로 기본은 동작 없음
func _on_area_entered(_area: Area2D) -> void:
	_on_player_contact()

func _on_body_entered(_body: Node) -> void:
	_on_player_contact()

func _on_player_contact() -> void:
	pass
