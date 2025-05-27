# Consul 클라이언트 설정
datacenter = "dc1"
data_dir = "/consul/data"
log_level = "INFO"
node_name = "consul-client"
server = false

# 서버 연결 설정
retry_join = ["consul-server-1", "consul-server-2", "consul-server-3"]

# 바인딩 설정
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"

# 포트 설정
ports {
  grpc = 8502
  grpc_tls = 8503
}

# Connect (Service Mesh) 활성화
connect {
  enabled = true
}

# 로그 설정
enable_syslog = false
log_rotate_duration = "24h"
log_rotate_max_files = 7

# 보안 설정
verify_incoming = false
verify_outgoing = false

# ACL 설정 (기본값: 비활성화)
acl = {
  enabled = false
  default_policy = "allow"
  enable_token_persistence = true
}

# 서비스 디스커버리 설정
services {
  name = "consul-client"
  tags = ["client", "discovery"]
  port = 8500
  check {
    http = "http://localhost:8500/v1/status/leader"
    interval = "10s"
    timeout = "3s"
  }
}

# 헬스체크 설정
check_update_interval = "5m"
