class_name BulletSpawner
extends RefCounted
## 탄막 생성 정적 헬퍼 — BulletPool.acquire + launch 래핑.
## FieldSpawner/Enemy 는 이 함수들로 탄막을 발사/배치한다. (인스턴스 없이 사용)

# 원형(직선) 탄막 발사
static func fire_circle(type: int, start: Vector2, direction: Vector2, speed_mul: float = 1.0) -> void:
	var b: Node2D = BulletPool.acquire(type)
	if b != null and b is LinearBullet:
		(b as LinearBullet).launch(start, direction, speed_mul)


# 점멸(폭탄/산탄) 탄막 배치 — 위치 고정, 점멸 후 자동 기폭
static func place_telegraph(type: int, pos: Vector2) -> void:
	var b: Node2D = BulletPool.acquire(type)
	if b != null:
		b.position = pos
