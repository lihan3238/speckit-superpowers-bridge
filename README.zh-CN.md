<p align="center">
  <img src="https://raw.githubusercontent.com/lihan3238/speckit-superpowers-bridge/main/assets/social/github-social-preview.png" alt="speckit-superpowers-bridge: Spec Kit 写 WHAT。Superpowers 执行 HOW。" width="960" />
</p>

<p align="center">
  <em>Spec Kit 写 WHAT。Superpowers 执行 HOW。这个桥只负责 handoff。</em>
</p>

<p align="center">
  <a href="./LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" /></a>
  <a href="https://github.com/lihan3238/speckit-superpowers-bridge/releases"><img alt="Bridge version" src="https://img.shields.io/github/v/release/lihan3238/speckit-superpowers-bridge?style=flat-square&label=bridge" /></a>
  <a href="https://github.com/github/spec-kit"><img alt="Spec Kit verified 0.10.2" src="https://img.shields.io/badge/Spec_Kit-verified_0.10.2-success?style=flat-square" /></a>
  <a href="https://github.com/obra/superpowers"><img alt="Superpowers verified 6.0.0" src="https://img.shields.io/badge/Superpowers-verified_6.0.0-success?style=flat-square" /></a>
  <a href="https://github.com/github/spec-kit/blob/main/docs/community/extensions.md"><img alt="Spec Kit Marketplace listed" src="https://img.shields.io/badge/Spec_Kit_Marketplace-listed-blueviolet?style=flat-square" /></a>
</p>

# speckit-superpowers-bridge

> English: [README.md](README.md)

**speckit-superpowers-bridge 是 Spec Kit 设计 artifact 与 Superpowers 实现纪律之间的 handoff 层。** Spec Kit 仍是设计唯一真相源（constitution → spec → plan → tasks）。Superpowers 负责实现期的 TDD、验证、code review 等纪律，由桥在指定生命周期阶段**显式**调用。Codex 与 Claude Code 共享同一个仓库内协议。

无守护进程。无服务。无数据库。无第二套 workflow engine。无超出 Superpowers 原生能力的自定义纪律。

> 设计意图参见 [Spec Kit vs Superpowers 对比文章](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj) —— 本插件是让二者合作所需的最小接线。

---

## 一眼看懂

| 如果你想要... | 这个桥提供... |
|---|---|
| Spec Kit artifact 保持权威 | Spec Kit 继续拥有 `spec.md`、`plan.md` 和 `tasks.md`。 |
| 不重新规划也能使用 Superpowers 纪律 | 把 `tasks.md` 交给原生 Superpowers execution、verification、review、branch-finishing 技能。 |
| Codex 与 Claude Code 协作 | 共享 `.specify/superpowers-handoff.json` 契约，两端 bridge skill 内容一致。 |
| Windows 与 Linux 都能验证 | 同一个 ZIP 同时带 bash 与 Windows PowerShell flavor，release gate 覆盖两端。 |
| 插件市场需要的可信证据 | `bridge-status --readiness`、package validation、确定性 release ZIP、已发布 SHA 证据。 |
| 最小运行负担 | 3 个命令、5 个 hook、每种 shell flavor 6 个小状态脚本，无 runtime service。 |

安装当前稳定版：

```bash
specify extension add speckit-superpowers-bridge \
  --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

## 为什么用 speckit-superpowers-bridge

Spec Kit 擅长产出耐久的设计 artifact（constitution、spec、plan、tasks、checklists、analysis），但它自带的 `speckit.implement` 只是一次性 LLM 调用 —— 没有 TDD、没有 subagent 分工、没有结构化 review。

Superpowers 擅长「执行」纪律（TDD、systematic debugging、subagent-driven development、verification、code review、finishing a development branch），但它原生预期通过自家的 `brainstorming` 与 `writing-plans` 技能驱动设计，而不是从 Spec Kit 的 `tasks.md` 出发。

桥是让二者合作的最薄胶水，并且不让任何一方蚕食对方的角色：一个 `superpowers-handoff.json` 状态文件、五条硬编码 guard 规则、每种 shell flavor 六个小脚本、一个编排 SKILL，按顺序在 Spec Kit `tasks.md` 上调用原生 Superpowers。**没有 runtime matrix、没有 audit loop、没有 implementation validation pass、没有 command-parity subsystem、没有自定义 DSL —— 只有让循环跑起来的最小契约。**

## Quick Start

```bash
specify init my-project --integration claude   # 或 --integration codex
cd my-project
specify extension add speckit-superpowers-bridge \
  --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

