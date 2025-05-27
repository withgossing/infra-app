# Consul 서버 설정
datacenter = "dc1"
data_dir = "/consul/data"
log_level = "INFO"
node_name = "consul-server"
server = true

# 클러스터 설정
bootstrap_expect = 3
retry_join = ["consul-server-1", "consul-server-2", "consul-server-3"]

# 바인딩 설정
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"

# UI 활성화
ui_config {
  enabled = true
}

# 포트 설정
ports {
  grpc = 8502
  grpc_tls = 8503
}

# Connect (Service Mesh) 활성화
connect {
  enabled = true
}

# 성능 설정
performance {
  raft_multiplier = 1
}

# 로그 설정
enable_syslog = false
log_rotate_duration = "24h"
log_rotate_max_files = 7

# 보안 설정
verify_incoming = false
verify_outgoing = false
verify_server_hostname = false

# ACL 설정 (기본값: 비활성화)
acl = {
  enabled = false
  default_policy = "allow"
  enable_token_persistence = true
}

# 자동 백업 설정
autopilot {
  cleanup_dead_servers = true
  last_contact_threshold = "200ms"
  max_trailing_logs = 250
  server_stabilization_time = "10s"
}

# 헬스체크 설정
check_update_interval = "5m"
