#!/usr/bin/env bash
# ============================================================
# TANMAK 웹 배포 스크립트
# ------------------------------------------------------------
# 로컬에서 Godot 웹(nothreads) 빌드 → rsync over SSH 로 우분투 서버 업로드.
# SSH 정보는 프로젝트 루트 .env 에서 읽는다.
# 사용: bash deploy/deploy.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"

# --- .env 로드 ---
if [ -f "$ENV_FILE" ]; then
	set -a
	. "$ENV_FILE"
	set +a
else
	echo "❌ .env 파일이 없습니다. 'cp .env.example .env' 후 값을 채우세요." >&2
	exit 1
fi

# --- 필수값 기본값/검증 ---
: "${DEPLOY_HOST:?DEPLOY_HOST 가 .env에 필요합니다}"
: "${DEPLOY_USER:?DEPLOY_USER 가 .env에 필요합니다}"
: "${DEPLOY_PORT:=22}"
: "${WEB_ROOT:=/var/www/tanmak}"
: "${WEB_PORT:=2713}"
: "${GODOT_EXPORT_PRESET:=Web}"
: "${GODOT_EXPORT_OUTPUT:=web/index.html}"
: "${DEPLOY_DOMAIN:=}"

# --- Godot 실행 파일 탐지 ---
GODOT="${GODOT_BIN:-}"
if [ -z "$GODOT" ]; then
	if command -v godot >/dev/null 2>&1; then
		GODOT="godot"
	else
		echo "❌ godot 실행 파일을 찾을 수 없습니다. .env 의 GODOT_BIN 을 전체 경로로 설정하세요." >&2
		exit 1
	fi
fi

# --- 웹 내보내기 template 확인 (nothreads = 호환성) ---
TPL_DIR="${APPDATA:-$HOME/AppData/Roaming}/Godot/export_templates/4.7.stable"
if [ ! -f "$TPL_DIR/web_nothreads_release.zip" ]; then
	cat >&2 <<EOF
❌ 웹 내보내기 template 이 없습니다:
   $TPL_DIR/web_nothreads_release.zip

설치 방법 (1회):
   1) Godot 에디터 실행 → 이 프로젝트 열기
   2) 메뉴 [Editor] → [Manage Export Templates...]
   3) [Web] 항목의 nothreads template 다운로드
이후 이 스크립트를 다시 실행하세요.
EOF
	exit 1
fi

# --- SSH 공통 옵션 조립 ---
SSH_BASE="ssh -p ${DEPLOY_PORT} -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15"
if [ -n "${DEPLOY_SSH_KEY:-}" ] && [ "${DEPLOY_SSH_KEY}" != "~/.ssh/id_ed25519" ]; then
	SSH_BASE="$SSH_BASE -i ${DEPLOY_SSH_KEY}"
fi

echo "==> 1/3 Godot 웹 빌드 (preset: ${GODOT_EXPORT_PRESET})"
mkdir -p "${PROJECT_DIR}/web"
"${GODOT}" --headless --export-release "${GODOT_EXPORT_PRESET}" "${GODOT_EXPORT_OUTPUT}" --path "${PROJECT_DIR}"

# 회색 여백 제거 + 모바일(카톡 인앱 브라우저 포함) 네이티브 키보드용 HTML 입력창 주입
INDEX_HTML="${PROJECT_DIR}/web/index.html"
if [ -f "$INDEX_HTML" ]; then
	# 1) body 배경을 게임색(#0b0e16)으로 통일 (회색 여백 제거)
	sed -i 's|</head>|<style>html,body{background:#0b0e16;margin:0;padding:0;overflow:hidden;}#canvas{display:block;}</style></head>|' "$INDEX_HTML"
	# 2) HTML 이름 입력창 + JS — Godot LineEdit 가상키보드 미지원 환경(카톡 WebView 등) 대응
	python3 - "$INDEX_HTML" <<'PYEOF'
import sys
p = sys.argv[1]
h = open(p, encoding='utf-8').read()
if 'tanmak-name' not in h:
    inj = (
        '<input id="tanmak-name" type="text" maxlength="3" autocomplete="off" '
        'autocapitalize="off" spellcheck="false" inputmode="text" '
        'style="position:fixed;left:50%;top:76%;transform:translateX(-50%);width:240px;'
        'height:56px;font-size:30px;text-align:center;background:#1a2030;color:#fff;'
        'border:2px solid #58a6ff;border-radius:10px;display:none;z-index:50;" '
        "onkeydown=\"if(event.key==='Enter'){window._tanmakNameSubmitted=this.value;}\">"
        '<script>'
        'window._tanmakNameSubmitted="";'
        "function showTanmakNameInput(){var i=document.getElementById('tanmak-name');"
        "i.style.display='block';i.value='';i.focus();i.click();"
        "setTimeout(function(){i.focus();i.click();},100);}"
        "function hideTanmakNameInput(){document.getElementById('tanmak-name').style.display='none';}"
        '</script>'
    )
    h = h.replace('</body>', inj + '</body>', 1)
    open(p, 'w', encoding='utf-8').write(h)
    print('   모바일 이름 입력창(HTML 네이티브 키보드) 주입')
PYEOF
fi

echo "==> 2/3 서버 업로드 (rsync over SSH, 포트 ${DEPLOY_PORT} → ${WEB_ROOT})"
if command -v rsync >/dev/null 2>&1; then
	rsync -avz --delete -e "${SSH_BASE}" "${PROJECT_DIR}/web/" "${DEPLOY_USER}@${DEPLOY_HOST}:${WEB_ROOT}/"
else
	# rsync 미지원 환경 fallback: scp (전체 덮어쓰기)
	echo "   (rsync 미설치 — scp 로 업로드)"
	${SSH_BASE} "${DEPLOY_USER}@${DEPLOY_HOST}" "mkdir -p ${WEB_ROOT}"
	scp -P "${DEPLOY_PORT}" ${DEPLOY_SSH_KEY:+-i "${DEPLOY_SSH_KEY}"} "${PROJECT_DIR}"/web/* "${DEPLOY_USER}@${DEPLOY_HOST}:${WEB_ROOT}/"
fi

echo "==> 3/3 헬스체크"
HEALTH_URL="${DEPLOY_DOMAIN:+https://${DEPLOY_DOMAIN}/}"
if [ -z "${HEALTH_URL}" ]; then
	HEALTH_URL="http://${DEPLOY_HOST}:${WEB_PORT}/"
fi
echo "   대상: ${HEALTH_URL}"
sleep 1
if curl -sS -o /dev/null -w "   HTTP %{http_code}\n" --max-time 10 "${HEALTH_URL}"; then
	:
else
	echo "   ⚠ 헬스체크 실패 — NPM 역프록시 / 포트 2713 / nginx 상태 확인"
fi

echo ""
echo "✅ 배포 완료 — NPM 에서 연결한 도메인(HTTPS)으로 접속해 확인하세요."
