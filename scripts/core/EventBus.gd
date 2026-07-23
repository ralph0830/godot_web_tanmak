extends Node
## EventBus (싱글톤) — 모든 노드 간 결합도를 낮추는 글로벌 시그널 허브.
## 노드들은 서로를 직접 참조하지 않고 이 시그널로 통신한다.

# 플레이어가 탄막에 피격 (1HP → 즉사). 데미지 인자 없음(즉사).
signal player_hit

# 게임 시작 (초기화 완료 후 플레이 진입)
signal game_started

# 게임 오버. 최종 점수를 전달.
signal game_over(final_score: int)

# 점수 변경 (생존 시간 누적 / 웨이브 보너스)
signal score_changed(score: int)

# 웨이브 변경 (새 웨이브 진입)
signal wave_changed(wave: int)

# 난이도 배수 변경 (UI/스폰 반영용)
signal difficulty_changed(multiplier: float)

# 보스전 시작/종료 (필드 스폰 제어, BGM 전환 등)
signal boss_phase_started
signal boss_phase_ended

# 화면 전체 정리 요청 (재시작 시 모든 탄막/이펙트 제거)
signal request_clear_field
