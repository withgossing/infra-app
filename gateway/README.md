# Meritz Gateway Infrastructure

`*.meritz.com` 도메인을 위한 고성능 게이트웨이 및 모니터링 시스템입니다.

## 🏗️ 아키텍처

```
Internet → Traefik Gateway → Backend Services
              ↓
         Monitoring Stack
    (Prometheus, Grafana, Loki, Jaeger)
```

## 🚀 주요 기능

### Gateway (Traefik)
- **도메인 라우팅**: `*.meritz.com` 모든 서브도메인 지원
- **자동 SSL/TLS**: Let's Encrypt 인증서 자동 발급/갱신
- **로드 밸런싱**: 다중 백엔드 서비스 지원
- **미들웨어**: 보안 헤더, CORS, 인증, 레이트 리미팅
- **헬스체크**: 자동 서비스 상태 모니터링

### 모니터링 스택
- **Prometheus**: 메트릭 수집 및 저장
- **Grafana**: 시각화 대시보드 (10.2.0)
- **Loki**: 로그 수집 및 분석
- **Jaeger**: 분산 트레이싱
- **Uptime Kuma**: 서비스 가용성 모니터링
- **Node Exporter**: 시스템 메트릭
- **cAdvisor**: 컨테이너 메트릭

## 📋 사전 요구사항

- Docker Engine 20.10+
- Docker Compose 2.0+
- 최소 4GB RAM
- 20GB 디스크 여유 공간
- 포트 80, 443, 1000-1009 사용 가능

## ⚡ 빠른 시작

### 1. 권한 설정
```bash
chmod +x scripts/*.sh
```

### 2. 환경 설정
```bash
# .env 파일 편집
cp .env.example .env
vim .env
```

### 3. 시작
```bash
./scripts/start.sh
```

### 4. 접속 확인
- Traefik 대시보드: http://localhost:1000
- Grafana: http://localhost:1003 (admin/admin123)
- Prometheus: http://localhost:1002

## 🌐 도메인 설정

### DNS 설정 예시
```
# A 레코드
meritz.com.           IN  A     YOUR_SERVER_IP
*.meritz.com.         IN  A     YOUR_SERVER_IP

# CNAME 레코드 (선택적)
www.meritz.com.       IN  CNAME meritz.com.
api.meritz.com.       IN  CNAME meritz.com.
admin.meritz.com.     IN  CNAME meritz.com.
```

### 지원되는 서브도메인
- `www.meritz.com` - 메인 웹사이트
- `api.meritz.com` - API 서비스
- `admin.meritz.com` - 관리자 대시보드
- `monitoring.meritz.com` - 모니터링 대시보드
- `dev.meritz.com` - 개발 환경
- 기타 모든 서브도메인 (와일드카드 지원)

## 🔧 관리 명령어

```bash
# 서비스 시작
./scripts/start.sh

# 서비스 중지
./scripts/stop.sh

# 헬스체크
./scripts/health-check.sh

# 백업
./scripts/backup.sh

# 복구
./scripts/restore.sh backup_file.tar.gz

# 완전 정리
./scripts/cleanup.sh
```

## 📊 모니터링 접속 정보

| 서비스 | 로컬 접속 | 도메인 접속 | 계정 |
|--------|-----------|-------------|------|
| Traefik | http://localhost:1000 | https://traefik.meritz.com | admin/admin123 |
| Prometheus | http://localhost:1002 | https://prometheus.meritz.com | admin/admin123 |
| Grafana | http://localhost:1003 | https://grafana.meritz.com | admin/admin123 |
| Loki | http://localhost:1004 | https://loki.meritz.com | admin/admin123 |
| Jaeger | http://localhost:1005 | https://jaeger.meritz.com | admin/admin123 |
| Uptime Kuma | http://localhost:1009 | https://uptime.meritz.com | 초기 설정 필요 |

## 🔒 보안 설정

### 기본 보안 기능
- **HTTPS 강제**: 모든 HTTP 요청을 HTTPS로 리다이렉트
- **보안 헤더**: HSTS, XSS Protection, Content-Type Options
- **레이트 리미팅**: 분당 100회 요청 제한
- **기본 인증**: 관리 도구 접근 제한

### 인증 정보 변경
```bash
# 새 비밀번호 해시 생성
echo $(htpasswd -nb admin new_password)

# traefik/config/dynamic/routes.yml 파일에서 업데이트
```

## 🏗️ 새로운 서비스 추가

### 1. Docker Compose에 서비스 추가
```yaml
your-service:
  image: your-image
  networks:
    - meritz-network
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.your-service.rule=Host(`your-service.meritz.com`)"
    - "traefik.http.routers.your-service.tls.certresolver=letsencrypt"
```

### 2. 동적 라우팅 설정
`traefik/config/dynamic/routes.yml`에 라우터 및 서비스 추가

### 3. 모니터링 설정
Prometheus 설정에 새 타겟 추가

## 📈 성능 최적화

### 시스템 요구사항 (권장)
- **CPU**: 4 코어 이상
- **메모리**: 8GB 이상
- **디스크**: SSD, 50GB 이상
- **네트워크**: 1Gbps 이상

### 설정 최적화
```bash
# Docker 로그 크기 제한
echo '{"log-driver":"json-file","log-opts":{"max-size":"100m","max-file":"3"}}' > /etc/docker/daemon.json

# 시스템 한계 증가
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
```

## 🔍 트러블슈팅

### 일반적인 문제

#### 1. 컨테이너가 시작되지 않음
```bash
# 로그 확인
docker-compose logs [service-name]

# 포트 충돌 확인
netstat -tulpn | grep :80
```

#### 2. SSL 인증서 발급 실패
```bash
# ACME 설정 확인
cat traefik/ssl/acme.json

# 스테이징 환경에서 테스트
# traefik.yml에서 caServer 주석 해제
```

#### 3. 메모리 부족
```bash
# 리소스 사용량 확인
docker stats

# 불필요한 컨테이너 정리
docker system prune -a
```

### 로그 위치
- **Traefik**: `./traefik/logs/`
- **Container**: `docker-compose logs`
- **System**: `/var/log/syslog`

## 🔄 업데이트

### 서비스 업데이트
```bash
# 이미지 업데이트
docker-compose pull

# 재시작 (무중단)
docker-compose up -d
```

### 설정 업데이트
1. 설정 파일 수정
2. `docker-compose restart traefik`

## 💾 백업 및 복구

### 자동 백업 설정
```bash
# crontab에 추가
0 2 * * * /path/to/gateway/scripts/backup.sh
```

### 백업 항목
- 모든 설정 파일
- Prometheus 메트릭 데이터
- Grafana 대시보드
- Loki 로그 데이터
- SSL 인증서
- Uptime Kuma 설정

## 📞 지원 및 문의

### 로그 확인 방법
```bash
# 실시간 로그 모니터링
docker-compose logs -f

# 특정 서비스 로그
docker-compose logs traefik

# 에러 로그만 확인
docker-compose logs | grep ERROR
```

### 성능 모니터링
- Grafana 대시보드에서 실시간 메트릭 확인
- Prometheus 쿼리로 상세 분석
- Jaeger로 요청 추적

## 📝 라이선스

이 프로젝트는 MIT 라이선스하에 제공됩니다.

## 🔗 참고 자료

- [Traefik 공식 문서](https://doc.traefik.io/traefik/)
- [Prometheus 문서](https://prometheus.io/docs/)
- [Grafana 문서](https://grafana.com/docs/)
- [Docker Compose 문서](https://docs.docker.com/compose/)

---

**🚀 Happy Monitoring with Meritz Gateway!**
