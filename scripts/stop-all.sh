#!/bin/bash

# 전체 인프라 서비스 중지 스크립트
# 사용법: ./scripts/stop-all.sh [--force]

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

# 강제 종료 플래그
FORCE_STOP=false
if [[ "$1" == "--force" ]]; then
    FORCE_STOP=true
fi

# 서비스 중지 함수
stop_service() {
    local service_name=$1
    
    log_info "Stopping $service_name..."
    
    if [ -d "$service_name" ]; then
        cd "$service_name"
        
        if [ "$FORCE_STOP" = true ]; then
            # 강제 중지 (볼륨도 삭제)
            if docker-compose down -v --remove-orphans; then
                log_success "$service_name stopped and volumes removed"
            else
                log_warning "Failed to stop $service_name gracefully"
            fi
        else
            # 일반 중지
            if docker-compose down --remove-orphans; then
                log_success "$service_name stopped successfully"
            else
                log_warning "Failed to stop $service_name gracefully"
            fi
        fi
        
        cd ..
    else
        log_warning "Service directory $service_name not found"
    fi
}

# 사용 중인 포트 확인 함수
check_ports() {
    log_info "Checking for services still using infrastructure ports..."
    
    local ports=(10000 10001 10002 10100 10101 10102 10103 10104 10200 10201 10202 
                 10300 10301 10302 10400 10401 10402 10403 10404 10500 10501 10502
                 10600 10601 10700 10701 10702 10703 10704 10800 10801 10802 10803
                 10900 10901 10902 10903)
    
    local used_ports=()
    
    for port in "${ports[@]}"; do
        if lsof -i :$port > /dev/null 2>&1; then
            used_ports+=($port)
        fi
    done
    
    if [ ${#used_ports[@]} -gt 0 ]; then
        log_warning "The following ports are still in use:"
        printf "  %s\n" "${used_ports[@]}"
        echo ""
        log_info "Run with --force to forcefully kill processes using these ports"
    else
        log_success "All infrastructure ports are now free"
    fi
}

# 강제 포트 정리 함수
force_cleanup_ports() {
    log_warning "Forcefully cleaning up infrastructure ports..."
    
    local ports=(10000 10001 10002 10100 10101 10102 10103 10104 10200 10201 10202 
                 10300 10301 10302 10400 10401 10402 10403 10404 10500 10501 10502
                 10600 10601 10700 10701 10702 10703 10704 10800 10801 10802 10803
                 10900 10901 10902 10903)
    
    for port in "${ports[@]}"; do
        local pids=$(lsof -ti :$port 2>/dev/null || true)
        if [ ! -z "$pids" ]; then
            log_info "Killing processes using port $port: $pids"
            echo "$pids" | xargs -r kill -9
        fi
    done
}

# Docker 시스템 정리 함수
cleanup_docker() {
    log_info "Cleaning up Docker resources..."
    
    # 사용하지 않는 컨테이너 제거
    log_info "Removing stopped containers..."
    docker container prune -f
    
    # 사용하지 않는 네트워크 제거
    log_info "Removing unused networks..."
    docker network prune -f
    
    if [ "$FORCE_STOP" = true ]; then
        # 강제 모드에서는 볼륨도 정리
        log_info "Removing unused volumes..."
        docker volume prune -f
        
        # 사용하지 않는 이미지도 정리
        log_info "Removing dangling images..."
        docker image prune -f
    fi
    
    log_success "Docker cleanup completed"
}

# 메인 중지 로직
main() {
    if [ "$FORCE_STOP" = true ]; then
        log_warning "🛑 Force stopping all infrastructure services (volumes will be deleted)..."
    else
        log_info "🛑 Stopping all infrastructure services..."
    fi
    
    log_info "📁 Working directory: $(pwd)"
    
    # 현재 디렉토리가 infra-app인지 확인
    if [[ ! "$(basename $(pwd))" == "infra-app" ]]; then
        log_error "Please run this script from the infra-app directory"
        exit 1
    fi
    
    # 시작 시간 기록
    start_time=$(date +%s)
    
    echo ""
    log_info "🔧 Stopping infrastructure services in reverse order..."
    echo ""
    
    # 역순으로 서비스 중지 (시작의 반대 순서)
    
    # 1. API 게이트웨이 (외부 트래픽 차단)
    stop_service "gateway"
    
    # 2. 레지스트리 서비스
    stop_service "registry"
    
    # 3. 트레이싱 서비스
    stop_service "tracing"
    
    # 4. 로깅 서비스
    stop_service "logging"
    
    # 5. 모니터링 서비스
    stop_service "monitoring"
    
    # 6. 메시징 서비스
    stop_service "messaging"
    
    # 7. 캐시 서비스
    stop_service "cache"
    
    # 8. DNS 서비스
    stop_service "dns"
    
    # 9. 서비스 디스커버리
    stop_service "service-discovery"
    
    # 10. 보안 서비스 (마지막)
    stop_service "security"
    
    echo ""
    
    # Docker 정리
    cleanup_docker
    
    echo ""
    
    # 포트 상태 확인
    if [ "$FORCE_STOP" = true ]; then
        force_cleanup_ports
        sleep 2
    fi
    
    check_ports
    
    # 완료 시간 계산
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    minutes=$((duration / 60))
    seconds=$((duration % 60))
    
    echo ""
    log_success "🎉 All infrastructure services stopped successfully!"
    log_info "⏱️  Total shutdown time: ${minutes}m ${seconds}s"
    echo ""
    
    if [ "$FORCE_STOP" = true ]; then
        log_warning "⚠️  All data volumes have been deleted (force mode)"
        log_info "💡 Next startup will initialize fresh data"
    else
        log_info "💾 Data volumes preserved for next startup"
        log_info "🗑️  Use --force flag to delete all data volumes"
    fi
    
    echo ""
    log_info "🚀 Run './scripts/start-all.sh' to restart all services"
    echo ""
}

# 확인 메시지 (강제 모드일 때)
if [ "$FORCE_STOP" = true ]; then
    echo ""
    log_warning "⚠️  WARNING: Force mode will delete all data volumes!"
    log_warning "⚠️  This will permanently delete all databases, logs, and configurations!"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Operation cancelled by user"
        exit 0
    fi
fi

# 인터럽트 시그널 처리
trap 'log_error "Script interrupted by user"; exit 1' INT

# 메인 함수 실행
main "$@"
