# Multi-Agent

面向 **Claude Code** 与 **Codex** 的多 Agent 自动编排插件——分析任务复杂度、智能路由到多 agent 协作、故障自愈与结构化交接。

## 与 Memory Pro 的区别：这里是「学说共享，实现平台隔离」

多 agent 插件**不是单一代码**。Claude 用 `Agent` 工具 + Markdown agent 定义 + prompt 型 hook；Codex 用 `spawn_agent` + TOML agent 定义 + shell hook。工具词汇、hook 机制、事件名两平台都不同——这是**平台必需的差异，不是重复**。

因此本仓分两层：

- **共享层**（[SHARED-DOCTRINE.md](SHARED-DOCTRINE.md)）：平台中立的编排学说——复杂度评分、角色分工、交接格式、停止条件、故障恢复。改这里两平台都适用。
- **平台隔离层**（`claude/` 与 `plugins/codex-multi-agent/`）：hook、工具名 matcher、agent 格式各写各的，**永不跨平台复制**。SHARED-DOCTRINE 里的映射表逐行锁死每个污染点，防止如「Codex 的 `wait_agent` matcher 搬到 Claude 导致 hook 静默失效」这类事故。

## 目录结构

```
multi-agent/
├── SHARED-DOCTRINE.md               # 共享编排学说 + 跨平台隔离映射表
├── claude/                          # Claude 平台（claude-autoagent）
│   ├── .claude-plugin/plugin.json
│   ├── agents/*.md                  # supervisor / recovery / playwright-audit / i18n-auditor
│   ├── commands/*.md
│   └── hooks/auto-route-prompt.md   # UserPromptSubmit prompt hook 模板
├── .agents/plugins/marketplace.json # Codex marketplace 清单
└── plugins/codex-multi-agent/       # Codex 平台
    ├── .codex-plugin/plugin.json
    ├── agents/*.toml
    ├── hooks.json + hooks/*.sh       # 意图路由 / 结果守卫 / subagent-stop
    └── references/                   # claude-source 适配说明
```

## 安装

### Claude Code
```bash
cd claude && bash install.sh
```
或参照 `claude/hooks/auto-route-prompt.md` 把 `UserPromptSubmit` prompt hook 配置进 `~/.claude/settings.json`。

### Codex
从 `.agents/plugins/marketplace.json` 作为本地 marketplace 加载：
```bash
cd plugins/codex-multi-agent && node scripts/install-local.mjs
```

## 维护规则
改编排概念 → 更新 SHARED-DOCTRINE，两平台一致。改 hook / 工具名 / agent 格式 → 只改当前平台，另一平台按映射表写**对应但不同**的实现，禁止复制粘贴。

## License
MIT
