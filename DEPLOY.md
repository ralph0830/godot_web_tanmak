# 배포 가이드 — 우분투 + Nginx Proxy Manager

이 프로젝트는 Godot 웹(nothreads) 빌드를 **우분투 서버의 nginx(포트 2713)** 로 서빙하고, **Nginx Proxy Manager(NPM)** 가 앞단에서 도메인/HTTPS 를 처리하는 구조를 전제로 한다.

```
[사용자 브라우저] --HTTPS--> [NPM:443 도메인] --HTTP--> [nginx:2713 /var/www/tanmak]
```

## 전제

- 우분투 서버, SSH 접속 가능 (이 프로젝트에선 `ralphpark.com:2202`, 사용자 `ralph`)
- Nginx Proxy Manager 가 이미 설치·운영 중
- 포트 **2713** 이 방화벽/보안그룹에서 열려 있음 (NPM 서버에서 접근 가능)
- 로컬에 Godot 4.7 + Web(nothreads) template 설치

---

## 1. Godot 웹 내보내기 template 설치 (로컬, 1회)

template 패키지가 크기 때문에 자동 다운로드 대신 에디터로 설치한다.

1. Godot 에디터 실행 → 이 프로젝트 열기
2. 메뉴 **[Editor] → [Manage Export Templates...]**
3. **[Web]** 항목의 **nothreads** template 다운로드
   - 설치 경로(Windows): `%APPDATA%\Godot\export_templates\4.7.stable\web_nothreads_release.zip`
4. `deploy/deploy.sh` 실행 시 자동으로 존재 여부를 검사한다.

## 2. 우분투 서버 nginx 설정 (서버, 1회)

```bash
# 서버 접속
ssh -p 2202 ralph@ralphpark.com

# nginx 설치(미설치 시)
sudo apt update && sudo apt install -y nginx

# 설정 복사(이 저장소의 deploy/nginx_tanmak.conf 를 서버로 전송 후)
sudo cp nginx_tanmak.conf /etc/nginx/sites-available/tanmak
sudo ln -s /etc/nginx/sites-available/tanmak /etc/nginx/sites-enabled/tanmak

# 웹 루트 생성 + 권한
sudo mkdir -p /var/www/tanmak
sudo chown -R ralph:ralph /var/www/tanmak

# 설정 검증 + 적용
sudo nginx -t && sudo systemctl reload nginx

# 로컬 확인
curl -I http://localhost:2713/   # 200/404 면 nginx 정상(파일은 아직 없어 404 가능)
```

> nginx 가 **brotli 모듈** 없이도 동작한다(`.br` 처리는 Content-Encoding 헤더만 추가). gzip_static 은 기본 지원.

## 3. NPM Proxy Host 등록 (NPM 관리 UI, 1회)

1. NPM Admin 패널 접속 → **Proxy Hosts → Add Proxy Host**
2. **Domain Names**: 사용할 도메인(예: `tanmak.ralphpark.com`)
3. **Forward Hostname / IP**: 우분투 서버 IP (또는 `127.0.0.1` if NPM이 같은 서버)
4. **Forward Port**: `2713`
5. **Block Common Exploits / Websockets Support**: ON 권장
6. **SSL** 탭: 인증서 발급(Let's Encrypt) + Force SSL
7. 저장 후 브라우저에서 도메인 접속 확인

> COOP/COEP 헤더는 백엔드(nginx)에서 추가하므로 NPM 측 별도 헤더 불필요.

## 4. 로컬 환경 변수 설정

```bash
cp .env.example .env
# .env 편집: DEPLOY_HOST / DEPLOY_PORT / DEPLOY_USER / (옵션)DEPLOY_SSH_KEY
```

SSH 키 인증을 권장한다. `.env` 의 `DEPLOY_SSH_KEY` 가 비어 있으면 기본 키/ssh-agent 를 사용한다.

## 5. 배포 실행

```bash
bash deploy/deploy.sh
```

스크립트 동작:
1. 로컬에서 `godot --headless --export-release "Web"` 빌드 → `web/`
2. rsync(또는 rsync 미설치 시 scp) 로 서버 `/var/www/tanmak/` 업로드
3. `http://<서버>:2713/` 헬스체크

nginx 는 정적 파일을 실시간으로 읽으므로 업로드 후 별도 reload 불필요.

---

## 문제 해결

| 증상 | 원인 / 해결 |
|---|---|
| `web_nothreads_release.zip 없음` | 1단계 template 미설치. 에디터에서 Web nothreads 다운로드 |
| 빌드는 되는데 브라우저가 하얀 화면 | COOP/COEP 헤더 누락 또는 MIME. `curl -I` 로 `application/wasm` / COOP 헤더 확인 |
| `SharedArrayBuffer is not defined` | threads template으로 빌드됨. export_presets 의 nothreads template 사용 확인 |
| NPM 도메인 502 Bad Gateway | nginx 미실행 또는 2713 미리스닝. 서버에서 `sudo systemctl status nginx` / `ss -lntp \| 2713` |
| 포트 접근 불가 | 방화벽/보안그룹에서 2713 오픈 확인 (NPM↔백엔드 통신) |
| rsync 명령 없음 | 로컬에 rsync 미설치 → 스크립트가 자동으로 scp fallback |
| SSH 인증 실패 | `.env` 의 `DEPLOY_SSH_KEY` 경로 확인 또는 ssh-agent 에 키 추가 |

## 수동 빌드/업로드 (스크립트 없이)

```bash
# 빌드
godot --headless --export-release "Web" web/index.html

# 업로드
scp -P 2202 -r web/* ralph@ralphpark.com:/var/www/tanmak/
```
