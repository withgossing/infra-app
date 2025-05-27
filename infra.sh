#!/bin/bash

# 인프라 관리 마스터 스크립트
# 사용법: ./infra.sh [command] [options]

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 스크립트 디렉토리
SCRIPT_DIR="./scripts"

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

# 헤더 출력
print_header() {
    echo -e "${CYAN}${BOLD}"
    echo "=================================================================="
    echo "           🏗️  Infrastructure Management Console"
    echo "=================================================================="
    echo -e "${NC}"
    echo ""
}

# 사용법 출력
usage() {
    print_header
    
    echo -e "${BOLD}Usage:${NC} $0 [command] [options]"
    echo ""
    
    echo -e "${PURPLE}📋 Main Commands:${NC}"
    echo "  start         Start all infrastructure services"
    echo "  stop          Stop all infrastructure services"
    echo "  restart       Restart all infrastructure services"
    echo "  status        Show current status of all services"
    echo "  health        Run comprehensive health check"
    echo "  logs          View service logs"
    echo ""
    
    echo -e "${PURPLE}🔧 Management Commands:${NC}"
    echo "  backup        Create infrastructure backup"
    echo "  update        Update services to latest versions"
    echo "  cleanup       Clean up unused Docker resources"
    echo "  reset         Reset all services (DANGEROUS)"
    echo ""
    
    echo -e "${PURPLE}🌐 Quick Access:${NC}"
    echo "  ui            Open all web UIs in browser"
    echo "  urls          Show all service URLs and credentials"
    echo "  ports         Show port allocation status"
    echo ""
    
    echo -e "${PURPLE}📊 Monitoring:${NC}"
    echo "  monitor       Real-time monitoring dashboard"
    echo "  resources     Show resource usage"
    echo "  metrics       Show system metrics"
    echo ""
    
    echo -e "${BOLD}Examples:${NC}"
    echo "  $0 start                    # Start all services"
    echo "  $0 status --detailed        # Detailed status check"
    echo "  $0 logs security --follow   # Follow security service logs"
    echo "  $0 backup --compress        # Create compressed backup"
    echo "  $0 health --json           # JSON health report"
    echo ""
    
    echo -e "${BOLD}Service Names:${NC}"
    echo "  security, gateway, monitoring, logging, cache, tracing"
    echo "  service-discovery, dns, messaging, registry"
    echo ""
}

# 스크립트 존재 여부 확인
check_script() {
    local script_name=$1
    local script_path="$SCRIPT_DIR/$script_name"
    
    if [ ! -f "$script_path" ]; then
        log_error "Script not found: $script_path"
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        log_warning "Making script executable: $script_path"
        chmod +x "$script_path"
    fi
    
    return 0
}

# 모든 스크립트 실행 권한 설정
setup_scripts() {
    log_info "Setting up scripts..."
    
    if [ ! -d "$SCRIPT_DIR" ]; then
        log_error "Scripts directory not found: $SCRIPT_DIR"
        return 1
    fi
    
    # 모든 .sh 파일에 실행 권한 부여
    find "$SCRIPT_DIR" -name "*.sh" -exec chmod +x {} \;
    
    # 보안 스크립트들도 실행 권한 부여
    if [ -d "security/scripts" ]; then
        find "security/scripts" -name "*.sh" -exec chmod +x {} \;
    fi
    
    log_success "Scripts setup completed"
}

# 서비스 시작
cmd_start() {
    print_header
    log_info "🚀 Starting all infrastructure services..."
    
    if check_script "start-all.sh"; then
        "$SCRIPT_DIR/start-all.sh" "$@"
    fi
}

# 서비스 중지
cmd_stop() {
    print_header
    log_info "🛑 Stopping all infrastructure services..."
    
    if check_script "stop-all.sh"; then
        "$SCRIPT_DIR/stop-all.sh" "$@"
    fi
}

# 서비스 재시작
cmd_restart() {
    print_header
    log_info "🔄 Restarting all infrastructure services..."
    
    if check_script "stop-all.sh" && check_script "start-all.sh"; then
        "$SCRIPT_DIR/stop-all.sh"
        sleep 5
        "$SCRIPT_DIR/start-all.sh"
    fi
}

