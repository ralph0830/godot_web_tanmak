extends Node
## WaveManager (싱글톤) — WAVE 진행 + 절차적 난이도 스케일링.
## 시간이 지날수록 웨이브가 올라가고 난이도 배수가 선형 증가한다.

var current_wave: int = 1
var wave_timer: float = 0.0           # 현재 웨이브 경과 시간
var difficulty_multiplier: float = 1.0 # 현재 난이도 배수 (스폰/속도에 곱적용)
var is_boss_wave: bool = false
var _active: bool = false


func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)


func _on_game_started() -> void:
	# 게임 시작 시 첫 웨이브 적용
	current_wave = 1
	wave_timer = 0.0
	_apply_wave(current_wave)
	_active = true


func _on_game_over(_final_score: int) -> void:
	_active = false
	# 보스전 도중 게임오버 시 보스 종료 처리
	if is_boss_wave:
		EventBus.boss_phase_ended.emit()


func _process(delta: float) -> void:
	if not _active:
		return
	wave_timer += delta
	# 웨이브 지속 시간 도달 → 다음 웨이브로 (첫 웨이브는 초반 단축)
	var duration := GameConfig.WAVE_DURATION
	if current_wave == 1:
		duration = GameConfig.FIRST_WAVE_DURATION
	if wave_timer >= duration:
		_advance_wave()


func _advance_wave() -> void:
	var was_boss := is_boss_wave
	current_wave += 1
	wave_timer = 0.0
	_apply_wave(current_wave)
	EventBus.wave_changed.emit(current_wave)
	# 보스전이 끝나는 웨이브 전환 시 종료 시그널
	if was_boss:
		EventBus.boss_phase_ended.emit()


# 웨이브 상태(난이도/보스여부)를 계산하고 브로드캐스트
func _apply_wave(wave: int) -> void:
	difficulty_multiplier = GameConfig.difficulty_for_wave(wave)
	is_boss_wave = _is_boss_wave(wave)
	EventBus.difficulty_changed.emit(difficulty_multiplier)
	if is_boss_wave:
		EventBus.boss_phase_started.emit()


func _is_boss_wave(wave: int) -> bool:
	return wave % GameConfig.BOSS_WAVE_INTERVAL == 0


# ------------------------------------------------------------
# 난이도 반영 값 (FieldSpawner/Enemy가 조회)
# ------------------------------------------------------------
# 필드 탄막 스폰 주기(초) — 난이도 오를수록 짧아짐(빈번)
func get_spawn_interval() -> float:
	return GameConfig.SPAWN_INTERVAL_BASE / difficulty_multiplier

# 탄막 속도 배수 — 난이도 오를수록 빨라짐
func get_speed_multiplier() -> float:
	return difficulty_multiplier

# 현재 웨이브에서 등장 가능한 탄막 타입 목록 (WaveData 테이블 조회)
func get_available_bullet_types() -> Array:
	return WaveData.get_available_types(current_wave)

# 현재 활성 필드 스폰 패턴 목록 (보스전이면 빈 배열)
func get_active_patterns() -> Array:
	return WaveData.get_patterns(current_wave)
