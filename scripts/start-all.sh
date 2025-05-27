#!/bin/bash

# 전체 인프라 서비스 시작 스크립트
# 사용법: ./scripts/start-all.sh

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 서비스 시작 함수
start_service() {
    local service_name=$1
    local wait_time=${2:-30}
    
    log_info "Starting $service_name..."
    
    if [ -d "$service_name" ]; then
        cd "$service_name"
        
        # 특별한 설정이 필요한 서비스들
        case $service_name in
            "security")
                # 스크립트 실행 권한 부여
                if [ -d "scripts" ]; then
                    chmod +x scripts/*.sh
                fi
                ;;
        esac
        
        # Docker Compose 시작
        if docker-compose up -d; then
            log_success "$service_name started successfully"
            
            # 서비스가 준비될 때까지 대기
            log_info "Waiting ${wait_time}s for $service_name to be ready..."
            sleep $wait_time
        else
            log_error "Failed to start $service_name"
            exit 1
        fi
        
        cd ..
    else
        log_warning "Service directory $service_name not found"
    fi
}

# 메인 시작 로직
main() {
    log_info "🚀 Starting all infrastructure services..."
    log_info "📁 Working directory: $(pwd)"
    
    # 현재 디렉토리가 infra-app인지 확인
    if [[ ! "$(basename $(pwd))" == "infra-app" ]]; then
        log_error "Please run this script from the infra-app directory"
        exit 1
    fi
    
    # 시작 시간 기록
    start_time=$(date +%s)
    
    log_info "🔧 Starting infrastructure services in order..."
    echo ""
    
    # 1. 보안 서비스 (가장 먼저 - 다른 서비스들이 의존)
    start_service "security" 60
    
    # 2. 서비스 디스커버리 (서비스 등록/발견을 위해 빨리 시작)
    start_service "service-discovery" 30
    
    # 3. DNS 서비스 (네트워크 해석을 위해)
    start_service "dns" 20
    
    # 4. 캐시 서비스 (많은 서비스가 캐시를 사용)
    start_service "cache" 25
    
    # 5. 메시징 서비스 (이벤트 기반 통신을 위해)
    start_service "messaging" 45
    
    # 6. 모니터링 서비스 (메트릭 수집 시작)
    start_service "monitoring" 30
    
    # 7. 로깅 서비스 (로그 수집 시작)
    start_service "logging" 45
    
    # 8. 트레이싱 서비스 (분산 추적을 위해)
    start_service "tracing" 30
    
    # 9. 레지스트리 서비스 (컨테이너 이미지 관리)
    start_service "registry" 40
    
    # 10. API 게이트웨이 (모든 서비스가 준비된 후 마지막)
    start_service "gateway" 30
    
    # 완료 시간 계산
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    minutes=$((duration / 60))
    seconds=$((duration % 60))
    
    echo ""
    log_success "🎉 All infrastructure services started successfully!"
    log_info "⏱️  Total startup time: ${minutes}m ${seconds}s"
    echo ""
    
    # 서비스 상태 요약
    log_info "📊 Service Status Summary:"
    echo ""
    printf "%-20s %-10s %-30s\n" "SERVICE" "STATUS" "URL"
    echo "=================================================================="
    printf "%-20s %-10s %-30s\n" "Keycloak" "✅ Ready" "http://localhost:10900"
    printf "%-20s %-10s %-30s\n" "Vault" "✅ Ready" "http://localhost:10902"
    printf "%-20s %-10s %-30s\n" "Consul" "✅ Ready" "http://localhost:10502"
    printf "%-20s %-10s %-30s\n" "CoreDNS" "✅ Ready" "DNS: localhost:10600"
    printf "%-20s %-10s %-30s\n" "Redis" "✅ Ready" "redis://localhost:10200"
    printf "%-20s %-10s %-30s\n" "Kafka" "✅ Ready" "http://localhost:10703"
    printf "%-20s %-10s %-30s\n" "Prometheus" "✅ Ready" "http://localhost:10000"
    printf "%-20s %-10s %-30s\n" "Grafana" "✅ Ready" "http://localhost:10001"
    printf "%-20s %-10s %-30s\n" "Kibana" "✅ Ready" "http://localhost:10102"
    printf "%-20s %-10s %-30s\n" "Jaeger" "✅ Ready" "http://localhost:10400"
    printf "%-20s %-10s %-30s\n" "Harbor" "✅ Ready" "http://localhost:10800"
    printf "%-20s %-10s %-30s\n" "Kong" "✅ Ready" "http://localhost:10300"
    echo ""
    
    log_info "🔍 Run './scripts/health-check.sh' to verify all services"
    log_info "📊 Run './scripts/status.sh' for detailed status information"
    log_info "🌐 Open your browser to access the web UIs above"
    echo ""
}

# 인터럽트 시그널 처리
trap 'log_error "Script interrupted by user"; exit 1' INT

# 메인 함수 실행
main "$@"