# 상태 확인
cmd_status() {
    print_header
    log_info "📊 Checking infrastructure status..."
    
    if check_script "status.sh"; then
        "$SCRIPT_DIR/status.sh" "$@"
    fi
}

# 헬스체크
cmd_health() {
    print_header
    log_info "🏥 Running infrastructure health check..."
    
    if check_script "health-check.sh"; then
        "$SCRIPT_DIR/health-check.sh" "$@"
    fi
}

# 로그 확인
cmd_logs() {
    if check_script "logs.sh"; then
        "$SCRIPT_DIR/logs.sh" "$@"
    fi
}

# 백업
cmd_backup() {
    print_header
    log_info "💾 Creating infrastructure backup..."
    
    if check_script "backup.sh"; then
        "$SCRIPT_DIR/backup.sh" "$@"
    fi
}

# 업데이트
cmd_update() {
    print_header
    log_info "🔄 Checking for infrastructure updates..."
    
    if check_script "update.sh"; then
        "$SCRIPT_DIR/update.sh" "$@"
    fi
}

# 웹 UI 열기
cmd_ui() {
    print_header
    log_info "🌐 Opening web UIs in browser..."
    
    local urls=(
        "http://localhost:10900"  # Keycloak
        "http://localhost:10902"  # Vault
        "http://localhost:10001"  # Grafana
        "http://localhost:10102"  # Kibana
        "http://localhost:10400"  # Jaeger
        "http://localhost:10502"  # Consul
        "http://localhost:10703"  # Kafka UI
        "http://localhost:10800"  # Harbor
    )
    
    for url in "${urls[@]}"; do
        log_info "Opening: $url"
        if command -v open >/dev/null 2>&1; then
            open "$url" 2>/dev/null &
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$url" 2>/dev/null &
        else
            echo "  $url"
        fi
        sleep 1
    done
    
    log_success "Web UIs opened (if browser available)"
}

# URL 및 자격 증명 표시
cmd_urls() {
    print_header
    log_info "🔗 Service URLs and Credentials"
    echo ""
    
    printf "%-25s %-35s %-20s\n" "SERVICE" "URL" "CREDENTIALS"
    echo "================================================================================"
    printf "%-25s %-35s %-20s\n" "Keycloak Admin" "http://localhost:10900/auth/admin/" "admin/admin123"
    printf "%-25s %-35s %-20s\n" "Vault UI" "http://localhost:10902/ui/" "Token: vault-root-token"
    printf "%-25s %-35s %-20s\n" "Kong Admin API" "http://localhost:10301/" "-"
    printf "%-25s %-35s %-20s\n" "Consul UI" "http://localhost:10502/ui/" "-"
    printf "%-25s %-35s %-20s\n" "Prometheus" "http://localhost:10000/" "-"
    printf "%-25s %-35s %-20s\n" "Grafana" "http://localhost:10001/" "admin/admin_password"
    printf "%-25s %-35s %-20s\n" "Kibana" "http://localhost:10102/" "-"
    printf "%-25s %-35s %-20s\n" "Jaeger UI" "http://localhost:10400/" "-"
    printf "%-25s %-35s %-20s\n" "Kafka UI" "http://localhost:10703/" "-"
    printf "%-25s %-35s %-20s\n" "Harbor Registry" "http://localhost:10800/" "admin/Harbor12345"
    echo ""
}

# 포트 상태 표시
cmd_ports() {
    print_header
    
    if check_script "status.sh"; then
        "$SCRIPT_DIR/status.sh" --ports
    fi
}

# 리소스 사용량 표시
cmd_resources() {
    print_header
    
    if check_script "status.sh"; then
        "$SCRIPT_DIR/status.sh" --resources
    fi
}