7 步说明这段命令做了什么：

1. `specify init` 用你选的 Agent integration 初始化一个 Spec Kit 项目。
2. `specify extension add ... /releases/latest/download/...` 从稳定别名 URL 安装桥（始终解析到最新发布 —— 后续发布永不失效）。
3. Spec Kit 在 `.specify/extensions.yml` 注册桥的 3 个命令 + 5 个 hook。
4. 桥在 `.specify/extensions/speckit-superpowers-bridge/scripts/` 写入边界 guard。
5. 跑一个 feature：`/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks`。
6. `after_tasks` 钩子自动触发 —— 桥写出 `.specify/superpowers-handoff.json`，status 为 `executing`。
7. `/speckit-superpowers-bridge`（Claude Code）或 `$speckit-superpowers-bridge`（Codex）驱动原生 `superpowers:executing-plans` 跑 `tasks.md`，然后 verification + code review + branch finishing。handoff 转为 `complete`。

> [!TIP]
> 只有一个模糊的想法？在 `/speckit-specify` 之前先跑 `superpowers:brainstorming`。桥的 guard 在「pre-spec」窗口允许这条路径 —— 产出的 design doc 落在 `docs/superpowers/specs/<date>-<topic>-design.md`，你可以把它的相对路径写进 `/speckit-specify` 的描述里，LLM 会把它当作 context。参见 feature [010-prespec-brainstorming](specs/010-prespec-brainstorming/spec.md) 中记录的生命周期决策。

## 1.0.x readiness 与支持矩阵

v1.0.0 是稳定协议 release：不引入新的 workflow engine、不引入 daemon/service/database，也不替代 Spec Kit 或 Superpowers 的原生行为。本版本加强 package/readiness 检查，并记录受支持平台与 Agent 的真实证据。

v1.0.1 是同一协议面上的文档与开发 checkout 清理补丁。

v1.0.2 是展示与发布资产补丁：README 顶图、社交卡片、marketplace 文案和贡献者文档小修；bridge runtime 行为不变。

v1.0.3 是 Spec Kit 0.10.x 兼容对齐补丁：在 Spec Kit CLI `0.10.2` 上重新验证、声明新的 `category`/`effect` manifest 字段、并按 0.10.0 的 git 扩展 opt-in 变化刷新 bootstrap 文档；bridge runtime 行为不变。

v1.1.0 是 Superpowers 6.0.0 兼容对齐版本：将「已验证的 Superpowers 基线」从 `5.1.0` 推进到 `6.0.0`（上游 major 大版本），且 **bridge runtime 零改动**。Superpowers 6.0.0 的破坏性变更全部位于上游 skill 内部（`subagent-driven-development` 的 reviewer prompt 合并、worktree 改落到项目内 `.worktrees/`、prose 去厂商化、新增三个 harness），对仅按 skill 名调用上游的 thin bridge 透明。grep 佐证的影响分析见 [`specs/016-superpowers-6-0-0-alignment/research.md`](specs/016-superpowers-6-0-0-alignment/research.md)。

| 目标 | 状态 | 证据 |
|---|---|---|
| Linux bash | 已验证 | 完整 bash smoke suite + release artifact sandbox cycle。 |
| Windows PowerShell 5.1+ | 已验证 | 原生 PowerShell smoke + release artifact sandbox cycle。旧 Windows Spec Kit CLI 在 GBK 控制台渲染 Rich 符号时可设置 `PYTHONUTF8=1`。 |
| Codex | 已验证 | `codex-cli 0.137.0` 的受限 sandbox 运行。 |
| Claude Code | 已验证 | Claude Code `2.1.162` 的受限 sandbox 运行。 |

安装后运行轻量 readiness 检查：

