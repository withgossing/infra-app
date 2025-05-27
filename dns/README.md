# DNS 서비스 (CoreDNS)

## 📋 개요
CoreDNS를 기반으로 한 내부 DNS 서비스 제공
- 내부 서비스 디스커버리 지원
- DNS 캐싱 및 포워딩
- 커스텀 도메인 관리
- Kubernetes DNS와 호환

## 🚀 주요 기능
- **내부 DNS 해석**: 서비스 간 도메인 이름 해석
- **DNS 캐싱**: 성능 향상을 위한 DNS 캐시
- **커스텀 도메인**: 내부 도메인 관리
- **DNS 포워딩**: 외부 DNS 서버로 포워딩
- **헬스체크**: DNS 서비스 상태 모니터링

## 🌐 네트워크 설정
- **외부 포트**: 10600 (DNS)
- **내부 포트**: 53
- **관리 포트**: 10601 (메트릭/헬스체크)

## 📁 구성 파일
- `config/Corefile`: CoreDNS 설정
- `config/custom-domains.db`: 커스텀 도메인 정의
- `docker-compose.yml`: 로컬 개발환경
- `k8s/`: Kubernetes 배포 설정

## 🔧 사용법

### 로컬 환경 실행
```bash
cd /Users/gossing/WorkPlace/infra-app/dns
docker-compose up -d
```

### DNS 테스트
```bash
# 내부 서비스 조회
nslookup redis-master.cache.local 127.0.0.1 -port=10600

# 외부 도메인 조회
nslookup google.com 127.0.0.1 -port=10600
```

## 📊 모니터링
- 메트릭: http://localhost:10601/metrics
- 헬스체크: http://localhost:10601/health
