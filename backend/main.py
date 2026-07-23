# ============================================================
# TANMAK 오락실 순위표 API - FastAPI
# ------------------------------------------------------------
# Godot 웹 탄막 게임의 순위표 백엔드 서버
# - GET /api/scores: 상위 10개 점수 목록 반환
# - POST /api/scores: 새 점수 제출 (이름 검증, 정렬 삽입)
# ============================================================

from __future__ import annotations

import os
import re
import threading
import time
from collections import defaultdict
from typing import Any

import uvicorn
from fastapi import FastAPI, HTTPException, Request, Response, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, field_validator

# ============================================================
# 설정 (환경변수 + 기본값)
# ============================================================

SCORES_FILE = os.getenv(
    "SCORES_FILE",
    "/home/ralph/work/web/tanmak-scores/scores.json"
)
# 속도 제한: IP당 3초 쿨다운
RATE_LIMIT_COOLDOWN = 3.0

# ============================================================
# 데이터 모델
# ============================================================


class ScoreEntry(BaseModel):
    """점수 항목 모델"""
    name: str = Field(..., min_length=1, description="플레이어 이름 (정확히 3자)")
    score: int = Field(..., ge=0, description="점수 (0 이상)")

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        """
        이름 검증: 정확히 3자, 한글/영문/숫자만 허용
        정규식: ^[가-힣A-Za-z0-9]{3}$
        """
        if not isinstance(v, str):
            raise ValueError("이름은 문자열이어야 합니다")

        # 정확히 3자인지 확인 (한글/영문/숫자)
        pattern = r"^[가-힣A-Za-z0-9]{3}$"
        if not re.fullmatch(pattern, v):
            raise ValueError(
                "이름은 정확히 3자여야 하며, 한글/영문/숫자만 허용됩니다"
            )
        return v


class ScoreListResponse(BaseModel):
    """점수 목록 응답"""
    scores: list[ScoreEntry]


class ScoreSubmitResponse(BaseModel):
    """점수 제출 응답"""
    rank: int = Field(..., ge=1, description="제출한 점수의 순위 (1-based)")
    scores: list[ScoreEntry] = Field(..., description="현재 상위 10개 점수")


class ErrorResponse(BaseModel):
    """에러 응답"""
    error: str


# ============================================================
# FastAPI 앱 설정
# ============================================================

app = FastAPI(
    title="TANMAK Leaderboard API",
    description="오락실 스타일 탄막 게임 순위표",
    version="0.1.0"
)

# CORS 미들웨어 - 로컬 개발/직접 호출 안전을 위해 전체 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# ============================================================
# 전역 상태 (파일 락 + 속도 제한)
# ============================================================

# JSON 파일 동시 쓰기 보호용 락
file_lock = threading.Lock()

# 속도 제한: IP별 마지막 요청 시간
rate_limit_tracker: dict[str, float] = defaultdict(float)

# ============================================================
# 파일 I/O 헬퍼 함수
# ============================================================


def load_scores() -> list[dict[str, Any]]:
    """
    scores.json 파일에서 점수 목록 로드
    - 파일이 없으면 빈 리스트 반환
    - JSON 파싱 실패 시 빈 리스트 반환 (안전 장치)
    """
    try:
        with open(SCORES_FILE, "r", encoding="utf-8") as f:
            import json
            data = json.load(f)
            if isinstance(data, list):
                return data
            # 잘못된 형식이면 빈 리스트로 초기화
            return []
    except FileNotFoundError:
        # 파일 없으면 빈 리스트 반환
        return []
    except (json.JSONDecodeError, OSError):
        # 읽기 오류 시 빈 리스트로 안전하게 복구
        return []


def save_scores(scores: list[dict[str, Any]]) -> None:
    """
    점수 목록을 scores.json 파일에 저장
    - 디렉토리가 없으면 자동 생성
    - 파일 락으로 동시 쓰기 보호
    - 원자적 쓰기를 위해 임시 파일 사용 후 이동
    """
    # 디렉토리가 없으면 생성
    directory = os.path.dirname(SCORES_FILE)
    if directory:
        os.makedirs(directory, exist_ok=True)

    # 원자적 쓰기: 임시 파일에 먼저 쓰기
    import tempfile
    import json

    fd, temp_path = tempfile.mkstemp(
        prefix="tanmak_scores_",
        suffix=".json.tmp",
        dir=directory if directory else None
    )

    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(scores, f, ensure_ascii=False, separators=(",", ":"))

        # 성공하면 원본 위치로 이동 (Windows/os.posix_rename 호환)
        if os.path.exists(SCORES_FILE):
            os.replace(temp_path, SCORES_FILE)
        else:
            os.rename(temp_path, SCORES_FILE)
    except Exception:
        # 실패 시 임시 파일 정리
        try:
            os.unlink(temp_path)
        except OSError:
            pass
        raise


