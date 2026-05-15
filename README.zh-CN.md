[English](README.md)

![License](https://img.shields.io/github/license/lihan3238/speckit-superpowers-bridge)
![Latest release](https://img.shields.io/github/v/release/lihan3238/speckit-superpowers-bridge)
![Last commit](https://img.shields.io/github/last-commit/lihan3238/speckit-superpowers-bridge)
![Spec Kit](https://img.shields.io/badge/spec--kit-%E2%89%A50.8.10-blue)

# speckit-superpowers-bridge

**正式结合 Spec Kit 与 Superpowers。** Spec Kit 始终是设计的事实源（constitution → spec → plan → tasks）。Superpowers 在指定生命周期阶段被**显式**调用，负责实现期的 TDD、verification、code review。跨 Agent 兼容：Codex、Claude Code、或两者同时使用。轻量级仓库内协议；无后台守护进程、无服务、无全局插件改动。

> 设计动机记录在 [Spec Kit vs Superpowers 比较文章](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj) 中——本扩展把这种结合模式落地为一份可强制执行的契约。

## workflow

```text
                  ┌───────────────── Spec Kit 设计阶段 ─────────────────────┐
  用户 ─► /speckit-constitution ─► /speckit-specify ─► /speckit-clarify ─►
          /speckit-plan ─► /speckit-tasks
                                                       │
                                                       │ after_tasks 钩子
                                                       ▼
                          ┌──────── speckit-superpowers-bridge ────────┐
                          │  guard / handoff / disposition matrix /    │
                          │  parity check / audit / validate           │
                          └──────────────────┬─────────────────────────┘
                                             │
                  ┌──────── Superpowers 执行阶段（显式调用） ───────┐
                  ▼                                                            ▼
       superpowers:test-driven-development            superpowers:verification-before-completion
       superpowers:systematic-debugging               superpowers:requesting-code-review
       superpowers:executing-plans (依据 tasks.md)    superpowers:finishing-a-development-branch
                                             │
                                             │ 每次调用记录为 skill_invocation 事件
                                             ▼
                                   .specify/bridge-events.jsonl
```

## installation

需先安装 Spec Kit。然后从下面三种安装路径中任选其一。

### Pure Codex

```powershell
specify init my-project --integration codex
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.2.0/speckit-superpowers-bridge-v0.2.0.zip
```

不依赖 Claude Code。所有桥接动作通过 Codex 的 `$speckit-*` 调用方式完成。

### Pure Claude Code

```powershell
specify init my-project --integration claude
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.2.0/speckit-superpowers-bridge-v0.2.0.zip
```

不依赖 Codex。所有桥接动作通过 Claude Code 的 `/speckit-*` 斜杠命令完成。

### Both (cross-agent handoff)

```powershell
specify init my-project --integration claude         # 或 --integration codex
cd my-project
specify integration add codex                         # 若以 codex 起步则换成 'claude'
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.2.0/speckit-superpowers-bridge-v0.2.0.zip
```

`.agents/skills/`（Codex）与 `.claude/skills/`（Claude Code）都会得到桥接 skill 对等文件。可以在一个 Agent 中做设计、切换到另一个 Agent 做实现，过程无需手动迁移状态。

### Local development install

如果要直接开发桥接本身：

```powershell
specify extension add --dev .\.specify\extensions\speckit-superpowers-bridge
```

## your first feature in 10 minutes

```text
1. /speckit-constitution            （每个项目一次性运行）
2. /speckit-specify "添加 OAuth2 登录"
3. /speckit-clarify                 （桥接提出 2–5 个针对性问题）
4. /speckit-plan                    （生成 plan.md + research.md + data-model.md + contracts/）
5. /speckit-tasks                   （生成 tasks.md）
                       │
                       │ after_tasks 钩子触发 → 写入 handoff JSON；status=ready
                       ▼
6. /speckit-speckit-superpowers-bridge-execute
       │
       │ 加载桥接 SKILL.md，开始显式调用 Superpowers skill：
       │   • 每个任务先执行 superpowers:test-driven-development
       │   • 阶段收尾前执行 superpowers:verification-before-completion
       │   • 整体收尾前执行 superpowers:requesting-code-review 和 :finishing-a-development-branch
       ▼
7. handoff → complete；用 /speckit-speckit-superpowers-bridge-validate 确认全部通过
```

下一个 feature 启动时，`/speckit-specify` 会触发 `auto-archive-handoff.ps1` 把上一个 `complete` 状态自动归档为 `ready` 并清空 `feature_directory`——无需手动维护 handoff。

## commands

| Command (Claude Code) | Command (Codex) | 用途 |
|---|---|---|
| `/speckit-speckit-superpowers-bridge-execute` | `$speckit-speckit-superpowers-bridge-execute` | 通过桥接协议把 Spec Kit `tasks.md` 交给 Superpowers 执行 |
| `/speckit-speckit-superpowers-bridge-handoff` | `$speckit-speckit-superpowers-bridge-handoff` | 创建或更新 Superpowers handoff 状态 |
| `/speckit-speckit-superpowers-bridge-guard` | `$speckit-speckit-superpowers-bridge-guard` | 检查请求的命令是否被当前 handoff 状态允许 |
| `/speckit-speckit-superpowers-bridge-audit` | `$speckit-speckit-superpowers-bridge-audit` | 检查安装状态：integration、git extension、双 Agent skill 对齐 |
| `/speckit-speckit-superpowers-bridge-validate` | `$speckit-speckit-superpowers-bridge-validate` | 端到端验证（handoff 状态 + 矩阵 + skill 调用 + 测试） |
| `/speckit-speckit-superpowers-bridge-parity` | `$speckit-speckit-superpowers-bridge-parity` | 审计 disposition matrix、版本锁定、Agent 对齐 |
| `/speckit-speckit-superpowers-bridge-recommend-route` | `$speckit-speckit-superpowers-bridge-recommend-route` | 建议性路由：完整 Spec Kit 流程 vs 直走 Superpowers |
| `/speckit-speckit-superpowers-bridge-submission-checklist` | `$…submission-checklist` | 本地镜像官方 catalog 提交校验 |
| `/speckit-speckit-superpowers-bridge-cleanup-audit` | `$…cleanup-audit` | 发版前的仓库清理审计 |

## configuration

桥接按以下优先级读取配置：脚本参数 > 环境变量 > 项目状态。

### actor resolution

桥接脚本通过 `-Actor` 判断当前由哪个 Agent 发起调用时，按此顺序解析：

1. 显式 `-Actor <codex|claude|unknown>` 参数。
2. `SPECKIT_BRIDGE_ACTOR` 环境变量。
3. `.specify/integration.json.default_integration`。
4. 兜底字符串 `"unknown"`。

每个 Agent 的桥接 `SKILL.md` 已写死自己的 `-Actor`，因此在对话框里正常使用时不需要设置环境变量；这条链主要服务于 CI 或脚本直接调用场景。

### autonomous mode

把 handoff JSON 的 `autonomous_mode` 字段设为 `true`（或临时设置 `SPECKIT_BRIDGE_AUTONOMOUS=1`），即可让 `/speckit-speckit-superpowers-bridge-execute` 在任务边界不再确认；只在指定的 review checkpoint（verification、code-review、finishing-branch）暂停。默认关闭。

### resume context

任何会话中断时，桥接会把当前 task ID、当前 Superpowers skill、下一步预期动作写入 `superpowers-handoff.json.resume_context`。下一会话的首条非工具输出会在 200 字符内告知三者，Agent 即可无缝继续。

跨 Agent 主协议见 `AGENTS.md`；Claude 特定补充见 `CLAUDE.md`。每个桥接脚本的完整参数参考见 [`.specify/extensions/speckit-superpowers-bridge/docs/parameter-reference.md`](.specify/extensions/speckit-superpowers-bridge/docs/parameter-reference.md)。

## troubleshooting

| 现象 | 可能原因 | 解决 |
|---|---|---|
| `handoff stuck in executing` | 上一次桥接执行中断，未走到 `complete` 或 `blocked` | 检查 `superpowers-handoff.json`；如果工作确实已完成，执行 `update-handoff.ps1 -Status complete`；如果中途放弃，则用 `-Status blocked -Reason "abandoned"` |
| `parity check P1 finding` | 上游 Spec Kit / Superpowers 新增了能力但矩阵尚未登记 | 在 `disposition-matrix.json` 中补一条 entry，写明 disposition 与 `verified_against`；再次运行 parity check |
| `missing per-agent peer skill` | 一边 `.X/skills/<id>` 存在但另一边缺失 | 镜像复制 SKILL.md 或移除孤儿；再次运行 audit |
| `autonomous mode not activating` | handoff 中 `autonomous_mode` 仍为默认 `false` | 运行 `update-handoff.ps1 -AutonomousMode $true` 或设置 `SPECKIT_BRIDGE_AUTONOMOUS=1` |
| `validation-pass failing on first run` | 10 项检查之一不通过（矩阵不完整、skill 调用缺失等） | 阅读报告 finding，每条都附 `suggested_fix`，从上到下处理 |
| `download_url_unreachable` during submission-checklist | release ZIP 尚未构建或 URL 写错 | tag 推送后等 2–5 分钟再跑；或修正 `marketplace/catalog-entry.json.download_url` |

## maintenance and versioning

本版本验证基线：

- **Spec Kit** `0.8.10`（锁定于 `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`）
- **Superpowers** skill pack `5.1.0`

`parity-check.ps1` 会在任意一边发版新增/重命名能力时立刻报告 drift。契约是：一旦出现 drift，要么更新矩阵并 bump `verified-versions.json`，要么把桥接锁回旧版；无论哪种决策都会记录在 `CHANGELOG.md`。

## architecture in 60 seconds

> 转述自 [Spec Kit vs Superpowers 比较文章 (truongpx396, dev.to)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj)。

- **Spec Kit 负责 WHAT。** Constitution、spec、clarify、plan、tasks、checklists、analysis。这些是 `.specify/` 与 `specs/` 下持久的设计制品。
- **Superpowers 负责 HOW。** TDD、debugging、executing-plans、requesting-code-review、verification-before-completion、finishing-a-development-branch。这些是在生命周期阶段被显式调用的实现纪律 skill。
- **桥接把两者的结合显式化。** [`disposition-matrix.json`](.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json) 把每个 Spec Kit 命令和 Superpowers skill 归类为 `COMBINE` / `FORBID-UNDER-HANDOFF` / `SUPERSEDED-BY` / `REVIEW-ONLY`，并附明确理由。Guard 在每一次可能交叠的调用前查阅矩阵。文章警告 auto-trigger 会让会话失控，所以桥接 SKILL.md 在指定阶段**显式**触发 Superpowers skill，每一次调用都写一条 `skill_invocation` 事件留痕。

### how the bridge differs from peer extensions

| Extension | 关注点 | 与本桥接的区别 |
|---|---|---|
| [AIDE](https://github.com/mnriem/spec-kit-extensions) | 7 步项目初始化工作流 | AIDE 在 Spec Kit 之上加了一层工作流；本桥接是把 Spec Kit **连接**到 Superpowers 执行层 |
| [architect-preview](https://github.com/UmmeHabiba1312/spec-kit-architect-preview) | AI 开发的持续架构治理 | architect-preview 审视 spec/plan/code 漂移；本桥接做跨两个工具的非交叠策略强制 |
| api-contract-evolution | API 契约演进、破坏性变更检测 | 不同层次；本桥接是元工具（Spec Kit + Superpowers 之上），不针对 API |
| impact-predictor | 预测变更的架构影响与风险 | 预测性 vs 本桥接的非交叠规约性 |

## contributing and license

MIT — 见 [`LICENSE`](LICENSE)。

本扩展使用 AI 编码助手开发（Claude Code 负责设计 + 计划；Codex 负责实现）；披露见 [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md) 要求。每一个产出都经过人工审阅；桥接自带的 `validation-pass.ps1` + 17 个 smoke test 是验证面。

问题与讨论：<https://github.com/lihan3238/speckit-superpowers-bridge/issues>
