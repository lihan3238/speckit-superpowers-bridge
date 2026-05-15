[English](README.md)

# speckit-superpowers-bridge

Spec Kit + Superpowers Bridge 是一个轻量融合协议：Spec Kit 继续作为 constitution、spec、plan、tasks、checklists 和 analyze 的事实源；Superpowers 只负责实现阶段的工程纪律。

## overview

这不是另一个“大而全”的 Superpowers 工作流替代品。bridge 刻意避免重复两边能力：

- Spec Kit 负责设计契约。
- Superpowers 负责 TDD、debug、执行、review、verification 和 branch finishing。
- `tasks.md` 是唯一实现契约。
- guard、handoff、audit 和 rollback 状态保证两套系统不重叠、不缺失。
- 包体保持 repo-local 且很小：一个 Spec Kit extension、一对 bridge skill、一个 handoff JSON、一个 JSONL 事件日志，以及 rollback snapshots。没有服务、数据库、daemon，也不修改全局 Superpowers 插件。

## installation

Marketplace release 安装：

```powershell
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.1.1/speckit-superpowers-bridge-v0.1.1.zip
```

本地开发安装：

```powershell
specify extension add --dev .\.specify\extensions\speckit-superpowers-bridge
```

安装后运行 install-state audit：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\audit-install-state.ps1 -Json
```

## quick-usage-example

### 0. Install once

从一个 Spec Kit 项目开始，安装一个或两个 agent integration：

```powershell
specify init . --integration codex
specify integration install claude
specify integration use codex
```

安装 bridge 后验证本地状态：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\audit-install-state.ps1 -Json
```

### 1. Pick the Spec Kit writer

每个 feature 同一时间只允许一个 agent 写 Spec Kit 控制产物。另一个 agent 只能 review。

- Codex 命令风格：`$speckit-specify`、`$speckit-plan`、`$speckit-tasks`
- Claude Code 命令风格：`/speckit-specify`、`/speckit-plan`、`/speckit-tasks`

### 2. Create the Spec Kit artifacts

当项目治理是新的或需要变更时，先运行 constitution；然后用选定 writer 跑标准 Spec Kit 设计流程：

```text
$speckit-constitution
$speckit-specify "描述要构建的功能"
$speckit-clarify
$speckit-checklist
$speckit-plan
$speckit-tasks
$speckit-analyze
```

Claude Code 使用同名 slash 命令，例如 `/speckit-specify`。

### 3. Hand off implementation

`after_tasks` hook 应创建 `.specify/superpowers-handoff.json`。需要手动刷新时：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready -Actor codex
```

如果 Claude Code 负责执行，使用 `-Actor claude`。只有明确想要长时间无人值守执行时才开启 autonomous mode：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready -AutonomousMode $true -Actor codex
```

### 4. Execute with Superpowers

调用 marketplace 合规的 execute 命令，而不是 `speckit.implement`：

```text
$speckit-speckit-superpowers-bridge-execute
```

Claude Code 使用 `/speckit-speckit-superpowers-bridge-execute`。

生成的 execute 命令就是 marketplace 安装后的 bridge 执行入口。它会先读取 `constitution.md`、`spec.md`、`plan.md` 和 `tasks.md`，再用 Superpowers 的工程纪律执行 `tasks.md`：TDD、debug、review、verification 和 branch finishing。执行过程中会更新任务勾选和 handoff 状态。在本源码仓库中，`.agents/skills/speckit-superpowers-bridge` 和 `.claude/skills/speckit-superpowers-bridge` 是同一协议的本地开发镜像。

### 5. Handle requirement gaps

如果实现时发现需求缺失或设计错误，停止编码并把 handoff 标记为 blocked：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status blocked -Reason "Spec Kit artifact needs revision" -Actor codex
```

回到 Spec Kit 修订 `spec.md`、`plan.md` 或 `tasks.md`，再创建新的 ready handoff 并恢复 bridge 执行。

### 6. Verify and finish

确认 feature 完成前运行：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\validation-pass.ps1 -Json -Actor codex
```

