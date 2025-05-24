#!/bin/bash

# 개선된 헬스체크 스크립트
# 각 서비스별로 적절한 헬스체크 엔드포인트를 사용

echo "🔍 서비스 헬스체크를 수행합니다..."
echo "📅 $(date)"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 헬스체크 정의 (서비스명:포트:엔드포인트)
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

echo "📊 서비스별 헬스체크 결과:"
echo ""

for check in "${HEALTH_CHECKS[@]}"; do
    IFS=':' read -r service port endpoint <<< "$check"
    
    # URL 구성
    url="http://localhost:${port}${endpoint}"
    
    # 헬스체크 수행
    if curl -f -s "${url}" > /dev/null 2>&1; then
        echo -e "✅ ${service} (${url}): ${GREEN}정상${NC}"
        ((HEALTHY_SERVICES++))
    else
        # 실패 시 상세 정보 출력
        echo -e "❌ ${service} (${url}): ${RED}확인 필요${NC}"
        
        # HTTP 응답 코드 확인
        response=$(curl -s -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null || echo "연결 실패")
        echo -e "   응답 코드: ${response}"
        
        # 컨테이너 상태 확인
        container_name="meritz-${service}"
        container_status=$(docker ps -a --filter "name=${container_name}" --format "{{.Status}}" | head -1)
        if [ -n "$container_status" ]; then
            echo -e "   컨테이너 상태: ${container_status}"
        else
            echo -e "   컨테이너를 찾을 수 없습니다"
        fi
    fi
done

echo ""
echo "========================="
echo "헬스체크 요약: ${HEALTHY_SERVICES}/${TOTAL_SERVICES} 서비스 정상"

if [ $HEALTHY_SERVICES -eq $TOTAL_SERVICES ]; then
    echo -e "${GREEN}🎉 모든 서비스가 정상적으로 작동 중입니다!${NC}"
else
    echo -e "${YELLOW}⚠️  일부 서비스에 문제가 있습니다.${NC}"
    echo ""
    echo "문제 해결 방법:"
    echo "1. 개별 서비스 로그 확인: docker logs [container-name]"
    echo "2. 서비스 재시작: cd [service-dir] && docker compose restart"
    echo "3. 디버그 스크립트 실행: ./scripts/debug-services.sh"
fi

echo ""
echo "📊 실행 중인 모든 Meritz 컨테이너:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep meritz || echo "실행 중인 Meritz 컨테이너가 없습니다."
