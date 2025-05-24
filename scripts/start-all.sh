#!/bin/bash

# Meritz 전체 인프라 시작 스크립트
# 모든 모니터링 서비스를 순차적으로 시작합니다

set -e

echo "🚀 Meritz 전체 인프라를 시작합니다..."
echo "📅 $(date)"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 진행 상황 표시
progress() {
    echo -e "${BLUE}[진행중]${NC} $1"
}

success() {
    echo -e "${GREEN}[완료]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[주의]${NC} $1"
}

error() {
    echo -e "${RED}[오류]${NC} $1"
}

# 스크립트 실행 위치 확인 및 작업 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# 작업 디렉토리를 infra-app로 이동
cd "$BASE_DIR"

# Docker 네트워크 생성
progress "Docker 네트워크 설정 중..."
docker network create meritz-network 2>/dev/null || echo "네트워크 'meritz-network'가 이미 존재합니다."
success "Docker 네트워크 설정 완료"

# 서비스 시작 순서 정의
SERVICES=(
    "gateway:Gateway (Traefik)"
    "prometheus:Prometheus"
    "loki:Loki"
    "grafana:Grafana"
    "node-exporter:Node Exporter"
    "cadvisor:cAdvisor"
    "promtail:Promtail"
    "jaeger:Jaeger"
    "uptime-kuma:Uptime Kuma"
)

# 각 서비스 시작
for service_info in "${SERVICES[@]}"; do
    IFS=':' read -r service_name service_display <<< "$service_info"
    
    progress "${service_display} 시작 중..."
    
    cd "${service_name}"
    
    # 환경에 따른 docker-compose 명령어 선택
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d
    else
        docker compose up -d
    fi
    
    cd ..
    
    # 서비스 시작 대기
    sleep 5
    
    success "${service_display} 시작 완료"
done

# 전체 서비스 상태 확인
echo ""
progress "전체 서비스 상태 확인 중..."
sleep 10

echo ""
echo "📊 서비스 상태 요약:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep meritz

echo ""
echo "🔍 헬스체크 수행 중..."

# 개선된 헬스체크 (서비스별 엔드포인트 사용)
HEALTH_CHECKS=(
    "traefik:10000:/api/overview"
    "prometheus:10001/-/healthy"
    "grafana:10002/api/health"
    "loki:10003/ready"
    "jaeger:10004/"
    "node-exporter:10006/metrics"
    "cadvisor:10007/metrics"
    "uptime-kuma:10008/"
)

HEALTHY_SERVICES=0
TOTAL_SERVICES=${#HEALTH_CHECKS[@]}

for check in "${HEALTH_CHECKS[@]}"; do
    IFS=':' read -r service port endpoint <<< "$check"
    url="http://localhost:${port}${endpoint}"
    
    if curl -f -s "${url}" > /dev/null 2>&1; then
        echo -e "✅ ${service} (포트 ${port}): ${GREEN}정상${NC}"
        ((HEALTHY_SERVICES++))
    else
        echo -e "❌ ${service} (포트 ${port}): ${RED}확인 필요${NC}"
    fi
done

echo ""
echo "========================="
if [ $HEALTHY_SERVICES -eq $TOTAL_SERVICES ]; then
    echo -e "${GREEN}🎉 모든 서비스가 정상적으로 시작되었습니다!${NC}"
else
    echo -e "${YELLOW}⚠️  일부 서비스가 아직 시작 중이거나 문제가 있습니다.${NC}"
    echo "   정상: ${HEALTHY_SERVICES}/${TOTAL_SERVICES}"
fi

echo ""
echo "📊 접속 정보:"
echo "  - Traefik 대시보드: http://localhost:10000"
echo "  - Prometheus: http://localhost:10001"
echo "  - Grafana: http://localhost:10002 (admin/admin123)"
echo "  - Loki: http://localhost:10003"
echo "  - Jaeger: http://localhost:10004"
echo "  - Node Exporter: http://localhost:10006"
echo "  - cAdvisor: http://localhost:10007"
echo "  - Uptime Kuma: http://localhost:10008"
echo ""
echo "🌐 도메인 접속 (DNS 설정 후):"
echo "  - https://traefik.meritz.com"
echo "  - https://grafana.meritz.com"
echo "  - https://prometheus.meritz.com"
echo "  - https://uptime.meritz.com"
echo ""
echo "🔧 관리 명령어:"
echo "  - 전체 상태 확인: ./scripts/status.sh"
echo "  - 전체 중지: ./scripts/stop-all.sh"
echo "  - 개별 서비스 재시작: cd [service] && docker-compose restart"
echo ""
echo "🎯 다음 단계:"
echo "  1. DNS A 레코드 설정 (*.meritz.com → 서버 IP)"
echo "  2. Grafana에서 대시보드 확인"
echo "  3. Uptime Kuma에서 모니터링 설정"
