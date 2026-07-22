#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
TEXT=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
d=json.load(sys.stdin)
print(json.dumps(d, ensure_ascii=False))
' 2>/dev/null || true)

if printf '%s' "$TEXT" | grep -Eiq 'failed|error|timeout|blocked|incomplete|无结果|失败|超时'; then
  cat >&2 <<'EOF'
[codex-multi-agent] 检测到子 agent 异常/阻塞信号。
→ 先恢复已有部分结果并整理为 Handoff。
→ 只重试失败阶段，最多 2 次。
→ 仍失败时由主线程接手，或派 recovery-agent 诊断。
EOF
  exit 2
fi

exit 0
