# Jaeger 분산 트레이싱 서비스

Meritz 인프라의 분산 트레이싱 및 마이크로서비스 모니터링 시스템입니다.

## 🎯 주요 기능

- **분산 트레이싱**: 마이크로서비스 간 요청 추적
- **성능 분석**: 병목 지점 및 지연 시간 분석
- **서비스 맵**: 서비스 간 의존성 시각화
- **에러 추적**: 요청 체인에서 에러 발생 지점 식별

## 🚀 사용 방법

### 서비스 시작
```bash
docker-compose up -d
```

### 서비스 중지
```bash
docker-compose down
```

## 🌐 접속 정보

- **로컬**: http://localhost:1005
- **도메인**: https://jaeger.meritz.com
- **계정**: admin/admin123 (기본 인증)

## 📊 주요 기능

### 1. 트레이스 검색
- 서비스별 트레이스 조회
- 시간 범위별 필터링
- 태그 기반 검색

### 2. 서비스 성능 분석
- 응답 시간 분포
- 에러율 분석
- 처리량 모니터링

### 3. 의존성 그래프
- 서비스 간 호출 관계
- 처리량 및 에러율 시각화

## 🔧 트레이싱 설정

### 애플리케이션 연동
```javascript
// Node.js 예시
const jaeger = require('jaeger-client');

const config = {
  serviceName: 'my-service',
  sampler: {
    type: 'const',
    param: 1
  },
  reporter: {
    collectorEndpoint: 'http://meritz-jaeger:14268/api/traces'
  }
};

const tracer = jaeger.initTracer(config);
```

### Traefik 연동
Traefik과 자동 연동되어 HTTP 요청 트레이싱이 가능합니다.

## 💾 데이터 관리

### 스토리지
- **저장 방식**: 메모리 (개발용)
- **보존 기간**: 컨테이너 재시작 시 삭제
- **프로덕션**: 영구 저장소 설정 권장

## 🔗 관련 서비스

- **Grafana**: 트레이싱 데이터 시각화
- **Loki**: 로그와 트레이스 연동
- **Prometheus**: 메트릭과 트레이스 연동

## 📚 참고 자료

- [Jaeger 공식 문서](https://www.jaegertracing.io/docs/)
- [OpenTracing 표준](https://opentracing.io/)
