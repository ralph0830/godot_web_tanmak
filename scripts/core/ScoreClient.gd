class_name ScoreClient
extends Node
## 순위 API 클라이언트 — HTTPRequest 로 /api/scores GET(조회)/POST(제출).
## 웹은 same-origin 이므로 base URL 을 window.location.origin 으로 추출.

signal scores_received(scores: Array)     # [{"name":str, "score":int}, ...]
signal submitted(rank: int, scores: Array)
signal request_failed(reason: String)

const DEV_BASE_URL := "http://localhost:2713"   # 에디터/데스크탑 개발용

var _http: HTTPRequest
var _mode: int = 0    # 0=idle, 1=fetch, 2=submit
var _base_url := DEV_BASE_URL


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	# 웹 환경에서는 현재 페이지 origin 을 base 로 사용 (same-origin)
	if OS.has_feature("web"):
		var origin: Variant = JavaScriptBridge.eval("window.location.origin", true)
		if origin is String and (origin as String) != "":
			_base_url = origin


# 상위 순위 조회
func fetch_scores() -> void:
	if _mode != 0:
		return
	_mode = 1
	var err := _http.request(_base_url + GameConfig.SCORE_API_PATH)
	if err != OK:
		_mode = 0
		request_failed.emit("요청 실패(err=%d)" % err)


# 점수 제출 (이름 3자 + 점수)
func submit_score(player_name: String, score: int) -> void:
	if _mode != 0:
		return
	_mode = 2
	var body := JSON.stringify({"name": player_name, "score": score})
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := _http.request(_base_url + GameConfig.SCORE_API_PATH, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_mode = 0
		request_failed.emit("요청 실패(err=%d)" % err)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var mode := _mode
	_mode = 0
	if result != HTTPRequest.RESULT_SUCCESS:
		request_failed.emit("네트워크 오류(result=%d)" % result)
		return
	if response_code < 200 or response_code >= 300:
		request_failed.emit("HTTP %d" % response_code)
		return
	var text := body.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		request_failed.emit("응답 파싱 실패")
		return
	var data: Dictionary = json.data
	if not data.has("scores"):
		request_failed.emit("잘못된 응답 형식")
		return
	var scores: Array = data["scores"]
	if mode == 1:
		scores_received.emit(scores)
	else:
		var rank: int = int(data.get("rank", 0))
		submitted.emit(rank, scores)