```bash
bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh --readiness --actor codex
bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh --readiness --json --actor codex
```

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\bridge-status.ps1 -Readiness -Actor claude
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\bridge-status.ps1 -Readiness -Json -Actor claude
```

readiness 报告是只读的：检查 script flavor、required tools、command namespace、package files、当前 bridge state、已验证 Agent metadata，以及下一步推荐动作。

### Demo：用户流程

<p align="center">
  <img src="docs/demo/hero.gif" alt="用户流程 demo — 安装、Spec Kit 设计命令、bridge 执行" width="760" />
</p>

## 定位（Positioning）

桥和「啥都不用」、「只用一边」或同类 hybrid 工具的差异：

| | 谁负责设计 | 谁负责实现 | 跨 Agent | 桥的额外开销 |
|---|---|---|---|---|
| **只用 `speckit.implement`** | Spec Kit | Spec Kit（一次性 LLM 调用） | 部分（通过 Spec Kit 的 agent-aware） | 无 |
| **只用 Superpowers（不用 Spec Kit）** | Superpowers（`brainstorming` + `writing-plans`） | Superpowers（TDD + subagents） | 是（Claude Code + Codex，通过 OS-level skills） | 无 |
| **Superspec** | spec-first workflow | plugin-managed implementation flow | 因 Agent 而异 | 更高 —— doctor/status 思路值得吸收，但 1.0.0 安装失败也暴露 catalog id / namespace 漂移风险 |
| **SuperB** | 以 Superpowers 为中心的规划 | 以 Superpowers 为中心的实现 | 是 | 更高 —— 编排更丰富，但生命周期 ownership 超出本桥目标 |
| **Comet（rpamis/comet，OpenSpec + Superpowers）** | OpenSpec change/spec | Superpowers，经 Comet 的 state machine | 是（多平台 npm 安装器） | 中等 —— Comet 自己有 `.yaml` + guard 脚本 |
| **cc-spex（rhuss/cc-spex，原 cc-sdd）** | Spec Kit（紧贴上游，定期同步） | Spec Kit 的显式规划 + 精选的 Superpowers 阶段（引导式 brainstorming、spec/plan 中间评审、多子代理深度评审），以原生 spec-kit 扩展形式提供 | 以 Claude Code 为主 | 中等 —— 叠加在 spec-kit 流程上的 opt-in 扩展 |
| **speckit-superpowers-bridge**（本项目） | Spec Kit（厂商所有） | Superpowers（厂商所有） | 是（Codex + Claude Code，契约相同） | **极薄** —— 1 个 guard 脚本、1 个 handoff JSON、0 套新的状态机 |

桥的招牌是 **兼容上游成长 + 极度轻量**。每个 release 都会过宪法 [Principle VI Native-First gate](.specify/memory/constitution.md)：上游是否已经做了这件事？上游是否是解决这件事的正确位置？只要任一答案是「是」，桥就**不**加这个功能。

---

<details>
<summary><strong>工作流图（Workflow）</strong></summary>

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

</details>

<details>
<summary><strong>安装（纯 Codex / 纯 Claude Code / 双 Agent / 开发安装 / 固定版本）</strong></summary>

先装 Spec Kit。本插件已收录到官方 Spec Kit community catalog，catalog 用于发现和审阅。

官方收录页：[docs/community/extensions.md](https://github.com/github/spec-kit/blob/main/docs/community/extensions.md)（通过 [issue #2581](https://github.com/github/spec-kit/issues/2581) 和 [PR #2586](https://github.com/github/spec-kit/pull/2586) 接受）。

community catalog 默认是 discovery-only，所以正常安装使用稳定的 latest-release ZIP。

**纯 Codex**

```powershell
specify init my-project --integration codex
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

无 Claude Code 依赖。桥完全跑在 Codex 的 `$speckit-*` 调用面上。

**纯 Claude Code**

```powershell
specify init my-project --integration claude
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

无 Codex 依赖。桥跑在 Claude Code 的 `/speckit-*` 斜杠命令上。

**双 Agent（跨 Agent 交接）**

```powershell
specify init my-project --integration claude         # 或 --integration codex
cd my-project
specify integration install codex                     # 反之 'claude'
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

`.agents/skills/`（Codex）与 `.claude/skills/`（Claude Code）都会拿到桥的同名 skill 文件。一边设计、一边实现，只需切换 Tab。

