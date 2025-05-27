#!/bin/bash

# 인프라 서비스 로그 뷰어 스크립트
# 사용법: ./scripts/logs.sh [service-name] [--follow] [--tail 100] [--since 1h]

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 기본값 설정
SERVICE_NAME=""
FOLLOW=false
TAIL_LINES=50
SINCE=""
SHOW_TIMESTAMPS=true

# 사용법 출력
usage() {
    echo "Usage: $0 [service-name] [options]"
    echo ""
    echo "Services:"
    echo "  security, gateway, monitoring, logging, cache, tracing"
    echo "  service-discovery, dns, messaging, registry, all"
    echo ""
    echo "Options:"
    echo "  --follow, -f         Follow log output"
    echo "  --tail N             Number of lines to show (default: 50)"
    echo "  --since TIME         Show logs since timestamp (e.g., 1h, 30m, 2023-01-01)"
    echo "  --no-timestamps      Hide timestamps"
    echo "  --help, -h           Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 security --follow"
    echo "  $0 monitoring --tail 100"
    echo "  $0 all --since 1h"
}

# 파라미터 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        --follow|-f)
            FOLLOW=true
            shift
            ;;
        --tail)
            TAIL_LINES="$2"
            shift 2
            ;;
        --since)
            SINCE="$2"
            shift 2
            ;;
        --no-timestamps)
            SHOW_TIMESTAMPS=false
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if [ -z "$SERVICE_NAME" ]; then
                SERVICE_NAME="$1"
            else
                echo "Multiple service names not supported"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# 서비스 이름이 제공되지 않은 경우 대화형 선택
if [ -z "$SERVICE_NAME" ]; then
    echo -e "${CYAN}🔍 Select a service to view logs:${NC}"
    echo ""
    echo "1) security      - Keycloak + Vault"
    echo "2) gateway       - Kong API Gateway"
    echo "3) monitoring    - Prometheus + Grafana"
    echo "4) logging       - ELK Stack"
    echo "5) cache         - Redis Cluster"
    echo "6) tracing       - Jaeger"
    echo "7) service-discovery - Consul"
    echo "8) dns           - CoreDNS"
    echo "9) messaging     - Apache Kafka"
    echo "10) registry     - Harbor"
    echo "11) all          - All services"
    echo ""
    read -p "Enter choice (1-11): " choice
    
    case $choice in
        1) SERVICE_NAME="security";;
        2) SERVICE_NAME="gateway";;
        3) SERVICE_NAME="monitoring";;
        4) SERVICE_NAME="logging";;
        5) SERVICE_NAME="cache";;
        6) SERVICE_NAME="tracing";;
        7) SERVICE_NAME="service-discovery";;
        8) SERVICE_NAME="dns";;
        9) SERVICE_NAME="messaging";;
        10) SERVICE_NAME="registry";;
        11) SERVICE_NAME="all";;
        *) echo "Invalid choice"; exit 1;;
    esac
fi

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✅]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠️]${NC} $1"
}

log_error() {
    echo -e "${RED}[❌]${NC} $1"
}

# Docker Compose 로그 옵션 구성
build_docker_logs_options() {
    local options=""
    
    if [ "$FOLLOW" = true ]; then
        options="$options -f"
    fi
    
    if [ ! -z "$TAIL_LINES" ]; then
        options="$options --tail $TAIL_LINES"
    fi
    
    if [ ! -z "$SINCE" ]; then
        options="$options --since $SINCE"
    fi
    
    if [ "$SHOW_TIMESTAMPS" = true ]; then
        options="$options -t"
    fi
    
    echo "$options"
}

# 개별 서비스 로그 보기
show_service_logs() {
    local service=$1
    local service_dir=$2
    
    if [ ! -d "$service_dir" ]; then
        log_error "Service directory not found: $service_dir"
        return 1
    fi
    
    log_info "📋 Showing logs for $service service..."
    echo ""
    
    cd "$service_dir"
    
    local log_options
    log_options=$(build_docker_logs_options)
    
    # 서비스가 실행 중인지 확인
    if ! docker-compose ps | grep -q "Up"; then
        log_warning "No containers are running for $service service"
        log_info "Start the service with: cd $service_dir && docker-compose up -d"
        cd ..
        return 1
    fi
    
    echo -e "${PURPLE}=== $service Service Logs ===${NC}"
    
    # Docker Compose 로그 실행
    if [ "$FOLLOW" = true ]; then
        echo -e "${YELLOW}Press Ctrl+C to stop following logs${NC}"
        echo ""
    fi
    
    docker-compose logs $log_options
    
    cd ..
}

# 모든 서비스 로그 보기 (요약)
show_all_logs() {
    local services=("security" "gateway" "monitoring" "logging" "cache" "tracing" "service-discovery" "dns" "messaging" "registry")
    
    log_info "📋 Showing logs for all infrastructure services..."
    echo ""
    
    if [ "$FOLLOW" = true ]; then
        log_warning "Follow mode not supported for 'all' services. Showing recent logs only."
        FOLLOW=false
    fi
    
    for service in "${services[@]}"; do
        if [ -d "$service" ]; then
            echo -e "${PURPLE}=== $service Service ===${NC}"
            
            cd "$service"
            
            # 실행 중인 컨테이너만 확인
            if docker-compose ps | grep -q "Up"; then
                # 최근 로그만 표시 (따라가기 없이)
                docker-compose logs --tail 10 -t | head -20
            else
                echo -e "${YELLOW}No running containers${NC}"
            fi
            
            cd ..
            echo ""
        else
            log_warning "Service directory not found: $service"
        fi
    done
}