# Docker 정리
cmd_cleanup() {
    print_header
    log_info "🧹 Cleaning up Docker resources..."
    
    echo ""
    log_warning "This will remove:"
    echo "  • Stopped containers"
    echo "  • Unused networks"
    echo "  • Dangling images"
    echo "  • Build cache"
    echo ""
    
    read -p "Continue? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled"
        return
    fi
    
    log_info "Removing stopped containers..."
    docker container prune -f
    
    log_info "Removing unused networks..."
    docker network prune -f
    
    log_info "Removing dangling images..."
    docker image prune -f
    
    log_info "Removing build cache..."
    docker builder prune -f
    
    log_success "Docker cleanup completed"
    
    # 정리 후 통계 표시
    echo ""
    log_info "Docker system usage after cleanup:"
    docker system df
}

# 전체 리셋 (위험)
cmd_reset() {
    print_header
    log_error "⚠️  DANGER: This will completely reset all infrastructure!"
    echo ""
    
    log_warning "This will:"
    echo "  • Stop all services"
    echo "  • Remove all containers"
    echo "  • Delete all volumes (ALL DATA WILL BE LOST)"
    echo "  • Remove all networks"
    echo "  • Clean all Docker resources"
    echo ""
    
    log_error "THIS ACTION IS IRREVERSIBLE!"
    echo ""
    
    read -p "Type 'RESET' to confirm: " -r
    if [[ $REPLY != "RESET" ]]; then
        log_info "Reset cancelled"
        return
    fi
    
    log_info "Creating emergency backup before reset..."
    if check_script "backup.sh"; then
        "$SCRIPT_DIR/backup.sh" --compress --output-dir "./backups/emergency-$(date +%Y%m%d_%H%M%S)"
    fi
    
    log_info "Stopping all services..."
    if check_script "stop-all.sh"; then
        "$SCRIPT_DIR/stop-all.sh" --force
    fi
    
    log_info "Removing all infrastructure containers..."
    docker ps -a --format "{{.Names}}" | grep -E "(keycloak|vault|kong|prometheus|grafana|redis|consul|coredns|kafka|elasticsearch|kibana|jaeger|harbor)" | xargs -r docker rm -f
    
    log_info "Removing all infrastructure volumes..."
    docker volume ls --format "{{.Name}}" | grep -E "(infra|security|monitoring|logging|cache|gateway|tracing|messaging|registry)" | xargs -r docker volume rm -f
    
    log_info "Removing all infrastructure networks..."
    docker network ls --format "{{.Name}}" | grep -E "(infra|security|monitoring|logging|cache|gateway|tracing|messaging|registry)" | xargs -r docker network rm
    
    log_info "Final cleanup..."
    docker system prune -af --volumes
    
    log_success "Infrastructure reset completed"
    log_info "Use './infra.sh start' to rebuild infrastructure"
}

# 실시간 모니터링
cmd_monitor() {
    print_header
    log_info "📡 Starting real-time monitoring..."
    echo ""
    
    log_info "Opening monitoring dashboards..."
    
    # Grafana 대시보드 열기
    if command -v open >/dev/null 2>&1; then
        open "http://localhost:10001/d/system-overview" 2>/dev/null &
    fi
    
    # 실시간 상태 모니터링
    while true; do
        clear
        print_header
        
        echo -e "${BOLD}Real-time Infrastructure Monitoring${NC}"
        echo "Press Ctrl+C to exit"
        echo ""
        
        # 컨테이너 상태
        echo -e "${PURPLE}🐳 Container Status:${NC}"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(keycloak|vault|kong|prometheus|grafana|redis|consul|kafka|harbor)" | head -10
        echo ""
        
        # 리소스 사용량
        echo -e "${PURPLE}💻 Resource Usage:${NC}"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -8
        echo ""
        
        # 시스템 정보
        echo -e "${PURPLE}🖥️  System Info:${NC}"
        echo "  Load: $(uptime | awk '{print $10,$11,$12}' 2>/dev/null || echo 'N/A')"
        echo "  Memory: $(free -h 2>/dev/null | awk '/^Mem:/{print $3"/"$2}' || vm_stat | grep 'Pages active' | awk '{print $3}' | head -1)"
        echo "  Disk: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5" used)"}')"
        echo ""
        
        echo "Last updated: $(date)"
        
        sleep 5
    done
}