**本地开发使用**（用来开发这个桥仓库本身）：

这个源码 checkout 已经把桥放在
`.specify/extensions/speckit-superpowers-bridge/`，并且
`.specify/extensions.yml` 已经把这份本地源码注册为 installed extension。
在这个仓库里直接使用正常的 `$speckit-*` / `/speckit-*` 命令即可；不要在
同一个 checkout 里安装发布 ZIP，除非你就是想用 release 内容替换本地
extension 目录。

如果 fresh `specify init --here ... --force` 重新生成了本地安装态，需要重新注册桥，
请从目标 extension 目录之外的临时副本安装：

```bash
tmp="$(mktemp -d)"
cp -a ./.specify/extensions/speckit-superpowers-bridge "$tmp"/
specify extension add --dev "$tmp/speckit-superpowers-bridge"
```

不要在这个源码 checkout 里直接把
`./.specify/extensions/speckit-superpowers-bridge` 作为 `--dev` source 传入。
Spec Kit 会安装到同一个目标路径，source 和 destination 会重合。

PowerShell 等价命令：

```powershell
$tmp = New-Item -ItemType Directory -Path ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString()))
Copy-Item .\.specify\extensions\speckit-superpowers-bridge $tmp.FullName -Recurse
specify extension add --dev (Join-Path $tmp.FullName "speckit-superpowers-bridge")
```

发布 ZIP 只用于独立消费项目，或 sibling release-verification sandbox
`../test_specify_superpower`。

**固定版本安装**（用来可复现地安装某个精确版本）：

```powershell
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v1.1.0/speckit-superpowers-bridge-v1.1.0.zip
```

</details>

<details>
<summary><strong>前置条件（Prerequisites）</strong></summary>

Windows 用户需要 PowerShell 5.1+（受支持的 Windows 版本自带）。Linux 和 macOS 用户使用同一个扩展 ZIP，但运行 bash flavor，需要：

- `bash >= 4.0`
- `jq >= 1.6`

安装示例：

```bash
sudo apt install bash jq      # Ubuntu / Debian
brew install bash jq          # macOS
sudo dnf install bash jq      # Fedora
```

需要运行仓库 smoke tests 的贡献者使用 WSL bash 套件（`bash tests/run-all.sh`，009 之后已经全 bash 化）。终端用户正常执行 bridge 不需要 PowerShell Core (`pwsh`)。

</details>

<details>
<summary><strong>10 分钟跑完第一个 feature</strong></summary>

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

<p align="center">
  <img src="docs/demo/full-cycle.gif" alt="完整用户流程 — install、specify、clarify、plan、tasks、bridge execution、complete" width="820" />
</p>

</details>

<details>
<summary><strong>何时跳过 Spec Kit</strong></summary>

并非所有改动都需要完整的 Spec Kit → 桥 → Superpowers 流程，由你自己决定路径：

| 改动类型 | 建议路径 |
|---------|---------|
| 错别字修复、单行 bug、小范围 refactor | 直接调用 Superpowers，跳过 `/speckit-specify`。 |
| 新功能、跨多文件 refactor、含设计决策的改动 | 走完整流程：`/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-superpowers-bridge`。 |
| 范围不明的探索 / spike | 先用 Superpowers `brainstorming`；若涌现出 spec，再升级到完整流程。参见 feature [010-prespec-brainstorming](specs/010-prespec-brainstorming/spec.md)。 |

桥不再自动给你推荐路径（0.2.x 时代的 `recommend-route` 命令已在 0.3.0 移除），决策权在你手上。guard 在两条路径下都仍会执行边界规则 —— 没有活动的 Spec Kit handoff 时它不会阻塞你直接使用 Superpowers。

</details>

<details>
<summary><strong>命令一览（Commands）</strong></summary>

