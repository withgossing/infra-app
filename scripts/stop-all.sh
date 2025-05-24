#!/bin/bash

# Meritz 전체 인프라 중지 스크립트
# 모든 모니터링 서비스를 순차적으로 중지합니다

set -e

echo "🛑 Meritz 전체 인프라를 중지합니다..."
echo "📅 $(date)"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

progress() {
    echo -e "${BLUE}[진행중]${NC} $1"
}

success() {
    echo -e "${GREEN}[완료]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[주의]${NC} $1"
}

# 현재 실행 중인 서비스 확인
echo "📋 현재 실행 중인 Meritz 서비스들:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep meritz || echo "실행 중인 Meritz 서비스가 없습니다."

echo ""
read -p "정말로 모든 Meritz 인프라 서비스를 중지하시겠습니까? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 서비스 중지 순서 (역순으로)
    SERVICES=(
        "uptime-kuma:Uptime Kuma"
        "jaeger:Jaeger"
        "promtail:Promtail"
        "cadvisor:cAdvisor"
        "node-exporter:Node Exporter"
        "grafana:Grafana"
        "loki:Loki"
        "prometheus:Prometheus"
        "gateway:Gateway (Traefik)"
    )
    
    # 각 서비스 중지
    for service_info in "${SERVICES[@]}"; do
        IFS=':' read -r service_name service_display <<< "$service_info"
        
        if [ -d "${service_name}" ]; then
            progress "${service_display} 중지 중..."
            
            cd "${service_name}"
            
            # 환경에 따른 docker-compose 명령어 선택
            if command -v docker-compose &> /dev/null; then
                docker-compose down 2>/dev/null || warning "${service_display} 중지 중 문제가 발생했습니다"
            else
                docker compose down 2>/dev/null || warning "${service_display} 중지 중 문제가 발생했습니다"
            fi
            
            cd ..
            success "${service_display} 중지 완료"
        else
            warning "${service_name} 디렉토리를 찾을 수 없습니다"
        fi
    done
    
    echo ""
    progress "남은 Meritz 컨테이너 정리 중..."
    
    # 남은 Meritz 컨테이너들 강제 중지 및 제거
    MERITZ_CONTAINERS=$(docker ps -aq --filter "name=meritz-" 2>/dev/null || true)
    if [ -n "$MERITZ_CONTAINERS" ]; then
        docker stop $MERITZ_CONTAINERS 2>/dev/null || true
        docker rm $MERITZ_CONTAINERS 2>/dev/null || true
        success "남은 컨테이너들 정리 완료"
    else
        success "정리할 추가 컨테이너가 없습니다"
    fi
    
    echo ""
    echo "✅ 모든 Meritz 인프라 서비스가 성공적으로 중지되었습니다."
    echo ""
    echo "📋 중지된 서비스들:"
    echo "  - Traefik Gateway"
    echo "  - Prometheus"
    echo "  - Grafana"
    echo "  - Loki"
    echo "  - Promtail"
    echo "  - Jaeger"
    echo "  - Node Exporter"
    echo "  - cAdvisor"
    echo "  - Uptime Kuma"
    echo ""
    echo "💡 참고사항:"
    echo "  - 데이터는 Docker 볼륨에 보존됩니다"
    echo "  - 재시작: ./scripts/start-all.sh"
    echo "  - 개별 서비스 시작: cd [service] && docker-compose up -d"
    echo "  - 완전 삭제: ./scripts/cleanup-all.sh"
    
else
    echo "❌ 중지가 취소되었습니다."
fi
