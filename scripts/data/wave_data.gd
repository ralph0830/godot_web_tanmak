class_name WaveData
extends RefCounted
## WAVE 데이터 테이블 (데이터 기반 확장).
## 새 탄막/패턴의 등장 시점은 이 파일만 수정하면 된다.

# 웨이브별 탄막 해금 시점 (이름 -> 해금 웨이브 번호)
# 새 탄막을 추가하면 UNLOCK_AT_WAVE + BulletPool.BulletType enum 2곳만 건드리면 됨.
const UNLOCK_AT_WAVE := {
	"CIRCLE_SMALL": 1,
	"CIRCLE_MEDIUM": 2,
	"SCATTER": 3,
	"BOMB": 4,
	"CIRCLE_LARGE": 6,
}

# 필드 스폰 패턴 종류 (FieldSpawner가 해석)
enum Pattern { TOP_RAIN, SIDE_WEAVE, RING_CENTER, RANDOM_AIM }

# 웨이브 구간별 활성 패턴 세트 (wave 이상에서 가장 큰 키를 사용)
const PATTERN_AT_WAVE := {
	1: [Pattern.TOP_RAIN],
	2: [Pattern.TOP_RAIN, Pattern.SIDE_WEAVE],
	3: [Pattern.RING_CENTER],
	4: [Pattern.RANDOM_AIM, Pattern.TOP_RAIN],
	6: [Pattern.TOP_RAIN, Pattern.RING_CENTER, Pattern.SIDE_WEAVE],
	8: [Pattern.RANDOM_AIM, Pattern.RING_CENTER, Pattern.TOP_RAIN, Pattern.SIDE_WEAVE],
}


# wave에 해금된 탄막 타입(BulletPool.BulletType) 배열 반환
static func get_available_types(wave: int) -> Array:
	var types: Array = []
	for key in UNLOCK_AT_WAVE.keys():
		if wave >= int(UNLOCK_AT_WAVE[key]):
			types.append(_string_to_bullet_type(key))
	return types


# wave의 활성 필드 패턴 배열 반환 (보스전이면 빈 배열 → FieldSpawner 정지)
static func get_patterns(wave: int) -> Array:
	if wave % GameConfig.BOSS_WAVE_INTERVAL == 0:
		return []
	var chosen: Array = [Pattern.TOP_RAIN]  # 기본값
	for w in PATTERN_AT_WAVE.keys():
		if wave >= int(w):
			chosen = PATTERN_AT_WAVE[w]
	return chosen


# 탄막 이름 문자열 → BulletPool.BulletType enum 변환
static func _string_to_bullet_type(name_str: String) -> int:
	match name_str:
		"CIRCLE_SMALL":  return BulletPool.BulletType.CIRCLE_SMALL
		"CIRCLE_MEDIUM": return BulletPool.BulletType.CIRCLE_MEDIUM
		"CIRCLE_LARGE":  return BulletPool.BulletType.CIRCLE_LARGE
		"BOMB":          return BulletPool.BulletType.BOMB
		"SCATTER":       return BulletPool.BulletType.SCATTER
	push_warning("WaveData: 알 수 없는 탄막 이름 " + name_str)
	return BulletPool.BulletType.CIRCLE_SMALL
