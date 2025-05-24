#!/bin/bash

# Meritz Gateway 헬스체크 스크립트
# 모든 서비스의 상태를 확인합니다

set -e

echo "🏥 Meritz Gateway 헬스체크를 시작합니다..."
echo "⏰ $(date)"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 헬스체크 결과 저장
HEALTH_STATUS=0

# 함수: 서비스 상태 확인
check_service() {
    local service_name="$1"
    local url="$2"
    local expected_code="${3:-200}"
    
    echo -n "🔍 $service_name 확인 중... "
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_code"; then
        echo -e "${GREEN}✅ 정상${NC}"
        return 0
    else
        echo -e "${RED}❌ 오류${NC}"
        return 1
    fi
}

# 함수: Docker 컨테이너 상태 확인
check_container() {
    local container_name="$1"
    echo -n "🐳 $container_name 컨테이너... "
    
    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
        echo -e "${GREEN}✅ 실행 중${NC}"
        return 0
    else
        echo -e "${RED}❌ 중지됨${NC}"
        return 1
    fi
}

echo "📊 컨테이너 상태 확인:"
check_container "meritz-gateway" || HEALTH_STATUS=1
check_container "meritz-prometheus" || HEALTH_STATUS=1
check_container "meritz-grafana" || HEALTH_STATUS=1
check_container "meritz-loki" || HEALTH_STATUS=1
check_container "meritz-promtail" || HEALTH_STATUS=1
check_container "meritz-jaeger" || HEALTH_STATUS=1
check_container "meritz-node-exporter" || HEALTH_STATUS=1
check_container "meritz-cadvisor" || HEALTH_STATUS=1
check_container "meritz-uptime-kuma" || HEALTH_STATUS=1

echo ""
echo "🌐 서비스 HTTP 상태 확인:"
check_service "Traefik API" "http://localhost:1000/ping" || HEALTH_STATUS=1
check_service "Prometheus" "http://localhost:1002/-/healthy" || HEALTH_STATUS=1
check_service "Grafana" "http://localhost:1003/api/health" || HEALTH_STATUS=1
check_service "Loki" "http://localhost:1004/ready" || HEALTH_STATUS=1
check_service "Jaeger" "http://localhost:1005" "200\|302" || HEALTH_STATUS=1
check_service "Node Exporter" "http://localhost:1007/metrics" || HEALTH_STATUS=1
check_service "cAdvisor" "http://localhost:1008/metrics" || HEALTH_STATUS=1
check_service "Uptime Kuma" "http://localhost:1009" || HEALTH_STATUS=1

echo ""
echo "📈 리소스 사용량 확인:"

# 메모리 사용량
echo -n "💾 메모리 사용량... "
MEMORY_USAGE=$(docker stats --no-stream --format "table {{.MemPerc}}" | grep -v "MEM" | sed 's/%//' | awk '{sum+=$1} END {printf "%.1f", sum}')
if (( $(echo "$MEMORY_USAGE < 80" | bc -l) )); then
    echo -e "${GREEN}${MEMORY_USAGE}% (정상)${NC}"
else
    echo -e "${YELLOW}${MEMORY_USAGE}% (주의)${NC}"
fi

# CPU 사용량
echo -n "🖥️  CPU 사용량... "
CPU_USAGE=$(docker stats --no-stream --format "table {{.CPUPerc}}" | grep -v "CPU" | sed 's/%//' | awk '{sum+=$1} END {printf "%.1f", sum}')
if (( $(echo "$CPU_USAGE < 80" | bc -l) )); then
    echo -e "${GREEN}${CPU_USAGE}% (정상)${NC}"
else
    echo -e "${YELLOW}${CPU_USAGE}% (주의)${NC}"
fi

# 디스크 사용량
echo -n "💿 디스크 사용량... "
DISK_USAGE=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    echo -e "${GREEN}${DISK_USAGE}% (정상)${NC}"
else
    echo -e "${YELLOW}${DISK_USAGE}% (주의)${NC}"
fi

echo ""
echo "🔗 네트워크 확인:"
echo -n "📡 meritz-network... "
if docker network ls | grep -q "meritz-network"; then
    echo -e "${GREEN}✅ 존재${NC}"
else
    echo -e "${RED}❌ 없음${NC}"
    HEALTH_STATUS=1
fi

echo ""
echo "📁 볼륨 확인:"
for volume in prometheus_data grafana_data loki_data jaeger_data; do
    echo -n "💾 gateway_$volume... "
    if docker volume ls | grep -q "gateway_$volume"; then
        echo -e "${GREEN}✅ 존재${NC}"
    else
        echo -e "${YELLOW}⚠️  없음${NC}"
    fi
done

echo ""
echo "📋 상세 컨테이너 정보:"
docker-compose ps

# SSL 인증서 확인
echo ""
echo "🔐 SSL 인증서 확인:"
if [ -f "./traefik/ssl/acme.json" ]; then
    echo -n "📜 ACME 인증서... "
    if [ -s "./traefik/ssl/acme.json" ]; then
        echo -e "${GREEN}✅ 존재${NC}"
    else
        echo -e "${YELLOW}⚠️  비어있음${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  ACME 인증서 파일이 없습니다${NC}"
fi

# 로그 파일 확인
echo ""
echo "📝 로그 파일 확인:"
if [ -f "./traefik/logs/traefik.log" ]; then
    LOG_SIZE=$(du -h "./traefik/logs/traefik.log" | cut -f1)
    echo -e "📄 Traefik 로그: ${GREEN}$LOG_SIZE${NC}"
else
    echo -e "📄 Traefik 로그: ${YELLOW}⚠️  없음${NC}"
fi

if [ -f "./traefik/logs/access.log" ]; then
    ACCESS_LOG_SIZE=$(du -h "./traefik/logs/access.log" | cut -f1)
    echo -e "📄 Access 로그: ${GREEN}$ACCESS_LOG_SIZE${NC}"
else
    echo -e "📄 Access 로그: ${YELLOW}⚠️  없음${NC}"
fi

echo ""
echo "========================="
if [ $HEALTH_STATUS -eq 0 ]; then
    echo -e "${GREEN}🎉 모든 서비스가 정상 작동 중입니다!${NC}"
else
    echo -e "${RED}⚠️  일부 서비스에 문제가 있습니다.${NC}"
    echo ""
    echo "🔧 문제 해결 방법:"
    echo "  - 로그 확인: docker-compose logs [service-name]"
    echo "  - 서비스 재시작: docker-compose restart [service-name]"
    echo "  - 전체 재시작: ./scripts/stop.sh && ./scripts/start.sh"
fi

echo ""
echo "📊 실시간 모니터링:"
echo "  - Traefik 대시보드: http://localhost:1000"
echo "  - Grafana: http://localhost:1003"
echo "  - Prometheus: http://localhost:1002"
echo "  - Uptime Kuma: http://localhost:1009"

exit $HEALTH_STATUS
