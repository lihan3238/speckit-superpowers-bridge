[English](README.md)

# speckit-superpowers-bridge

Spec Kit + Superpowers Bridge 是一个轻量的本地扩展协议：Spec Kit 继续作为规范、计划、任务的事实源，Superpowers 负责实现阶段的工程纪律。

## installation

按照 `.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml` 中列出的文件，把 bridge 资产安装或复制到已经安装 Codex、Claude Code 或两者的 Spec Kit 项目中。

```powershell
specify init . --integration codex
specify integration install claude
```

安装后运行安装状态审计：

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

复制或安装本 bridge 在 manifest 中列出的文件，然后验证本地安装：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\audit-install-state.ps1 -Json
```

### 1. Pick the Spec Kit writer

每个 feature 同一时间只让一个 agent 写 Spec Kit 控制产物，另一个 agent 只做 review。

- Codex 命令风格：`$speckit-specify`、`$speckit-plan`、`$speckit-tasks`
- Claude Code 命令风格：`/speckit-specify`、`/speckit-plan`、`/speckit-tasks`

### 2. Create the Spec Kit artifacts

用选定的 writer 跑标准 Spec Kit 设计流程：

```text
$speckit-specify "描述要构建的功能"
$speckit-clarify
$speckit-checklist
$speckit-plan
$speckit-tasks
$speckit-analyze
```

Claude Code 使用同名 slash 命令，例如 `/speckit-specify`。

### 3. Hand off implementation

`after_tasks` hook 应该会创建 `.specify/superpowers-handoff.json`。需要手动刷新时：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready -Actor codex
```

如果 Claude Code 负责执行，用 `-Actor claude`。只有明确想长时间无人值守执行时才开启 autonomous mode：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready -AutonomousMode $true -Actor codex
```

### 4. Execute with Superpowers

调用 bridge，而不是 `speckit.implement`：

```text
$speckit-superpowers-bridge
```

Claude Code 使用 `/speckit-superpowers-bridge`。

bridge 会读取 `constitution.md`、`spec.md`、`plan.md` 和 `tasks.md`，然后用 Superpowers 的工程纪律执行 `tasks.md`：TDD、debug、review、verification 和 branch finishing。执行过程中会更新任务勾选和 handoff 状态。

### 5. Handle requirement gaps

如果实现时发现需求缺失或设计错误，停止编码并把 handoff 标记为 blocked：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status blocked -Reason "Spec Kit artifact needs revision" -Actor codex
```

回到 Spec Kit 修订 `spec.md`、`plan.md` 或 `tasks.md`，再创建新的 ready handoff 并继续 bridge 执行。

### 6. Verify and finish

确认 feature 完成前运行：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\validation-pass.ps1 -Json -Actor codex
```

只有任务完成且验证通过后，bridge 才把 handoff 标记为 `complete`。开始下一个 feature 时，`before_specify` hook 会自动归档已完成 handoff；也可以手动运行：

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\auto-archive-handoff.ps1 -Actor codex
```

### 7. Guardrails

- handoff executor 是 `superpowers` 时，不要运行 `speckit.implement`。
- 不要用 Superpowers `brainstorming` 或 `writing-plans` 覆盖已有的 Spec Kit `spec.md`、`plan.md` 或 `tasks.md`。
- 不要让 Codex 和 Claude Code 同时写同一份 Spec Kit 产物。
- 感觉状态不一致时，运行 `speckit.superpowers.audit`、`speckit.superpowers.parity` 和 `speckit.superpowers.validate`。

## configuration

交接状态文件是 `.specify/superpowers-handoff.json`。

关键字段：

- `executor`: 必须是 `superpowers`
- `autonomous_mode`: 默认 `false`
- `resume_context`: 当前任务、skill、阶段和下一步动作
- `artifact_owner`: 唯一允许写 Spec Kit 控制产物的 agent

环境变量：

- `SPECKIT_BRIDGE_ACTOR`: 覆盖 actor 自动检测
- `SPECKIT_BRIDGE_AUTONOMOUS=1`: 运行时启用 autonomous execution

## architecture

Spec Kit 负责 WHAT：constitution、spec、plan、tasks、checklists 和 analyze。Superpowers 负责 HOW：TDD、debug、execution、review、verification 和 branch finishing。这个边界遵循 `AGENTS.md` 中引用的 Spec Kit vs Superpowers 对比文章。

## commands

Bridge meta-commands：

- `speckit.superpowers.guard`: 执行职责边界保护
- `speckit.superpowers.handoff`: 创建或刷新 handoff
- `speckit.superpowers.parity`: 审计 disposition matrix 覆盖
- `speckit.superpowers.audit`: 审计安装状态和双 agent skill parity
- `speckit.superpowers.validate`: 运行端到端 bridge validation pass
- `speckit.superpowers.recommend-route`: 给出轻/重工作流建议

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

## license

MIT。包元数据见 extension manifest。