| 命令（Claude Code） | 命令（Codex） | 用途 |
|---|---|---|
| `/speckit-superpowers-bridge` | `$speckit-superpowers-bridge` | 通过桥协议把 Spec Kit `tasks.md` 跑进 Superpowers |
| `/speckit-speckit-superpowers-bridge-handoff` | `$speckit-speckit-superpowers-bridge-handoff` | 创建或更新 Superpowers handoff 状态 |
| `/speckit-speckit-superpowers-bridge-guard` | `$speckit-speckit-superpowers-bridge-guard` | 检查请求的命令是否被当前 handoff 状态允许 |
| `bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh`（Windows 用 `.ps1`） | 同左 | **(v0.7.0+)** 一秒内打印当前 bridge 状态 + `Drift:` + `Next:` 推荐命令。只读。`--json` 支持机器可读输出。v1.0.0 起可加 `--readiness` / `-Readiness` 查看安装健康度。 |

fresh marketplace 安装会从 execute 命令的 alias 生成 `$speckit-superpowers-bridge` / `/speckit-superpowers-bridge`。官方 canonical 回退入口仍是 `$speckit-speckit-superpowers-bridge-execute` / `/speckit-speckit-superpowers-bridge-execute`。handoff 和 guard 有意保留 canonical 长命令，因为它们是高级/内部命令。

如果你看到 `.agents/skills/speckit-speckit-superpowers-bridge-*` 或 `.claude/skills/speckit-speckit-superpowers-bridge-*`，这是正常现象：Spec Kit 会根据 extension commands 自动生成这些 skills。源码仓库里也有 `.agents/skills/speckit-superpowers-bridge/` 和 `.claude/skills/speckit-superpowers-bridge/` 这两个短名本地镜像；不要期待它们被 extension ZIP 原样复制到新项目。

v0.2.x 中存在的 6 个元命令（`audit`、`validate`、`parity`、`recommend-route`、`submission-checklist`、`cleanup-audit`）**已在 0.3.0 移除**。它们要么重复了原生 Superpowers 已经提供的纪律，要么属于超出薄桥范围的自定义功能。详见 `CHANGELOG.md`。

</details>

<details>
<summary><strong>配置（actor resolution）</strong></summary>

桥按优先级读取两层配置：显式脚本参数 > 环境变量。

**Actor resolution**：桥脚本需要知道是哪个 Agent 在调用它（`-Actor`）时，按下面顺序解析：

1. 显式 `-Actor <codex|claude|unknown>` 参数。
2. `SPECKIT_BRIDGE_ACTOR` 环境变量。
3. 字面量 `"unknown"`。

每个 Agent 的桥 `SKILL.md` 都把 `-Actor` 写死为自己 —— 所以正常对话使用中你完全不用设环境变量。这个链对 CI 或手动调脚本场景才有意义。

主跨 Agent 协议见 `AGENTS.md`；Claude Code 专属补充见 `CLAUDE.md`。

</details>

<details>
<summary><strong>故障排查（Troubleshooting）</strong></summary>

| 现象 | 可能原因 | 修复 |
|---|---|---|
| `handoff stuck in executing` | 上一次桥执行在转 `complete`/`blocked` 之前被中断 | 检查 `superpowers-handoff.json`；若工作确实做完了，运行 `update-handoff.ps1 -Status complete`；若被放弃，`-Status blocked -Reason "abandoned"` |
| `missing per-agent peer skill` | 一边的 `.X/skills/<id>` 存在但另一边不存在 | 把存在那一侧的 SKILL.md 镜像过去；或删掉孤立项 |
| 只看到长的 `speckit-speckit-superpowers-bridge-*` skills | 安装的是 `v0.4.0-rc.1` 或更旧包，当时还没有 execute alias | 使用上面的 latest-release ZIP 命令升级；短执行入口是 `$speckit-superpowers-bridge` / `/speckit-superpowers-bridge` |
| Windows 下 `specify extension info` 抛 `UnicodeEncodeError` | 旧 GBK 控制台无法渲染 Rich 的 bullet 字符 | 运行 `chcp 65001` 或把 PowerShell 输出设为 UTF-8。这是 Spec Kit CLI 显示问题，不是桥安装失败 |
| guard 拒绝了一个你没预期的命令 | `guard-command.ps1` 里 5 条硬编码规则之一触发了 | 阅读 guard 打印的拒绝原因；规则集很小、可读 |
| 老安装写的 handoff JSON 含 v3 字段 | 0.3.0 前的 handoff 里有 `autonomous_mode` / `resume_context` / `archive_history` | 无需操作。0.3.0+ 桥会容忍读、下次写入时静默丢弃。 |

