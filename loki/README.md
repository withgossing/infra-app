# Loki 로그 수집 서비스

Meritz 인프라의 중앙 로그 수집 및 분석 시스템입니다.

## 🎯 주요 기능

- **로그 수집**: 모든 서비스와 컨테이너 로그 중앙 집중
- **효율적 저장**: 압축 및 인덱싱으로 저장 공간 최적화
- **LogQL**: Prometheus와 유사한 쿼리 언어
- **Grafana 연동**: 로그와 메트릭 통합 시각화

## 🚀 사용 방법

### 서비스 시작
```bash
docker-compose up -d
```

### 서비스 중지
```bash
docker-compose down
```

### 로그 확인
```bash
docker-compose logs -f
```

## 🌐 접속 정보

- **로컬**: http://localhost:1004
- **도메인**: https://loki.meritz.com
- **계정**: admin/admin123 (기본 인증)

## 📊 로그 수집 대상

### 현재 수집 중인 로그
1. **시스템 로그** - `/var/log/` 디렉토리
2. **Docker 컨테이너 로그** - 모든 Meritz 컨테이너
3. **Traefik 로그** - 액세스 로그 및 애플리케이션 로그
4. **커스텀 애플리케이션 로그** - JSON 형식 로그

### 로그 라벨링
- `job`: 로그 소스 (traefik-access, containers 등)
- `level`: 로그 레벨 (info, error, debug)
- `container_name`: 컨테이너 이름
- `method`: HTTP 메서드 (GET, POST 등)
- `status`: HTTP 상태 코드

## 🔍 LogQL 쿼리 예시

### 기본 쿼리
```logql
# 모든 로그
{}

# 특정 job의 로그
{job="traefik-access"}

# 에러 로그만
{level="error"}

# 특정 컨테이너 로그
{container_name="meritz-grafana"}
```

### 필터링
```logql
# 특정 문자열 포함
{job="traefik-access"} |= "error"

# 정규식 필터
{job="traefik-access"} |~ "GET|POST"

# JSON 파싱
{job="applications"} | json | status="500"
```

### 메트릭 쿼리
```logql
# 에러 로그 발생률
rate({level="error"}[5m])

# HTTP 상태 코드별 요청 수
sum by (status) (rate({job="traefik-access"}[5m]))
```

## ⚙️ 설정 파일

### 주요 설정
- `config/local-config.yaml` - Loki 메인 설정
- **데이터 보존**: 30일 (720시간)
- **압축**: Gzip 압축 적용
- **인덱싱**: 24시간 주기

### 환경 변수
```bash
TZ=Asia/Seoul
```

## 💾 데이터 관리

### 스토리지
- **위치**: Docker 볼륨 `loki_data`
- **보존 기간**: 30일
- **압축**: 자동 압축 적용

### 백업
```bash
# 데이터 백업
docker run --rm -v loki_loki_data:/source -v $(pwd):/backup \
    alpine tar -czf /backup/loki-backup.tar.gz -C /source .

# 데이터 복구
docker run --rm -v loki_loki_data:/target -v $(pwd):/backup \
    alpine tar -xzf /backup/loki-backup.tar.gz -C /target
```

## 🔧 트러블슈팅

### 일반적인 문제

1. **로그가 수집되지 않음**
   ```bash
   # Promtail 상태 확인
   curl http://meritz-promtail:9080/metrics
   
   # Loki 상태 확인
   curl http://localhost:1004/ready
   ```

2. **쿼리 성능 저하**
   - 시간 범위를 줄여서 쿼리
   - 라벨 필터를 먼저 적용
   - 정규식 사용 최소화

3. **디스크 공간 부족**
   ```bash
   # 보존 기간 단축 (config/local-config.yaml)
   retention_period: 168h  # 7일로 단축
   ```

## 📈 성능 최적화

### 쿼리 최적화
- 시간 범위 제한
- 라벨 선택자 우선 사용
- 정규식 최소화
- 파이프라인 단계 순서 최적화

### 리소스 설정
```yaml
# docker-compose.yml에서 리소스 제한
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '0.5'
```

## 🔗 관련 서비스

- **Promtail**: 로그 수집 에이전트
- **Grafana**: 로그 시각화
- **Jaeger**: 트레이싱과 로그 연동

## 📚 참고 자료

- [Loki 공식 문서](https://grafana.com/docs/loki/)
- [LogQL 가이드](https://grafana.com/docs/loki/latest/logql/)
- [Promtail 설정](https://grafana.com/docs/loki/latest/clients/promtail/)
