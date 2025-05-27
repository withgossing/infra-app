# Security 서비스 (Keycloak + Vault)

## 📋 개요
Keycloak과 HashiCorp Vault를 기반으로 한 통합 보안 서비스
- OAuth2/OIDC 인증 서비스 (Keycloak)
- 시크릿 관리 서비스 (Vault)
- SSO (Single Sign-On) 지원
- 다중 인증 방식 지원
- 정책 기반 액세스 제어

## 🚀 주요 기능

### Keycloak (인증/인가)
- **OAuth2/OIDC**: 표준 프로토콜 지원
- **SSO**: 단일 로그인 환경
- **사용자 관리**: 사용자 및 그룹 관리
- **클라이언트 관리**: 애플리케이션 클라이언트 등록
- **소셜 로그인**: Google, GitHub 등 소셜 로그인
- **MFA**: 다중 인증 지원

### HashiCorp Vault (시크릿 관리)
- **시크릿 저장**: 안전한 키-값 저장소
- **동적 시크릿**: 데이터베이스 크리덴셜 동적 생성
- **암호화**: 데이터 암호화 서비스
- **PKI**: 인증서 관리
- **감사 로그**: 접근 기록 및 감사

## 🌐 네트워크 설정
- **Keycloak**: 10900 (외부), 8080 (내부)
- **Keycloak DB**: 10901 (PostgreSQL)
- **Vault**: 10902 (외부), 8200 (내부)
- **Vault UI**: 10903 (Vault UI)

## 📁 구성 파일
- `config/keycloak/`: Keycloak 설정
- `config/vault/`: Vault 설정
- `config/policies/`: 보안 정책
- `docker-compose.yml`: 로컬 개발환경
- `k8s/`: Kubernetes 배포 설정

## 🔧 사용법

### 로컬 환경 실행
```bash
cd /Users/gossing/WorkPlace/infra-app/security
docker-compose up -d
```

### Keycloak 설정
1. 웹 UI 접속: http://localhost:10900
2. 관리자 로그인: admin / admin123
3. Realm 생성 및 클라이언트 등록

### Vault 설정
1. 웹 UI 접속: http://localhost:10902
2. Vault 초기화 및 언실링
3. 시크릿 엔진 활성화

## 🔐 기본 계정
- **Keycloak 관리자**: admin / admin123
- **Vault**: 초기화 후 루트 토큰 사용

## 📊 모니터링
- Keycloak: http://localhost:10900/auth/admin/
- Vault: http://localhost:10902/ui/
- 헬스체크: http://localhost:10900/auth/health, http://localhost:10902/v1/sys/health

## 🔗 통합 가이드

### 애플리케이션 통합
```bash
# Keycloak 클라이언트 생성
# Vault 시크릿 조회
# JWT 토큰 검증
```

### API 인증 플로우
1. 클라이언트가 Keycloak에서 토큰 획득
2. API 호출 시 Bearer 토큰 포함
3. API 서버에서 토큰 검증
4. Vault에서 필요한 시크릿 조회
