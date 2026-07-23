# 배포 가이드 — 우분투 + Nginx Proxy Manager

Godot 웹(nothreads) 빌드를 **우분투 서버의 nginx(포트 2713)** 로 서빙하고, **Nginx Proxy Manager(NPM, openresty)** 가 앞단에서 도메인/HTTPS 를 처리하는 구조.

```
[사용자 브라우저] --HTTPS--> [NPM(openresty):443 tanmak.ralphpark.com] --HTTP--> [nginx:2713 /home/ralph/work/web/tanmak]
```

## 현재 구축 상태 (검증 완료)

| 항목 | 상태 |
|---|---|
| 서버 | `ralph@ralphpark.com:2202` (Ubuntu 24.04, `pjserver`) |
| SSH 인증 | 키 인증(passwordless sudo OK) |
| nginx | 1.24.0 설치, 기본 사이트(80) 제거, **2713 리스닝 활성** |
| 웹 루트 | `/home/ralph/work/web/tanmak` (ralph 소유) |
| 역프록시 | NPM: `tanmak.ralphpark.com` → `서버:2713` (HTTPS, `X-Served-By` 확인) |
| 헬스체크 | `https://tanmak.ralphpark.com/` → **200 + COOP/COEP 헤더 정상** |

> 포트 2713 은 서버에 방화벽 규칙 없이도 NPM(같은 서버)에서 접근 가능하다. 외부 직접 접근도 열려 있음(`http://ralphpark.com:2713/` 200 확인).

---

## 서버 측 설정 (이미 완료됨 — 참고용)

```bash
# nginx 설치 + 기본 사이트(80, NPM 충돌) 제거 + 2713 사이트 활성화
sudo apt-get install -y nginx
sudo cp deploy/nginx_tanmak.conf /etc/nginx/sites-available/tanmak
sudo ln -sf /etc/nginx/sites-available/tanmak /etc/nginx/sites-enabled/tanmak
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

> nginx 는 정적 파일을 실시간으로 읽으므로 파일 교체 후 reload 불필요.

---

## 로컬 → 배포 절차

### 1. Godot 웹 template 설치 (1회, 1.28GB)

1. Godot 에디터 → 이 프로젝트 열기
2. **[Editor] → [Manage Export Templates...]** → **Web** 의 **nothreads** template 다운로드
   - 경로(Windows): `%APPDATA%\Godot\export_templates\4.7.stable\web_nothreads_release.zip`
3. `deploy/deploy.sh` 가 자동으로 존재 여부를 검사한다.

### 2. `.env` 확인

핵심 변수 (실제 값은 `.env` 에 설정됨):
```
DEPLOY_HOST=ralphpark.com
DEPLOY_PORT=2202
DEPLOY_USER=ralph
DEPLOY_DOMAIN=tanmak.ralphpark.com   # 헬스체크 대상 (NPM 도메인)
WEB_PORT=2713
WEB_ROOT=/home/ralph/work/web/tanmak
GODOT_BIN=godot
```

### 3. 배포 실행

```bash
bash deploy/deploy.sh
```

스크립트 동작:
1. 로컬 `godot --headless --export-release "Web"` 빌드 → `web/`
2. rsync(미설치 시 scp) 로 서버 `/home/ralph/work/web/tanmak/` 업로드 — 기존 임시 `index.html` 을 Godot 빌드로 덮어씀
3. `https://tanmak.ralphpark.com/` 헬스체크

---

## 문제 해결

| 증상 | 원인 / 해결 |
|---|---|
| `web_nothreads_release.zip 없음` | 1단계 template 미설치. 에디터에서 Web nothreads 다운로드 |
| 브라우저 하얀 화면 | COOP/COEP 또는 MIME. `curl -I https://tanmak.ralphpark.com/` 로 `application/wasm`·COOP 확인 |
| `SharedArrayBuffer is not defined` | threads template 으로 빌드됨 → nothreads template 사용 |
| NPM 도메인 502 Bad Gateway | nginx 미실행 또는 2713 미리스닝. 서버에서 `sudo systemctl status nginx`, `sudo ss -lntp \| 2713` |
| rsync 명령 없음 | 로컬 미설치 → 스크립트가 자동 scp fallback |

## 수동 빌드/업로드 (스크립트 없이)

```bash
godot --headless --export-release "Web" web/index.html
scp -P 2202 web/* ralph@ralphpark.com:/home/ralph/work/web/tanmak/
```
