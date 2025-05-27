#!/bin/bash

# 전체 인프라 서비스 상태 확인 스크립트
# 사용법: ./scripts/status.sh [--containers] [--resources] [--ports]

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 옵션 파라미터
SHOW_CONTAINERS=true
SHOW_RESOURCES=false
SHOW_PORTS=false

# 파라미터 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        --containers)
            SHOW_CONTAINERS=true
            shift
            ;;
        --resources)
            SHOW_RESOURCES=true
            shift
            ;;
        --ports)
            SHOW_PORTS=true
            shift
            ;;
        --all)
            SHOW_CONTAINERS=true
            SHOW_RESOURCES=true
            SHOW_PORTS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--containers] [--resources] [--ports] [--all]"
            exit 1
            ;;
    esac
done

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

# 헤더 출력 함수
print_header() {
    echo -e "${CYAN}$1${NC}"
    echo "=================================================================="
}

# 컨테이너 상태 확인 함수
show_container_status() {
    print_header "🐳 Docker Container Status"
    
    # 인프라 관련 컨테이너만 필터링
    local infra_containers=$(docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(keycloak|vault|kong|prometheus|grafana|redis|consul|coredns|kafka|elasticsearch|kibana|jaeger|harbor)" || true)
    
    if [ -z "$infra_containers" ]; then
        log_warning "No infrastructure containers found"
        echo ""
        log_info "💡 Start all services with: ./scripts/start-all.sh"
    else
        echo "$infra_containers"
    fi
    
    echo ""
    
    # 실행 중인 컨테이너 수 계산
    local running_count=$(docker ps --format "{{.Names}}" | grep -E "(keycloak|vault|kong|prometheus|grafana|redis|consul|coredns|kafka|elasticsearch|kibana|jaeger|harbor)" | wc -l || echo "0")
    local total_count=$(docker ps -a --format "{{.Names}}" | grep -E "(keycloak|vault|kong|prometheus|grafana|redis|consul|coredns|kafka|elasticsearch|kibana|jaeger|harbor)" | wc -l || echo "0")
    
    if [ "$running_count" -eq "$total_count" ] && [ "$total_count" -gt 0 ]; then
        log_success "All infrastructure containers are running ($running_count/$total_count)"
    elif [ "$running_count" -gt 0 ]; then
        log_warning "Some containers are not running ($running_count/$total_count)"
    else
        log_error "No infrastructure containers are running"
    fi
    
    echo ""
}

# 서비스별 상태 확인
show_service_status() {
    print_header "🔧 Service Status by Category"
    
    # 보안 서비스
    echo -e "${PURPLE}🔐 Security Services:${NC}"
    check_service_container "keycloak" "Keycloak Authentication" "http://localhost:10900"
    check_service_container "vault" "HashiCorp Vault" "http://localhost:10902"
    echo ""
    
    # 게이트웨이 & 네트워킹
    echo -e "${PURPLE}🌐 Gateway & Networking:${NC}"
    check_service_container "kong" "Kong API Gateway" "http://localhost:10300"
    check_service_container "consul" "Consul Service Discovery" "http://localhost:10502"
    check_service_container "coredns" "CoreDNS" "udp://localhost:10600"
    echo ""
    
    # 모니터링 & 관측성
    echo -e "${PURPLE}📊 Monitoring & Observability:${NC}"
    check_service_container "prometheus" "Prometheus" "http://localhost:10000"
    check_service_container "grafana" "Grafana" "http://localhost:10001"
    check_service_container "kibana" "Kibana" "http://localhost:10102"
    check_service_container "jaeger" "Jaeger UI" "http://localhost:10400"
    echo ""
    
    # 데이터 & 메시징
    echo -e "${PURPLE}🚀 Data & Messaging:${NC}"
    check_service_container "redis" "Redis Cache" "tcp://localhost:10200"
    check_service_container "kafka" "Apache Kafka" "tcp://localhost:10700"
    check_service_container "harbor" "Harbor Registry" "http://localhost:10800"
    echo ""
}

# 개별 서비스 컨테이너 상태 확인
check_service_container() {
    local container_pattern=$1
    local service_name=$2
    local endpoint=$3
    
    local containers=$(docker ps --format "{{.Names}}" | grep "$container_pattern" || true)
    local container_count=$(echo "$containers" | grep -v '^$' | wc -l || echo "0")
    
    if [ "$container_count" -gt 0 ]; then
        log_success "$service_name: $container_count container(s) running - $endpoint"
        if [ "$container_count" -gt 1 ]; then
            echo "    Containers: $(echo "$containers" | tr '\n' ', ' | sed 's/,$//')"
        fi
    else
        log_error "$service_name: No containers running - $endpoint"
    fi
}

# 리소스 사용량 확인
show_resource_usage() {
    print_header "💻 Resource Usage"
    
    # Docker 전체 리소스 사용량
    echo -e "${PURPLE}Docker System Resources:${NC}"
    docker system df
    echo ""
    
    # 컨테이너별 리소스 사용량
    echo -e "${PURPLE}Container Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | head -20
    echo ""
    
    # 시스템 리소스
    echo -e "${PURPLE}System Resources:${NC}"
    echo "CPU Usage:"
    top -l 1 -n 0 | grep "CPU usage" || echo "CPU info not available"
    echo ""
    
    echo "Memory Usage:"
    if command -v free >/dev/null 2>&1; then
        free -h
    else
        # macOS 대안
        echo "Memory Pressure:"
        memory_pressure=$(memory_pressure 2>/dev/null || echo "normal")
        echo "  Status: $memory_pressure"
        
        vm_stat | grep -E "(Pages free|Pages active|Pages inactive|Pages speculative|Pages wired down)" | while read line; do
            echo "  $line"
        done
    fi
    echo ""
    
    echo "Disk Usage:"
    df -h / | tail -1
    echo ""
}

# 포트 사용 현황 확인
show_port_status() {
    print_header "🌐 Port Usage Status"
    
    # 인프라 포트 목록
    local ports=(
        "10000:Prometheus"
        "10001:Grafana" 
        "10002:AlertManager"
        "10100:Elasticsearch"
        "10101:Logstash"
        "10102:Kibana"
        "10103:Filebeat"
        "10104:Metricbeat"
        "10200:Redis Master"
        "10201:Redis Replica"
        "10202:Redis Sentinel"
        "10300:Kong Gateway"
        "10301:Kong Admin"
        "10302:Kong DB"
        "10400:Jaeger UI"
        "10401:Jaeger Collector"
        "10402:Jaeger Query"
        "10403:OTEL Collector"
        "10404:Jaeger ES"
        "10500:Consul Server"
        "10501:Consul Client"
        "10502:Consul UI"
        "10600:CoreDNS"
        "10601:DNS Metrics"
        "10700:Kafka Broker 1"
        "10701:Kafka Broker 2"
        "10702:Kafka Broker 3"
        "10703:Kafka UI"
        "10704:Schema Registry"
        "10800:Harbor UI"
        "10801:Harbor DB"
        "10802:Harbor Redis"
        "10803:Notary"
        "10900:Keycloak"
        "10901:Keycloak DB"
        "10902:Vault"
        "10903:Vault UI"
    )
    
    printf "%-6s %-20s %-8s %-15s\n" "PORT" "SERVICE" "STATUS" "PROCESS"
    echo "=================================================================="
    
    for port_info in "${ports[@]}"; do
        IFS=':' read -r port service <<< "$port_info"
        
        if lsof -i :$port > /dev/null 2>&1; then
            local process=$(lsof -ti :$port | head -1)
            local process_name=$(ps -p $process -o comm= 2>/dev/null || echo "unknown")
            printf "%-6s %-20s %-8s %-15s\n" "$port" "$service" "🟢 USED" "$process_name"
        else
            printf "%-6s %-20s %-8s %-15s\n" "$port" "$service" "🔴 FREE" "-"
        fi
    done
    
    echo ""
    
    # 사용 중인 포트 통계
    local used_ports=0
    local total_ports=${#ports[@]}
    
    for port_info in "${ports[@]}"; do
        IFS=':' read -r port service <<< "$port_info"
        if lsof -i :$port > /dev/null 2>&1; then
            ((used_ports++))
        fi
    done
    
    echo "Port Usage Summary: $used_ports/$total_ports ports in use"
    echo ""
}

# 서비스 URL 정보
show_service_urls() {
    print_header "🔗 Service Access URLs"
    
    printf "%-25s %-35s %-15s\n" "SERVICE" "URL" "CREDENTIALS"
    echo "=================================================================="
    printf "%-25s %-35s %-15s\n" "Keycloak Admin" "http://localhost:10900/auth/admin/" "admin/admin123"
    printf "%-25s %-35s %-15s\n" "Vault UI" "http://localhost:10902/ui/" "Token: vault-root-token"
    printf "%-25s %-35s %-15s\n" "Kong Admin API" "http://localhost:10301/" "-"
    printf "%-25s %-35s %-15s\n" "Consul UI" "http://localhost:10502/ui/" "-"
    printf "%-25s %-35s %-15s\n" "Prometheus" "http://localhost:10000/" "-"
    printf "%-25s %-35s %-15s\n" "Grafana" "http://localhost:10001/" "admin/admin_password"
    printf "%-25s %-35s %-15s\n" "Kibana" "http://localhost:10102/" "-"
    printf "%-25s %-35s %-15s\n" "Jaeger UI" "http://localhost:10400/" "-"
    printf "%-25s %-35s %-15s\n" "Kafka UI" "http://localhost:10703/" "-"
    printf "%-25s %-35s %-15s\n" "Harbor Registry" "http://localhost:10800/" "admin/Harbor12345"
    echo ""
}

# 도커 네트워크 정보
show_network_info() {
    print_header "🌐 Docker Networks"
    
    # 인프라 관련 네트워크만 표시
    docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" | grep -E "(infra|security|monitoring|logging|cache|gateway|tracing|messaging|registry)" || echo "No infrastructure networks found"
    echo ""
    
    # 네트워크 상세 정보 (첫 번째 인프라 네트워크)
    local first_network=$(docker network ls --format "{{.Name}}" | grep -E "(infra|security|monitoring)" | head -1)
    if [ ! -z "$first_network" ]; then
        echo "Sample Network Details ($first_network):"
        docker network inspect $first_network --format '{{json .}}' | jq -r '.IPAM.Config[0].Subnet // "N/A"' | sed 's/^/  Subnet: /'
        echo ""
    fi
}

# 볼륨 정보
show_volume_info() {
    print_header "💾 Docker Volumes"
    
    # 인프라 관련 볼륨만 표시
    docker volume ls --format "table {{.Name}}\t{{.Driver}}" | grep -E "(infra|security|monitoring|logging|cache|gateway|tracing|messaging|registry|keycloak|vault|prometheus|grafana|redis|consul|elasticsearch|kibana|jaeger|kafka|harbor)" || echo "No infrastructure volumes found"
    echo ""
}

# 메인 함수
main() {
    log_info "📊 Infrastructure Status Check"
    log_info "📁 Working directory: $(pwd)"
    log_info "🕐 Timestamp: $(date)"
    echo ""
    
    # 현재 디렉토리가 infra-app인지 확인
    if [[ ! "$(basename $(pwd))" == "infra-app" ]]; then
        log_warning "Not in infra-app directory, but continuing status check..."
        echo ""
    fi
    
    # 컨테이너 상태 (기본값)
    if [ "$SHOW_CONTAINERS" = true ]; then
        show_container_status
        show_service_status
    fi
    
    # 서비스 URL 정보 (항상 표시)
    show_service_urls
    
    # 리소스 사용량
    if [ "$SHOW_RESOURCES" = true ]; then
        show_resource_usage
    fi
    
    # 포트 상태
    if [ "$SHOW_PORTS" = true ]; then
        show_port_status
    fi
    
    # 네트워크 및 볼륨 정보 (추가 옵션)
    if [ "$SHOW_RESOURCES" = true ]; then
        show_network_info
        show_volume_info
    fi
    
    # 유용한 명령어 팁
    print_header "💡 Useful Commands"
    echo "Health Check:     ./scripts/health-check.sh"
    echo "Start All:        ./scripts/start-all.sh"
    echo "Stop All:         ./scripts/stop-all.sh"
    echo "View Logs:        docker-compose -f [service]/docker-compose.yml logs -f"
    echo "Restart Service:  cd [service] && docker-compose restart"
    echo "System Cleanup:   docker system prune -f"
    echo ""
    
    log_info "Status check completed"
}

# 인터럽트 시그널 처리
trap 'log_error "Status check interrupted by user"; exit 1' INT

# 메인 함수 실행
main "$@"
