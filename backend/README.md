# TANMAK API - 오락실 순위표 백엔드

Godot 웹 탄막 게임의 순위표 관리를 위한 FastAPI 백엔드 서버입니다.

## 설치 (uv 미설치 시)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## 로컬 실행

```bash
cd backend
uv run uvicorn main:app --port 2715
```

## API 엔드포인트

### `GET /api/scores`

상위 10개 점수 목록을 점수 내림차순으로 반환합니다.

**응답 예시:**
```json
{
  "scores": [
    {"name": "ABC", "score": 1000},
    {"name": "가나다", "score": 900}
  ]
}
```

### `POST /api/scores`

새 점수를 제출합니다.

**요청 본문:**
```json
{
  "name": "ABC",
  "score": 1000
}
```

**검증 규칙:**
- `name`: 정확히 3자, 한글(`가-힣`) 또는 영문(`A-Za-z`) 또는 숫자(`0-9`)만 허용
- `score`: 0 이상의 정수

**응답 예시:**
```json
{
  "rank": 1,
  "scores": [
    {"name": "ABC", "score": 1000},
    {"name": "가나다", "score": 900}
  ]
}
```

**에러 응답:**
- `422`: 이름 또는 점수 형식 위반
  ```json
  {"error": "이름은 정확히 3자여야 하며, 한글/영문/숫자만 허용됩니다"}
  ```
- `429`: 속도 제한 초과 (IP당 3초 쿨다운)
  ```json
  {"error": "rate_limited"}
  ```

## 환경 변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `SCORES_FILE` | `/home/ralph/work/web/tanmak-scores/scores.json` | 점수 저장 파일 경로 |

## 설계 특징

- **동시 쓰기 보호**: `threading.Lock`으로 파일 동시 접근 방지
- **속도 제한**: 클라이언트 IP당 3초 쿨다운 (X-Forwarded-For 헤더 지원)
- **CORS**: 전체 허용 (`*`) - Godot 웹(same-origin)과 로컬 개발 고려
- **원자적 파일 쓰기**: 임시 파일 후 이동 방식으로 데이터 무결성 보장
- **자동 디렉토리 생성**: `SCORES_FILE` 경로의 디렉토리가 없으면 자동 생성