# ============================================================
# 속도 제한 헬퍼
# ============================================================


def get_client_ip(request: Request) -> str:
    """
    클라이언트 IP 추출
    - X-Forwarded-For 헤더 우선 (프록시 경로 고려)
    - 없으면 request.client.host 사용
    """
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        # 콤마로 구분된 경우 첫 번째 IP 사용
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


def check_rate_limit(request: Request) -> None:
    """
    속도 제한 확인 (IP당 3초 쿨다운)
    - 위반 시 HTTPException(429) 발생
    """
    client_ip = get_client_ip(request)
    current_time = time.time()

    last_request_time = rate_limit_tracker[client_ip]
    if current_time - last_request_time < RATE_LIMIT_COOLDOWN:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={"error": "rate_limited"}
        )

    # 속도 제한 통과: 현재 시간 기록
    rate_limit_tracker[client_ip] = current_time

    # 오래된 기록 정리 (1시간 이상된 것)
    cutoff_time = current_time - 3600
    stale_ips = [
        ip for ip, last_time in rate_limit_tracker.items()
        if last_time < cutoff_time
    ]
    for ip in stale_ips:
        del rate_limit_tracker[ip]


# ============================================================
# 순위표 비즈니스 로직
# ============================================================


def get_leaderboard() -> list[dict[str, Any]]:
    """
    현재 상위 10개 점수 목록 반환 (점수 내림차순)
    """
    with file_lock:
        scores = load_scores()
        # 점수 내림차순 정렬
        sorted_scores = sorted(scores, key=lambda x: x.get("score", 0), reverse=True)
        return sorted_scores[:10]


def insert_score(name: str, score: int) -> tuple[int, list[dict[str, Any]]]:
    """
    새 점수를 순위표에 삽입하고 순위를 계산
    - 정렬 삽입 (점수 내림차순)
    - 상위 10개만 유지
    - 반환: (순위, 상위 10개 목록)
    """
    new_entry = {"name": name, "score": score}

    with file_lock:
        scores = load_scores()

        # 새 점수 추가 후 내림차순 정렬
        scores.append(new_entry)
        scores.sort(key=lambda x: x["score"], reverse=True)

        # 상위 10개만 유지
        top_10 = scores[:10]

        # 방금 제출한 점수의 순위 찾기 (1-based)
        # 동점일 경우 먼저 등록된 쪽이 높은 순위
        try:
            rank = next(
                i + 1
                for i, entry in enumerate(top_10)
                if entry["name"] == name and entry["score"] == score
            )
        except StopIteration:
            # 10위 밖으로 밀려난 경우
            rank = 0

        # 파일에 저장
        save_scores(top_10)

        return rank, top_10


# ============================================================
# API 엔드포인트
# ============================================================


@app.get(
    "/api/scores",
    response_model=ScoreListResponse,
    responses={
        200: {"description": "성공 - 상위 10개 점수 목록"}
    }
)
async def get_scores() -> ScoreListResponse:
    """
    상위 10개 점수 목록 반환 (점수 내림차순)
    """
    leaderboard = get_leaderboard()
    # ScoreEntry 모델로 변환
    score_entries = [ScoreEntry(**entry) for entry in leaderboard]
    return ScoreListResponse(scores=score_entries)


@app.post(
    "/api/scores",
    response_model=ScoreSubmitResponse,
    responses={
        200: {"description": "성공 - 점수 제출 완료"},
        422: {"model": ErrorResponse, "description": "검증 실패"},
        429: {"model": ErrorResponse, "description": "속도 제한 초과"}
    }
)
async def submit_score(
    request: Request,
    entry: ScoreEntry
) -> ScoreSubmitResponse:
    """
    새 점수 제출
    - 이름: 정확히 3자, 한글/영문/숫자만
    - 점수: 0 이상
    - 속도 제한: IP당 3초 쿨다운
    - 응답: 제출한 점수의 순위 + 현재 상위 10개
    """
    # 속도 제한 확인
    check_rate_limit(request)

    # Pydantic 모델에서 이미 검증됨
    name = entry.name
    score = entry.score

    # 점수 삽입 및 순위 계산
    rank, top_10 = insert_score(name, score)

    # ScoreEntry 모델로 변환
    score_entries = [ScoreEntry(**entry) for entry in top_10]

    return ScoreSubmitResponse(rank=rank, scores=score_entries)


@app.get("/health")
async def health_check() -> dict[str, str]:
    """헬스 체크 엔드포인트"""
    return {"status": "ok"}


# ============================================================
# 메인 실행부 (uvicorn)
# ============================================================

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="127.0.0.1",
        port=2715,
        log_level="info",
        access_log=True
    )
