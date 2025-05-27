# Registry 서비스 (Harbor)

## 📋 개요
Harbor를 기반으로 한 엔터프라이즈급 컨테이너 레지스트리
- 보안 스캐닝 기능
- RBAC 권한 관리
- 이미지 서명 및 검증
- 복제 및 백업 기능
- 웹 UI 제공

## 🚀 주요 기능
- **이미지 저장**: Docker/OCI 이미지 저장 및 관리
- **보안 스캐닝**: CVE 취약점 스캐닝
- **이미지 서명**: Notary를 통한 이미지 서명
- **RBAC**: 사용자 및 프로젝트 권한 관리
- **복제**: 다중 레지스트리 복제
- **웹 UI**: 직관적인 웹 인터페이스

## 🌐 네트워크 설정
- **외부 포트**: 10800 (Harbor UI/API)
- **내부 포트**: 80, 443
- **데이터베이스 포트**: 10801 (PostgreSQL)
- **Redis 포트**: 10802 (Redis)
- **Notary 포트**: 10803 (Notary Server)

## 📁 구성 파일
- `config/harbor.yml`: Harbor 설정
- `config/nginx.conf`: Nginx 프록시 설정
- `docker-compose.yml`: 로컬 개발환경
- `k8s/`: Kubernetes 배포 설정

## 🔧 사용법

### 로컬 환경 실행
```bash
cd /Users/gossing/WorkPlace/infra-app/registry
docker-compose up -d
```

### 이미지 푸시/풀
```bash
# 로그인
docker login localhost:10800

# 이미지 태그
docker tag my-app:latest localhost:10800/library/my-app:latest

# 이미지 푸시
docker push localhost:10800/library/my-app:latest

# 이미지 풀
docker pull localhost:10800/library/my-app:latest
```

## 🔐 기본 계정
- **관리자**: admin / Harbor12345
- **웹 UI**: http://localhost:10800

## 📊 모니터링
- Harbor UI: http://localhost:10800
- 헬스체크: http://localhost:10800/api/v2.0/health
