extends Node
## GameManager (싱글톤) — 게임 상태 머신, 점수, 생존 시간, 생명(1HP) 관리.

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: State = State.MENU
var score: int = 0
var elapsed_time: float = 0.0      # 생존 누적 시간(초)
var current_wave: int = 1
var best_score: int = 0            # 최고 점수 (로컬)


func _ready() -> void:
	# 피격 → 즉사 처리 연결
	EventBus.player_hit.connect(_on_player_hit)
	# 웨이브 보너스는 WaveManager가 wave_changed 발행 시 지급
	EventBus.wave_changed.connect(_on_wave_changed)
	# 최고 점수 로드
	best_score = int(_load_best_score())


func _process(delta: float) -> void:
	# 플레이 중일 때만 생존 시간 누적 → 점수 환산
	if current_state == State.PLAYING:
		elapsed_time += delta
		var new_score := int(elapsed_time * GameConfig.SCORE_PER_SECOND)
		if new_score != score:
			score = new_score
			EventBus.score_changed.emit(score)


# ------------------------------------------------------------
# 게임 라이프사이클
# ------------------------------------------------------------
func start_game() -> void:
	# 상태 초기화 후 플레이 시작 시그널 발행
	current_state = State.PLAYING
	score = 0
	elapsed_time = 0.0
	current_wave = 1
	EventBus.request_clear_field.emit()
	EventBus.game_started.emit()
	EventBus.score_changed.emit(score)
	EventBus.wave_changed.emit(current_wave)


func _on_player_hit() -> void:
	# 1HP 즉사 — 플레이 중일 때만 반응 (중복 트리거 방지)
	if current_state != State.PLAYING:
		return
	current_state = State.GAME_OVER
	# 최고 점수 갱신
	if score > best_score:
		best_score = score
		_save_best_score(best_score)
	EventBus.game_over.emit(score)


func _on_wave_changed(wave: int) -> void:
	# 웨이브가 올라갈 때 보너스 점수 (wave 1 시작 제외)
	if current_state == State.PLAYING and wave > 1:
		score += GameConfig.SCORE_PER_WAVE
		EventBus.score_changed.emit(score)
	current_wave = wave


# ------------------------------------------------------------
# 최고 점수 영속화 (로컬 — 웹에서는 사용자 데이터 저장)
# ------------------------------------------------------------
const BEST_SCORE_KEY := "tanmak_best_score"

func _load_best_score() -> int:
	# 웹/데스크탑 공통 저장소에서 로드 (없으면 0)
	if FileAccess.file_exists("user://" + BEST_SCORE_KEY + ".dat"):
		var f := FileAccess.open("user://" + BEST_SCORE_KEY + ".dat", FileAccess.READ)
		if f != null:
			return f.get_64()
	return 0

func _save_best_score(value: int) -> void:
	var f := FileAccess.open("user://" + BEST_SCORE_KEY + ".dat", FileAccess.WRITE)
	if f != null:
		f.store_64(value)
