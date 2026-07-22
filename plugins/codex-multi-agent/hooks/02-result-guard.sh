#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(printf '%s' "$INPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("tool_name",""))' 2>/dev/null || true)
TEXT=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
d=json.load(sys.stdin)
for key in ("tool_result", "result", "output"):
    if key in d:
        print(d[key] if isinstance(d[key], str) else json.dumps(d[key], ensure_ascii=False))
        break
' 2>/dev/null || true)

LEN=${#TEXT}
HAS_HANDOFF=0
if printf '%s' "$TEXT" | grep -Eiq '##[[:space:]]*(Handoff|交接报告|恢复报告)|"handoff"[[:space:]]*:'; then
  HAS_HANDOFF=1
fi

HAS_RAW_EVENTS=0
if printf '%s' "$TEXT" | grep -Eq '"eventsTail"|"rawResult"|stream-json|"type"[[:space:]]*:[[:space:]]*"assistant"|"type"[[:space:]]*:[[:space:]]*"system"'; then
  HAS_RAW_EVENTS=1
fi

if [ "$LEN" -gt 12000 ] || [ "$HAS_RAW_EVENTS" -eq 1 ] || [ "$HAS_HANDOFF" -eq 0 ]; then
  cat >&2 <<EOF
[codex-multi-agent] $TOOL_NAME 返回结果需要压缩后再进入主线程。
问题:
$([ "$LEN" -gt 12000 ] && echo "  - 输出过长: ${LEN} chars")
$([ "$HAS_RAW_EVENTS" -eq 1 ] && echo "  - 检测到 raw events/rawResult/stream-json")
$([ "$HAS_HANDOFF" -eq 0 ] && echo "  - 未检测到 Handoff/交接摘要")

处理要求:
1. 只抽取 Handoff、关键失败摘要、修改文件、验证结果。
2. 不要继续分析全文 JSON、全文日志、全文 diff 或全文 events。
3. Claude delegate 优先调用 claude_summary 或 claude_result(includeRaw:false)。
4. 如 agent 失败，派 recovery-agent 或由主线程接手，不要重复拉 raw tail。
EOF
  exit 2
fi

exit 0
