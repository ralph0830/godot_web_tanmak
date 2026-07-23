extends Node
## BulletPool (싱글톤) — 탄막 객체 풀링으로 웹 성능 확보.
## instantiate/free 반복 대신 visible/process 토글로 객체를 재사용한다.

const CircleScene := preload("res://scenes/bullets/BulletCircle.tscn")
const BombScene := preload("res://scenes/bullets/BulletBomb.tscn")
const ScatterScene := preload("res://scenes/bullets/BulletScatter.tscn")

# 탄막 종류 식별자 — 새 탄막 추가 시 enum에 한 줄 추가
enum BulletType { CIRCLE_SMALL, CIRCLE_MEDIUM, CIRCLE_LARGE, BOMB, SCATTER }

var _pools: Dictionary = {}  # BulletType(int) -> Array[Node2D]


func _ready() -> void:
	# 타입별 빈 풀 초기화
	for t in BulletType.values():
		_pools[t] = []
	# 필드 정리 요청에 대응
	EventBus.request_clear_field.connect(clear_all)


# 타입에 맞는 탄막 1개를 획득(활성화)한다.
func acquire(type: int) -> Node2D:
	var pool: Array = _pools.get(type, [])
	# 비활성(visible=false) 슬롯을 먼저 재사용
	for b in pool:
		if is_instance_valid(b) and not b.visible:
			b._on_acquire()
			return b
	# 가용 슬롯이 없으면 새로 생성해 풀에 추가
	var bullet: Node2D = _instantiate(type)
	if bullet == null:
		push_error("BulletPool: 알 수 없는 탄막 타입 " + str(type))
		return null
	bullet.bullet_type = type
	add_child(bullet)
	pool.append(bullet)
	bullet._on_acquire()
	return bullet


# 사용 완료 탄막을 비활성화(풀 반납).
func release(bullet: Node2D) -> void:
	if bullet == null or not is_instance_valid(bullet):
		return
	bullet._on_release()


# 모든 활성 탄막 비활성화 (게임오버/재시작 정리).
func clear_all() -> void:
	for t in _pools.keys():
		for b in _pools[t]:
			release(b)


# 타입 → 씬 인스턴스 생성 (새 탄막 추가 시 match에 분기 추가)
func _instantiate(type: int) -> Node2D:
	match type:
		BulletType.CIRCLE_SMALL:  return _new_circle(GameConfig.CircleSize.SMALL)
		BulletType.CIRCLE_MEDIUM: return _new_circle(GameConfig.CircleSize.MEDIUM)
		BulletType.CIRCLE_LARGE:  return _new_circle(GameConfig.CircleSize.LARGE)
		BulletType.BOMB:          return BombScene.instantiate()
		BulletType.SCATTER:       return ScatterScene.instantiate()
	return null


func _new_circle(size: int) -> Node2D:
	var c: Node2D = CircleScene.instantiate()
	c.circle_size = size
	return c
