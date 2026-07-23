# TANMAK API — 오락실 순위표 백엔드

Godot 웹 탄막 게임의 순위표 관리를 위한 FastAPI 백엔드 서버.

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

상위 10개 점수를 점수 내림차순으로 반환.

**응답:**
```json
{
  "scores": [
    {"name": "ABC", "score": 1000},
    {"name": "XYZ", "score": 900}
  ]
}
```

### `POST /api/scores`

새 점수 제출 → 정렬 삽입 → 상위 10 유지 → 순위 반환.

**요청 본문:**
```json
{ "name": "ABC", "score": 1000 }
```

**검증 규칙:**
- `name`: 정확히 3자, 영문(`A-Za-z`) 또는 숫자(`0-9`)만 허용 (정규식 `^[A-Za-z0-9]{3}$`)
- `score`: 0 이상 정수

> 게임 UI는 영문 폰트만 지원하므로 이름 입력도 영문/숫자로 제한한다.

**응답:**
```json
{
  "rank": 1,
  "scores": [
    {"name": "ABC", "score": 1000},
    {"name": "XYZ", "score": 900}
  ]
}
```

**에러 응답:**
- `422`: 이름/점수 형식 위반 (`{"error": "..."}`)
- `429`: 속도 제한 초과 (IP당 3초 쿨다운, `{"error": "rate_limited"}`)

## 환경 변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `SCORES_FILE` | `/home/ralph/work/web/tanmak-scores/scores.json` | 점수 저장 파일 경로 |

## 설계 특징

- **동시 쓰기 보호**: `threading.Lock` 으로 파일 동시 접근 방지
- **속도 제한**: 클라이언트 IP당 3초 쿨다운 (`X-Forwarded-For` 헤더 지원)
- **CORS**: 전체 허용 (`*`) — Godot 웹(same-origin) 및 로컬 개발 고려
- **원자적 파일 쓰기**: 임시 파일 후 이동 방식으로 무결성 보장
- **자동 디렉토리 생성**: `SCORES_FILE` 경로의 디렉토리 부재 시 자동 생성

## 배포 (systemd)

서비스 유닛 `deploy/tanmak-api.service`:
```ini
ExecStart=/home/ralph/.local/bin/uv run uvicorn main:app --host 127.0.0.1 --port 2715
WorkingDirectory=/home/ralph/work/web/tanmak-api
Environment=SCORES_FILE=/home/ralph/work/web/tanmak-scores/scores.json
```

nginx 가 `/api/` 를 `127.0.0.1:2715` 로 역프록시(동일 출처 → CORS 불필요). 상세는 [DEPLOY.md](../DEPLOY.md).
