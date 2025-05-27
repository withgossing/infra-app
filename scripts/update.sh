    echo "  • Create backup: ./scripts/backup.sh --compress"
    echo ""
}

# 인터럽트 시그널 처리
trap 'log_error "Update process interrupted by user"; exit 1' INT

# 메인 함수 실행
main "$@"
