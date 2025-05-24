#!/bin/bash

# 중복 파일 및 폴더 정리 스크립트
echo "🧹 중복 파일 및 폴더 정리를 시작합니다..."

# 스크립트 실행 위치 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$BASE_DIR"

# gateway 폴더 내 불필요한 항목 삭제
echo ""
echo "📁 Gateway 폴더 정리 중..."

# monitoring 폴더 삭제
if [ -d "gateway/monitoring" ]; then
    echo "  - gateway/monitoring 폴더 삭제 중..."
    rm -rf gateway/monitoring
    echo "  ✅ monitoring 폴더 삭제 완료"
fi

# 중복 mcp_rule.md 파일 삭제
if [ -f "gateway/mcp_rule.md" ]; then
    echo "  - gateway/mcp_rule.md 파일 삭제 중..."
    rm -f gateway/mcp_rule.md
    echo "  ✅ mcp_rule.md 파일 삭제 완료"
fi

# MONITORING_TOOLS.md 파일 삭제
if [ -f "gateway/MONITORING_TOOLS.md" ]; then
    echo "  - gateway/MONITORING_TOOLS.md 파일 삭제 중..."
    rm -f gateway/MONITORING_TOOLS.md
    echo "  ✅ MONITORING_TOOLS.md 파일 삭제 완료"
fi

echo ""
echo "🎉 중복 파일 및 폴더 정리가 완료되었습니다!"
echo ""
echo "📋 현재 gateway 폴더 구조:"
ls -la gateway/