> [!WARNING]
> **WSL 用户：**不要**设置 `git config --global http.proxy`。** 使用 `AGENTS.md` 中记录的 per-call env-var 方案（`https_proxy=http://10.77.0.11:10808 git push ...`）。全局 proxy 配置会把代理地址烤进 git config，在任何代理不可达的机器上都会出错。桥的 release runbook 和 smoke 套件都默认 env-var-per-call 写法。

</details>

<details>
<summary><strong>维护与版本（Maintenance and versioning）</strong></summary>

本版本（v1.1.0）针对以下版本验证：

- **Spec Kit** `0.10.2`（Linux bash）；Windows PowerShell 证据沿用 v1.0.0（`ps` 脚本 flavor 字节级未变），当时 sandbox 在 bridge runtime floor 对应的 Spec Kit CLI `0.8.10` 上通过
- **Superpowers** `6.0.0`
- **Codex CLI** `0.137.0`
- **Claude Code** `2.1.162`

verified metadata 记录在 [`.specify/extensions/speckit-superpowers-bridge/verified-versions.json`](.specify/extensions/speckit-superpowers-bridge/verified-versions.json) —— 项目自有、只做增量扩展的 schema，每次桥 release 刷新一次。v1.1.0 记录 bridge、上游工具、平台和真实 Agent 行；缺失或 blocked 的行不会被宣传为 verified。

当上游工具的新版破坏了桥，我们要么修补桥脚本，要么在 `CHANGELOG.md` 中钉住已验证的兼容版本。

Spec Kit `0.9.x` 已把 coding-agent context 更新迁移到 bundled `agent-context` 扩展。桥的运行时不依赖这个扩展，所以 `requires.speckit_version` 仍保持 `>=0.8.10`；本仓库跟踪 `agent-context` 只是为了让自身的 Spec Kit project bootstrap 保持最新。

> [!NOTE]
> **自 v0.6.0 起**，marketplace 的 `download_url` 与版本号解耦。它永久指向 `https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`，由 GitHub 的 `/releases/latest/` 别名解析。后续桥 release 不再编辑 `download_url`，只在 `marketplace/catalog-entry.json` 里 bump `version`。这消除了一类反复出现的「每个版本编辑一次」工作量和漂移面 —— 是 Principle VI 能取得的最小一次胜利。

</details>

<details>
<summary><strong>60 秒架构</strong></summary>

> 改编自 [Spec Kit vs Superpowers 对比文章（truongpx396, dev.to）](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj)。

- **Spec Kit 拥有 WHAT。** Constitution、spec、clarify、plan、tasks、checklists、analysis 都是 `.specify/` 与 `specs/` 下的耐久设计 artifact。
- **Superpowers 拥有 HOW。** TDD、debugging、executing-plans、requesting-code-review、verification-before-completion、finishing-a-development-branch，是在生命周期阶段调用的实现纪律技能。
- **桥编排原生技能，不提供自定义纪律。** 它只贡献：Spec Kit 生成的 extension command skills、PowerShell 和 bash 两种 flavor 的六个小脚本（`update-handoff`、`guard-command`、`auto-archive-handoff`、`bridge-state`、`bridge-status`、`common-actor-resolution`），以及 5 条硬编码边界规则。没有 runtime matrix、没有 audit loop、没有 implementation validation pass、没有 command-parity subsystem。

</details>

---

## 贡献与许可证

MIT —— 见 [`LICENSE`](LICENSE)。

本插件使用 AI 协作开发（Claude Code 负责设计 + 规划；Codex 负责实现；0.3.0 的瘦身和 v0.6.0 的美化都由 Claude Code 独立完成）满足 [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md) 的 AI 披露要求。所有 artifact 都经人工 review 后提交。[`tests/`](tests/) 下的 smoke 测试（009 之后已经全 bash 化）覆盖 handoff schema、5 条硬编码 guard 规则、bridge-state 输出和跨 Agent skill 对等。

Issues 与讨论：<https://github.com/lihan3238/speckit-superpowers-bridge/issues>
