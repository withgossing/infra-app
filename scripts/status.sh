#!/bin/bash

# Meritz 전체 인프라 상태 확인 스크립트
# 모든 서비스의 상태를 한눈에 확인합니다

set -e

echo "📊 Meritz 인프라 상태 확인"
echo "⏰ $(date)"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 컨테이너 상태 확인
echo "🐳 컨테이너 상태:"
echo "=================================================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|meritz)" || echo "Meritz 컨테이너가 실행되지 않았습니다."

echo ""
echo "💾 볼륨 사용량:"
echo "=================================================="
docker volume ls | grep -E "(DRIVER|meritz|prometheus|grafana|loki|jaeger)" || echo "Meritz 관련 볼륨이 없습니다."

echo ""
echo "🌐 서비스 헬스체크:"
echo "=================================================="

# 헬스체크 대상 서비스들
HEALTH_CHECKS=(
    "Traefik:1000:/ping"
    "Prometheus:1002:/-/healthy"
    "Grafana:1003:/api/health"
    "Loki:1004:/ready"
    "Jaeger:1005:/"
    "Node Exporter:1007:/metrics"
    "cAdvisor:1008:/metrics"
    "Uptime Kuma:1009:/"
)

HEALTHY_COUNT=0
TOTAL_COUNT=${#HEALTH_CHECKS[@]}

for check in "${HEALTH_CHECKS[@]}"; do
    IFS=':' read -r service port endpoint <<< "$check"
    
    printf "%-15s (포트 %s): " "$service" "$port"
    
    if curl -f -s --max-time 5 "http://localhost:${port}${endpoint}" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 정상${NC}"
        ((HEALTHY_COUNT++))
    else
        echo -e "${RED}❌ 오류${NC}"
    fi
done

echo ""
echo "📈 리소스 사용량:"
echo "=================================================="

# Docker 컨테이너 리소스 사용량
if docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep meritz > /dev/null 2>&1; then
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | head -1
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep meritz
else
    echo "실행 중인 Meritz 컨테이너가 없습니다."
fi

echo ""
echo "💻 시스템 리소스:"
echo "=================================================="

# 메모리 사용량
echo -n "메모리: "
free -h | awk 'NR==2{printf "사용: %s/%s (%.2f%%)", $3,$2,$3*100/$2}'
echo ""

# 디스크 사용량
echo -n "디스크: "
df -h . | awk 'NR==2{printf "사용: %s/%s (%s)", $3,$2,$5}'
echo ""

# CPU 로드
echo -n "CPU 로드: "
uptime | awk -F'load average:' '{print $2}'

echo ""
echo "🔗 네트워크 상태:"
echo "=================================================="

# Docker 네트워크 확인
if docker network ls | grep meritz-network > /dev/null; then
    echo -e "meritz-network: ${GREEN}✅ 존재${NC}"
    
    # 네트워크에 연결된 컨테이너 수
    CONNECTED_CONTAINERS=$(docker network inspect meritz-network --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | wc -w)
    echo "연결된 컨테이너 수: $CONNECTED_CONTAINERS"
else
    echo -e "meritz-network: ${RED}❌ 없음${NC}"
fi

echo ""
echo "📊 요약:"
echo "=================================================="
echo -e "전체 상태: ${HEALTHY_COUNT}/${TOTAL_COUNT} 서비스가 정상 작동 중"

if [ $HEALTHY_COUNT -eq $TOTAL_COUNT ]; then
    echo -e "상태: ${GREEN}🎉 모든 서비스 정상${NC}"
elif [ $HEALTHY_COUNT -gt $((TOTAL_COUNT * 2 / 3)) ]; then
    echo -e "상태: ${YELLOW}⚠️  일부 서비스 문제${NC}"
else
    echo -e "상태: ${RED}🚨 심각한 문제${NC}"
fi

echo ""
echo "🔧 빠른 액션:"
echo "  - 전체 시작: ./scripts/start-all.sh"
echo "  - 전체 중지: ./scripts/stop-all.sh"
echo "  - 개별 재시작: cd [service] && docker-compose restart"
echo "  - 로그 확인: cd [service] && docker-compose logs -f"

echo ""
echo "🌐 접속 주소:"
echo "  - http://localhost:1000 (Traefik)"
echo "  - http://localhost:1003 (Grafana)"
echo "  - http://localhost:1002 (Prometheus)"
echo "  - http://localhost:1009 (Uptime Kuma)"
