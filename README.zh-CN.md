[English](README.md)

![License](https://img.shields.io/github/license/lihan3238/speckit-superpowers-bridge)
![Latest release](https://img.shields.io/github/v/release/lihan3238/speckit-superpowers-bridge)
![Last commit](https://img.shields.io/github/last-commit/lihan3238/speckit-superpowers-bridge)
![Spec Kit](https://img.shields.io/badge/spec--kit-%E2%89%A50.8.10-blue)

# speckit-superpowers-bridge

**一座连接 Spec Kit（设计）与 Superpowers（实现）的轻量编排桥。** Spec Kit 仍是设计的唯一真相源（constitution → spec → plan → tasks）。Superpowers 负责实现期的 TDD、验证、code review 等纪律，由桥在指定生命周期阶段**显式**调用。跨 Agent：Codex、Claude Code 任选其一或同时使用。仓库内协议；无守护进程、无服务、无超出 Superpowers 原生能力的自定义纪律。

> 设计意图参见 [Spec Kit vs Superpowers 对比文章](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj) —— 本插件是让二者合作所需的最小接线。

## workflow

```text
                  ┌───────────────────── Spec Kit 阶段 ─────────────────────┐
  user ─► /speckit-constitution ─► /speckit-specify ─► /speckit-clarify ─►
          /speckit-plan ─► /speckit-tasks
                                                       │
                                                       │ after_tasks 钩子
                                                       ▼
                          ┌──────── speckit-superpowers-bridge ─────────┐
                          │  handoff（写入 superpowers-handoff.json）   │
                          │  guard（5 条硬编码边界规则）                 │
                          │  execute（编排原生 Superpowers 技能）       │
                          └──────────────────┬──────────────────────────┘
                                             │
                  ┌────────── Superpowers 阶段（显式调用）───────┐
                  ▼                                                            ▼
       superpowers:executing-plans                   superpowers:verification-before-completion
       superpowers:test-driven-development           superpowers:requesting-code-review
       superpowers:systematic-debugging              superpowers:finishing-a-development-branch
                                             │
                                             │ handoff 状态转换写入日志
                                             ▼
                                   .specify/bridge-events.jsonl
```

## installation

先装 Spec Kit。本插件已收录到官方 Spec Kit community catalog，catalog 用于发现和审阅：

官方收录页：[docs/community/extensions.md](https://github.com/github/spec-kit/blob/main/docs/community/extensions.md)（通过 [issue #2581](https://github.com/github/spec-kit/issues/2581) 和 [PR #2586](https://github.com/github/spec-kit/pull/2586) 接受）。

community catalog 默认是 discovery-only，所以正常安装使用稳定的 latest-release ZIP：

### 纯 Codex

```powershell
specify init my-project --integration codex
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

无 Claude Code 依赖。桥完全跑在 Codex 的 `$speckit-*` 调用面上。

### 纯 Claude Code

```powershell
specify init my-project --integration claude
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

无 Codex 依赖。桥跑在 Claude Code 的 `/speckit-*` 斜杠命令上。

### 双 Agent（跨 Agent 交接）

```powershell
specify init my-project --integration claude         # 或 --integration codex
cd my-project
specify integration install codex                     # 反之 'claude'
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

`.agents/skills/`（Codex）与 `.claude/skills/`（Claude Code）都会拿到桥的同名 skill 文件。一边设计、一边实现，只需切换 Tab。

### 本地开发安装

为开发桥本身：

```powershell
specify extension add --dev .\.specify\extensions\speckit-superpowers-bridge
```

### 固定版本安装

如果你需要可复现地安装某个精确版本，使用固定 ZIP：

```powershell
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.4.3/speckit-superpowers-bridge-v0.4.3.zip
```

## prerequisites

Windows 用户需要 PowerShell 5.1+（受支持的 Windows 版本自带）。Linux 和 macOS 用户使用同一个扩展 ZIP，但运行 bash flavor，需要：

- `bash >= 4.0`
- `jq >= 1.6`

安装示例：

```bash
sudo apt install bash jq      # Ubuntu / Debian
brew install bash jq          # macOS
sudo dnf install bash jq      # Fedora
```

需要运行仓库 smoke tests 的贡献者还需要 PowerShell Core (`pwsh`) 7.x。Linux/macOS 终端用户正常执行 bridge 不需要 `pwsh`。

## your first feature in 10 minutes

```text
1. /speckit-constitution            （项目内一次）
2. /speckit-specify "新增 OAuth2 登录"
3. /speckit-clarify                 （桥提 2–5 个针对性问题）
4. /speckit-plan                    （生成 plan.md + research.md + data-model.md + contracts/）
5. /speckit-tasks                   （生成 tasks.md）
                       │
                       │ after_tasks 钩子触发 → 写入 handoff JSON；status=executing
                       ▼
6. /speckit-superpowers-bridge      （Claude Code）  或  $speckit-superpowers-bridge  （Codex）
       │
       │ 桥 SKILL.md 加载；按顺序调用原生 Superpowers 技能：
       │   • superpowers:executing-plans 驱动逐任务循环
       │   • superpowers:test-driven-development 在每个改码任务前
       │   • superpowers:verification-before-completion 在阶段结束
       │   • superpowers:requesting-code-review 然后 :finishing-a-development-branch 在功能结束
       ▼
7. handoff → complete；下一次 /speckit-specify 自动归档上一次
```

## When to Skip Spec Kit

并非所有改动都需要完整的 Spec Kit → 桥 → Superpowers 流程，由你自己决定路径：

| 改动类型 | 建议路径 |
|---------|---------|
| 错别字修复、单行 bug、小范围 refactor | 直接调用 Superpowers，跳过 `/speckit-specify`。 |
| 新功能、跨多文件 refactor、含设计决策的改动 | 走完整流程：`/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-superpowers-bridge`。 |
| 范围不明的探索 / spike | 先用 Superpowers `brainstorming`；若涌现出 spec，再升级到完整流程。 |

桥不再自动给你推荐路径（0.2.x 时代的 `recommend-route` 命令已在 0.3.0 移除），决策权在你手上。guard 在两条路径下都仍会执行边界规则 —— 没有活动的 Spec Kit handoff 时它不会阻塞你直接使用 Superpowers。

## commands

| 命令（Claude Code） | 命令（Codex） | 用途 |
|---|---|---|
| `/speckit-superpowers-bridge` | `$speckit-superpowers-bridge` | 通过桥协议把 Spec Kit `tasks.md` 跑进 Superpowers |
| `/speckit-speckit-superpowers-bridge-handoff` | `$speckit-speckit-superpowers-bridge-handoff` | 创建或更新 Superpowers handoff 状态 |
| `/speckit-speckit-superpowers-bridge-guard` | `$speckit-speckit-superpowers-bridge-guard` | 检查请求的命令是否被当前 handoff 状态允许 |

fresh marketplace 安装会从 execute 命令的 alias 生成 `$speckit-superpowers-bridge` / `/speckit-superpowers-bridge`。官方 canonical 回退入口仍是 `$speckit-speckit-superpowers-bridge-execute` / `/speckit-speckit-superpowers-bridge-execute`。handoff 和 guard 有意保留 canonical 长命令，因为它们是高级/内部命令。

如果你看到 `.agents/skills/speckit-speckit-superpowers-bridge-*` 或 `.claude/skills/speckit-speckit-superpowers-bridge-*`，这是正常现象：Spec Kit 会根据 extension commands 自动生成这些 skills。源码仓库里也有 `.agents/skills/speckit-superpowers-bridge/` 和 `.claude/skills/speckit-superpowers-bridge/` 这两个短名本地镜像；不要期待它们被 extension ZIP 原样复制到新项目。

v0.2.x 中存在的 6 个元命令（`audit`、`validate`、`parity`、`recommend-route`、`submission-checklist`、`cleanup-audit`）**已在 0.3.0 移除**。它们要么重复了原生 Superpowers 已经提供的纪律，要么属于超出薄桥范围的自定义功能。详见 `CHANGELOG.md`。

## configuration

桥按优先级读取两层配置：显式脚本参数 > 环境变量。

### actor resolution

桥脚本需要知道是哪个 Agent 在调用它（`-Actor`）时，按下面顺序解析：

1. 显式 `-Actor <codex|claude|unknown>` 参数。
2. `SPECKIT_BRIDGE_ACTOR` 环境变量。
3. 字面量 `"unknown"`。

每个 Agent 的桥 `SKILL.md` 都把 `-Actor` 写死为自己 —— 所以正常对话使用中你完全不用设环境变量。这个链对 CI 或手动调脚本场景才有意义。

主跨 Agent 协议见 `AGENTS.md`；Claude Code 专属补充见 `CLAUDE.md`。

## troubleshooting

| 现象 | 可能原因 | 修复 |
|---|---|---|
| `handoff stuck in executing` | 上一次桥执行在转 `complete`/`blocked` 之前被中断 | 检查 `superpowers-handoff.json`；若工作确实做完了，运行 `update-handoff.ps1 -Status complete`；若被放弃，`-Status blocked -Reason "abandoned"` |
| `missing per-agent peer skill` | 一边的 `.X/skills/<id>` 存在但另一边不存在 | 把存在那一侧的 SKILL.md 镜像过去；或删掉孤立项 |
| 只看到长的 `speckit-speckit-superpowers-bridge-*` skills | 安装的是 `v0.4.0-rc.1` 或更旧包，当时还没有 execute alias | 使用上面的 latest-release ZIP 命令升级；短执行入口是 `$speckit-superpowers-bridge` / `/speckit-superpowers-bridge` |
| Windows 下 `specify extension info` 抛 `UnicodeEncodeError` | 旧 GBK 控制台无法渲染 Rich 的 bullet 字符 | 运行 `chcp 65001` 或把 PowerShell 输出设为 UTF-8。这是 Spec Kit CLI 显示问题，不是桥安装失败 |
| guard 拒绝了一个你没预期的命令 | `guard-command.ps1` 里 5 条硬编码规则之一触发了 | 阅读 guard 打印的拒绝原因；规则集很小、可读 |
| 老安装写的 handoff JSON 含 v3 字段 | 0.3.0 前的 handoff 里有 `autonomous_mode` / `resume_context` / `archive_history` | 无需操作。0.3.0 桥会容忍读、下次写入时静默丢弃。 |

## maintenance and versioning

本版本针对以下版本验证：

- **Spec Kit** `0.8.10`
- **Superpowers** skill 包 `v5.1.0`

版本兼容性现在由 release 时的人工检查保障（0.2.x 时代自动化的 `verified-versions.json` 与 `parity-check.ps1` 已在 0.3.0 移除）。当上游工具的新版破坏了桥，我们要么修补 3 个保留脚本，要么在 `CHANGELOG.md` 中钉住已验证的兼容版本。

## architecture in 60 seconds

> 改编自 [Spec Kit vs Superpowers 对比文章（truongpx396, dev.to）](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj)。

- **Spec Kit 拥有 WHAT。** Constitution、spec、clarify、plan、tasks、checklists、analysis 都是 `.specify/` 与 `specs/` 下的耐久设计 artifact。
- **Superpowers 拥有 HOW。** TDD、debugging、executing-plans、requesting-code-review、verification-before-completion、finishing-a-development-branch，是在生命周期阶段调用的实现纪律技能。
- **桥编排原生技能，不提供自定义纪律。** 它只贡献：Spec Kit 生成的 extension command skills、PowerShell 和 bash 两种 flavor 的四个小状态脚本（`update-handoff`、`guard-command`、`auto-archive-handoff`、`common-actor-resolution`），以及 5 条硬编码边界规则。没有 matrix、没有 audit、没有 validation pass、没有 parity check。

### how the bridge differs from peer extensions

| 插件 | 关注点 | 桥的差异 |
|---|---|---|
| [AIDE](https://github.com/mnriem/spec-kit-extensions) | 7 步项目启动工作流 | AIDE 在 Spec Kit 之上加 workflow；本桥**连接** Spec Kit 到 Superpowers 的执行层 |
| [architect-preview](https://github.com/UmmeHabiba1312/spec-kit-architect-preview) | AI 协作下的持续架构治理 | Architect-preview 审 spec/plan/code 漂移；本桥编排两个工具但不添加纪律 |
| api-contract-evolution | API 契约演进、破坏性变更检测 | 完全不同的层；本桥是 Spec Kit + Superpowers 上面的元层，与 API 形状无关 |
| impact-predictor | 预测变更的架构影响 / 风险 | 预测 vs. 我们这种“机械执行”的桥 |

## contributing and license

MIT —— 见 [`LICENSE`](LICENSE)。

本插件使用 AI 协作开发（Claude Code 负责设计 + 规划；Codex 负责实现；0.3.0 的瘦身由 Claude Code 独立完成）满足 [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md) 的 AI 披露要求。所有 artifact 都经人工 review 后提交。`tests/` 下保留 3 个 smoke 测试，覆盖 handoff schema、硬编码 guard 规则、跨 Agent skill 对等。

Issues 与讨论：<https://github.com/lihan3238/speckit-superpowers-bridge/issues>