# 메트릭 표시
cmd_metrics() {
    print_header
    log_info "📊 Infrastructure Metrics"
    echo ""
    
    # 헬스체크 실행
    if check_script "health-check.sh"; then
        log_info "🏥 Health Status:"
        "$SCRIPT_DIR/health-check.sh" --json | jq -r '.health_percentage + "% healthy"' 2>/dev/null || echo "Health check not available"
        echo ""
    fi
    
    # 컨테이너 통계
    log_info "🐳 Container Statistics:"
    local total_containers=$(docker ps -a --format "{{.Names}}" | grep -E "(keycloak|vault|kong|prometheus|grafana|redis|consul|kafka|harbor)" | wc -l)
    local running_containers=$(docker ps --format "{{.Names}}" | grep -E "(keycloak|vault|kong|prometheus|grafana|redis|consul|kafka|harbor)" | wc -l)
    echo "  Total containers: $total_containers"
    echo "  Running containers: $running_containers"
    echo "  Container uptime: $(echo "scale=1; $running_containers * 100 / $total_containers" | bc -l)%"
    echo ""
    
    # 볼륨 사용량
    log_info "💾 Volume Usage:"
    docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}" | grep -E "(Volumes|Local Volumes)"
    echo ""
    
    # 네트워크 정보
    log_info "🌐 Network Information:"
    local network_count=$(docker network ls --format "{{.Name}}" | grep -E "(infra|security|monitoring)" | wc -l)
    echo "  Infrastructure networks: $network_count"
    echo ""
    
    # 포트 사용량
    log_info "🔌 Port Usage:"
    local used_ports=0
    local total_ports=44  # 10000-10999 범위의 인프라 포트들
    
    for port in {10000..10999}; do
        if lsof -i :$port > /dev/null 2>&1; then
            ((used_ports++))
        fi
    done
    
    echo "  Used ports: $used_ports/$total_ports"
    echo "  Port utilization: $(echo "scale=1; $used_ports * 100 / $total_ports" | bc -l)%"
}

# 환경 설정 확인
check_environment() {
    local errors=0
    
    # Docker 확인
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed"
        ((errors++))
    fi
    
    # Docker Compose 확인
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "Docker Compose is not installed"
        ((errors++))
    fi
    
    # 디렉토리 확인
    if [[ ! "$(basename $(pwd))" == "infra-app" ]]; then
        log_error "Please run this script from the infra-app directory"
        ((errors++))
    fi
    
    # 필수 유틸리티 확인
    for cmd in curl jq bc; do
        if ! command -v $cmd >/dev/null 2>&1; then
            log_warning "$cmd is not installed (some features may not work)"
        fi
    done
    
    return $errors
}

# 메인 함수
main() {
    # 환경 확인
    if ! check_environment; then
        exit 1
    fi
    
    # 스크립트 설정
    setup_scripts
    
    # 명령어가 없으면 사용법 표시
    if [ $# -eq 0 ]; then
        usage
        exit 0
    fi
    
    # 명령어 처리
    local command=$1
    shift
    
    case $command in
        "start")
            cmd_start "$@"
            ;;
        "stop")
            cmd_stop "$@"
            ;;
        "restart")
            cmd_restart "$@"
            ;;
        "status")
            cmd_status "$@"
            ;;
        "health")
            cmd_health "$@"
            ;;
        "logs")
            cmd_logs "$@"
            ;;
        "backup")
            cmd_backup "$@"
            ;;
        "update")
            cmd_update "$@"
            ;;
        "ui")
            cmd_ui "$@"
            ;;
        "urls")
            cmd_urls "$@"
            ;;
        "ports")
            cmd_ports "$@"
            ;;
        "resources")
            cmd_resources "$@"
            ;;
        "cleanup")
            cmd_cleanup "$@"
            ;;
        "reset")
            cmd_reset "$@"
            ;;
        "monitor")
            cmd_monitor "$@"
            ;;
        "metrics")
            cmd_metrics "$@"
            ;;
        "help"|"-h"|"--help")
            usage
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            usage
            exit 1
            ;;
    esac
}

# 인터럽트 시그널 처리
trap 'echo ""; log_info "Operation cancelled by user"; exit 0' INT

# 메인 함수 실행
main "$@"