# 특정 컨테이너 로그 보기
show_container_logs() {
    local container_pattern=$1
    
    log_info "🐳 Finding containers matching: $container_pattern"
    
    local containers
    containers=$(docker ps --format "{{.Names}}" | grep "$container_pattern" || true)
    
    if [ -z "$containers" ]; then
        log_error "No running containers found matching: $container_pattern"
        return 1
    fi
    
    echo "Found containers:"
    echo "$containers" | sed 's/^/  • /'
    echo ""
    
    # 첫 번째 컨테이너의 로그를 보여줌
    local first_container
    first_container=$(echo "$containers" | head -1)
    
    log_info "Showing logs for container: $first_container"
    echo ""
    
    local log_options
    log_options=$(build_docker_logs_options)
    
    docker logs $log_options "$first_container"
}

# 로그 검색 함수
search_logs() {
    local service=$1
    local search_term=$2
    
    if [ -z "$search_term" ]; then
        read -p "Enter search term: " search_term
    fi
    
    if [ -z "$search_term" ]; then
        log_error "Search term is required"
        return 1
    fi
    
    log_info "🔍 Searching for '$search_term' in $service logs..."
    echo ""
    
    cd "$service"
    
    # 로그에서 검색어 찾기
    docker-compose logs --no-color | grep -i --color=always "$search_term" | head -50
    
    cd ..
}

# 오류 로그만 표시
show_error_logs() {
    local service=$1
    
    log_info "❌ Showing error logs for $service..."
    echo ""
    
    cd "$service"
    
    # ERROR, FATAL, Exception 등의 키워드로 필터링
    docker-compose logs --no-color | grep -iE "(error|fatal|exception|failed|panic)" | tail -50
    
    cd ..
}

# 로그 통계 표시
show_log_stats() {
    local service=$1
    
    log_info "📊 Log statistics for $service service..."
    echo ""
    
    cd "$service"
    
    local total_lines
    total_lines=$(docker-compose logs --no-color | wc -l)
    
    local error_lines
    error_lines=$(docker-compose logs --no-color | grep -icE "(error|fatal|exception)" || echo "0")
    
    local warning_lines
    warning_lines=$(docker-compose logs --no-color | grep -icE "(warning|warn)" || echo "0")
    
    echo "📈 Log Statistics:"
    echo "  Total log lines: $total_lines"
    echo "  Error lines: $error_lines"
    echo "  Warning lines: $warning_lines"
    echo "  Success rate: $(echo "scale=2; ($total_lines - $error_lines) * 100 / $total_lines" | bc -l)%"
    
    echo ""
    echo "🔍 Recent log levels:"
    docker-compose logs --tail 100 --no-color | grep -oiE "(info|debug|warn|error|fatal)" | sort | uniq -c | sort -nr
    
    cd ..
}

# 실시간 로그 모니터링 (고급)
monitor_logs() {
    local service=$1
    
    log_info "📡 Real-time log monitoring for $service (Press Ctrl+C to stop)..."
    echo ""
    
    cd "$service"
    
    # 실시간 로그를 색상으로 구분하여 표시
    docker-compose logs -f --no-color | while read line; do
        case "$line" in
            *ERROR*|*FATAL*|*Exception*)
                echo -e "${RED}$line${NC}"
                ;;
            *WARN*|*WARNING*)
                echo -e "${YELLOW}$line${NC}"
                ;;
            *INFO*)
                echo -e "${BLUE}$line${NC}"
                ;;
            *DEBUG*)
                echo -e "${CYAN}$line${NC}"
                ;;
            *)
                echo "$line"
                ;;
        esac
    done
    
    cd ..
}

# 메인 함수
main() {
    log_info "📋 Infrastructure Logs Viewer"
    log_info "📁 Working directory: $(pwd)"
    echo ""
    
    # 현재 디렉토리가 infra-app인지 확인
    if [[ ! "$(basename $(pwd))" == "infra-app" ]]; then
        log_error "Please run this script from the infra-app directory"
        exit 1
    fi
    
    # 서비스별 처리
    case "$SERVICE_NAME" in
        "all")
            show_all_logs
            ;;
        "security"|"gateway"|"monitoring"|"logging"|"cache"|"tracing"|"service-discovery"|"dns"|"messaging"|"registry")
            # 추가 옵션 확인
            if [ "$FOLLOW" = true ] && command -v tput >/dev/null; then
                # 터미널 크기에 따른 모니터링 모드
                monitor_logs "$SERVICE_NAME"
            else
                show_service_logs "$SERVICE_NAME" "$SERVICE_NAME"
            fi
            ;;
        *)
            # 컨테이너 이름으로 시도
            if docker ps --format "{{.Names}}" | grep -q "$SERVICE_NAME"; then
                show_container_logs "$SERVICE_NAME"
            else
                log_error "Unknown service or container: $SERVICE_NAME"
                echo ""
                usage
                exit 1
            fi
            ;;
    esac
    
    # 추가 작업 제안
    if [ "$FOLLOW" = false ] && [ "$SERVICE_NAME" != "all" ]; then
        echo ""
        log_info "💡 Additional options:"
        echo "  View errors only: $0 $SERVICE_NAME --tail 100 | grep -i error"
        echo "  Follow logs: $0 $SERVICE_NAME --follow"
        echo "  Recent logs: $0 $SERVICE_NAME --since 1h"
        echo "  Search logs: docker-compose logs | grep 'search-term'"
    fi
}

# 인터럽트 시그널 처리 (follow 모드용)
trap 'echo ""; log_info "Log viewing stopped"; exit 0' INT

# 메인 함수 실행
main "$@"
