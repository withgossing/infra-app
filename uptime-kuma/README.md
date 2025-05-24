# Uptime Kuma 가용성 모니터링

Meritz 인프라의 서비스 가용성 및 업타임 모니터링 시스템입니다.

## 🎯 주요 기능

- **웹사이트 모니터링**: HTTP/HTTPS 상태 체크
- **포트 모니터링**: TCP/UDP 포트 상태 확인
- **알림 시스템**: 다양한 채널로 장애 알림
- **상태 페이지**: 공개 상태 페이지 제공

## 🚀 사용 방법

### 서비스 시작
```bash
docker-compose up -d
```

### 초기 설정
1. http://localhost:1009 접속
2. 관리자 계정 생성
3. 모니터링 대상 추가

## 🌐 접속 정보

- **로컬**: http://localhost:1009
- **도메인**: https://uptime.meritz.com
- **계정**: 초기 설정 시 생성

## 📊 권장 모니터링 대상

### 내부 서비스
- http://localhost:1000 (Traefik)
- http://localhost:1002 (Prometheus)
- http://localhost:1003 (Grafana)
- http://localhost:1004 (Loki)

### 외부 서비스
- https://meritz.com
- https://www.meritz.com
- https://api.meritz.com

## 🔔 알림 설정

### 지원 알림 채널
- 이메일
- Slack
- Discord
- Telegram
- Webhook

### 알림 조건
- 서비스 다운
- 응답 시간 초과
- SSL 인증서 만료 임박

## 💾 데이터 관리

### 백업
```bash
# 데이터 백업
cp -r data/ backup/uptime-kuma-$(date +%Y%m%d)/
```

## 📚 참고 자료

- [Uptime Kuma GitHub](https://github.com/louislam/uptime-kuma)