只有任务完成且验证通过后，bridge 才会把 handoff 标记为 `complete`。开始下一个 feature 时，`before_specify` hook 会自动归档已完成 handoff；也可以手动运行：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\auto-archive-handoff.ps1 -Actor codex
```

### 7. Guardrails

- handoff executor 是 `superpowers` 时，不要运行 `speckit.implement`。
- 不要用 Superpowers `brainstorming` 或 `writing-plans` 覆盖已有 Spec Kit `spec.md`、`plan.md` 或 `tasks.md`。
- 不要让 Codex 和 Claude Code 同时写同一份 Spec Kit 产物。
- 感觉状态不一致时，运行 `speckit.speckit-superpowers-bridge.audit`、`speckit.speckit-superpowers-bridge.parity` 和 `speckit.speckit-superpowers-bridge.validate`。

## configuration

handoff 文件是 `.specify/superpowers-handoff.json`。

关键字段：

- `executor`: 必须是 `superpowers`
- `autonomous_mode`: 默认 `false`
- `resume_context`: 当前 task、skill、phase 和下一步动作
- `artifact_owner`: 唯一允许写 Spec Kit 控制产物的 agent

详细脚本参数和 handoff 字段行为见 `.specify/extensions/speckit-superpowers-bridge/docs/parameter-reference.md`。

环境变量：

- `SPECKIT_BRIDGE_ACTOR`: 覆盖 actor 自动检测
- `SPECKIT_BRIDGE_AUTONOMOUS=1`: 运行时启用 autonomous execution

## architecture

Spec Kit 负责 WHAT：constitution、spec、plan、tasks、checklists 和 analyze。Superpowers 负责 HOW：TDD、debug、execution、review、verification 和 branch finishing。bridge 的优势是用最少胶水保持严格分工，让两边都做自己最擅长的事，而不是互相改写或替代。

## commands

官方 extension command IDs：

- `speckit.speckit-superpowers-bridge.execute`: 通过 Superpowers 执行 Spec Kit `tasks.md`
- `speckit.speckit-superpowers-bridge.guard`: 执行职责边界保护
- `speckit.speckit-superpowers-bridge.handoff`: 创建或刷新 handoff
- `speckit.speckit-superpowers-bridge.parity`: 审计 disposition matrix 覆盖
- `speckit.speckit-superpowers-bridge.audit`: 审计安装状态和双 agent skill parity
- `speckit.speckit-superpowers-bridge.validate`: 运行端到端 bridge validation pass
- `speckit.speckit-superpowers-bridge.recommend-route`: 给出轻/重工作流建议

Agent integration 会把这些 command ID 渲染为各自的调用风格。例如 Codex 会把 execute 命令渲染为 `$speckit-speckit-superpowers-bridge-execute`；Claude Code 会渲染为 `/speckit-speckit-superpowers-bridge-execute`。

## skill-sync-upgrade

Codex 和 Claude Code 使用不同的 skill 目录。用下面命令保持同步：

```powershell
specify integration upgrade codex
specify integration upgrade claude
```

如果上游 Spec Kit 没有自动镜像 extension skills，只手动复制 bridge skill：

```powershell
Copy-Item .agents\skills\speckit-superpowers-bridge .claude\skills\speckit-superpowers-bridge -Recurse
```

不要手改官方生成的 `.agents/skills/speckit-*` 或 `.claude/skills/speckit-*` 文件。

## troubleshooting

优先运行这些检查：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\parity-check.ps1 -Json
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\audit-install-state.ps1 -Json
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\validation-pass.ps1 -Json
```

如果实现阶段发现需求缺口，把 handoff 标记为 `blocked`，回到 Spec Kit 产物修正后再继续。

## marketplace-positioning

社区 catalog 里已经有更宽泛的 Superpowers bridge。本 extension 刻意更窄：它服务于希望 Spec Kit 保持完整设计主干，同时让 Superpowers 提供实现纪律的团队。差异点是 guard/handoff/audit/rollback 契约，而不是另一个 planning layer。

## license

MIT。包元数据见 extension manifest。
