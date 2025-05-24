#!/bin/bash

# 실행 중인 컨테이너와 아직 실행되지 않은 컨테이너를 파악하여 
# 실행되지 않은 서비스만 시작하는 스크립트

set -e

echo "🔍 현재 실행 중인 서비스를 확인합니다..."
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# infra-app 디렉토리로 이동
cd /Users/gossing/WorkPlace/infra-app

# 서비스 리스트
SERVICES=(
    "gateway:meritz-traefik"
    "prometheus:meritz-prometheus"
    "loki:meritz-loki"
    "grafana:meritz-grafana"
    "node-exporter:meritz-node-exporter"
    "cadvisor:meritz-cadvisor"
    "promtail:meritz-promtail"
    "jaeger:meritz-jaeger"
    "uptime-kuma:meritz-uptime-kuma"
)

# 각 서비스 확인 및 시작
for service_info in "${SERVICES[@]}"; do
    IFS=':' read -r service_dir container_name <<< "$service_info"
    
    # 컨테이너가 실행 중인지 확인
    if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
        echo -e "✅ ${service_dir}: ${GREEN}실행 중${NC}"
    else
        echo -e "❌ ${service_dir}: ${RED}중지됨${NC}"
        echo -e "${BLUE}[진행중]${NC} ${service_dir} 시작 중..."
        
        cd "${service_dir}"
        
        # docker-compose 명령어 실행
        if command -v docker-compose &> /dev/null; then
            docker-compose up -d
        else
            docker compose up -d
        fi
        
        cd ..
        
        echo -e "${GREEN}[완료]${NC} ${service_dir} 시작 완료"
    fi
    echo ""
done

# 전체 상태 확인
echo ""
echo "📊 전체 서비스 상태:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep meritz || true

echo ""
echo "✅ 모든 서비스 확인 완료!"
