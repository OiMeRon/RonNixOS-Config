# 技能库 — nix-skills 使用说明

> **单一事实源**：源文件在 `~/nixos-config/NIX-SKILLS.md`（受 git 版本控制，会推到 GitHub）。
> 软链接（由 `home.nix` 的 `mkOutOfStoreSymlink` 声明式维护）：
> `~/.kimi-code/NIX-SKILLS.md`（Kimi CLI）。
> 与 `NIXOS-OPS.md` / `MEMORY.md` 分工：本文档是**技能索引与工作指引**，
> 前者是事实与依据库，后者是用户偏好与系统状态。

## 概述

- **来源**：<https://github.com/olafkfreund/nix-skills>
- **安装日期**：2026-09-29
- **安装位置**：`~/.agents/skills/`（10 个目录）
- **定位**：给 AI agent 提供**带版本钉选上游来源**的 Nix 生态知识，避免给出过时/命令式/不匹配当前 NixOS pin 的建议
- **与本机 `nix-ins` 的关系**：互补不重叠。`nix-ins`（本机自建）= 软件安装流程 SOP（读错误总结 → 声明式安装 → 验证 → 文档更新）；`nix-skills` = 按领域细分的知识参考，覆盖语言、系统运维、打包、Home Manager 等 10 个领域

## 共性工作原则

所有 nix-skills 共享以下行为模式：

1. **先读 `sources.json`**：每个 skill 目录下有 `sources.json`，记录该 skill 所钉选的上游版本（Nix/NixOS/Nixpkgs 修订号）。skill 内容描述的是那个钉选版本，**不一定**是当前系统的 pin。涉及版本敏感行为时，必须核实本机实际版本。
2. **先读仓库指令再动手**：每个 skill 都要求先读项目自身的 `AGENTS.md`、`README`、`flake.nix` 等，尊重项目既有约定。
3. **最小改动原则**：复用项目已有函数/约定，选最小的正确修改。
4. **区分层次**：语言内置 vs Nixpkgs `lib` vs NixOS 模块选项合并，三者不可混淆。

## 技能索引

### 1. `nix-language` — Nix 语言

| 项 | 内容 |
|---|---|
| **用途** | 编写、解释、调试、审查 Nix 表达式 |
| **触发场景** | 语法、作用域、惰性求值、函数、字符串、路径、推导（derivation）、内置函数 |
| **不覆盖** | NixOS 服务选项（→ `nixos-operations` / `nixos-wiki`）、Nixpkgs API（→ `nixpkgs-development`） |
| **关键参考** | `references/language.md`（作用域、函数、递归集、let/with、数据类型、运算符、惰性、字符串上下文、derivation）、`references/builtins.md`（精选内置函数的行为与可用性） |
| **来源钉选** | Nix 手册（LGPL-2.1），版本见 `sources.json` |

**使用要点**：
- 区分语言内置与 Nixpkgs `lib` 提供的函数
- 区分普通属性集与 NixOS 模块选项合并语义
- `//` 只替换重叠属性，不递归合并嵌套集
- 插值路径会触发文件复制进 store，需保留依赖上下文

---

### 2. `nix-workflow` — Nix 工作流

| 项 | 内容 |
|---|---|
| **用途** | 选择 Nix 命令、定位 store 路径与库、使用开发 shell、调试构建、配置 Nix、导航生态工具 |
| **触发场景** | 不确定该用 `nix build` 还是 `nix develop`、找不到某个文件属于哪个包、构建失败排查 |
| **关键规则** | **永远不要暴力搜索 `/nix/store`**（`find`/`ls` 只看到本地已构建的，看不到其余一切，且复制的路径在 store 变化后即失效） |
| **正确工具** | `nix-locate` 查文件归属包；`nix path-info` / `nix why-depends` 查依赖；通过 Nix 表达式引用库而非硬编码 store 路径 |

**使用要点**：
- 先确认 `nix --version`（Nix / Lix / Determinate Nix 行为不同）
- 确认 `nix-command` 与 `flakes` 是否启用（`nix config show experimental-features`）
- 确认项目用 flake / npins / niv / channels 哪种方式锁定输入

---

### 3. `nixos-operations` — NixOS 运维

| 项 | 内容 |
|---|---|
| **用途** | 操作 NixOS 系统：rebuild 模式选择、generation 管理、回滚、升级、store 清理、启动与服务诊断 |
| **触发场景** | 该用 `switch` 还是 `test` 还是 `build`、如何回滚、如何安全清理 store、启动失败排查 |
| **关键参考** | `references/operations.md`（引用 NixOS 手册，版本见 `sources.json`） |
| **来源钉选** | NixOS 手册（MIT），版本见 `sources.json` |

**使用要点**：
- 先确认系统构建方式（flake `nixosConfigurations.<host>` 还是 channel `/etc/nixos/configuration.nix`）
- 先确认 NOS 版本与 `system.stateVersion`
- 不要把手册示例当作迁移配置的理由

---

### 4. `nixpkgs-development` — Nixpkgs 开发

| 项 | 内容 |
|---|---|
| **用途** | 编写、解释、审查、调试 Nixpkgs 包表达式、构建 helper、override、overlay、库 API |
| **触发场景** | 给 nixpkgs 加新包、写 overlay、调试构建失败、理解 stdenv 阶段 |
| **关键参考** | `references/packaging.md`（stdenv、依赖角色、阶段/hook、元数据、包测试）、`references/customization.md`（参数 override、属性 override、overlay、通用模块组合） |
| **来源钉选** | Nixpkgs 手册，版本见 `sources.json`（master 快照，非稳定版声明） |

**使用要点**：
- 区分 Nix evaluator 版本、Nixpkgs 修订、构建/宿主/目标平台
- 保持项目既有包布局、overlay、开发环境约定

---

### 5. `home-manager` — Home Manager

| 项 | 内容 |
|---|---|
| **用途** | 配置与排错 Home Manager 用户环境（NixOS 模块 / nix-darwin 模块 / 独立安装） |
| **触发场景** | 用户级包、服务、环境变量、dotfiles 管理 |
| **关键参考** | `references/nixos.md`（NixOS 模块模式）、`references/install-nix-darwin.md` + `references/flake-nix-darwin.md`（nix-darwin 模式）、`references/install-standalone.md`（独立模式） |
| **来源钉选** | Home Manager（MIT），版本见 `sources.json` |

**使用要点**：
- **先确定安装模式**：NixOS 模块 → 随 host 的 `nixos-rebuild` 生效；nix-darwin 模块 → `darwin-rebuild`；独立 → `home-manager switch`
- 保持项目既有模块与 feature-flag 约定

---

### 6. `nixos-wiki` — NixOS Wiki

| 项 | 内容 |
|---|---|
| **用途** | 查找并解读保留的 NixOS Wiki 指南（系统配置、模块、reboot、启动、网络、存储、systemd） |
| **触发场景** | 需要社区经验补充官方手册未覆盖的配置细节 |
| **关键工具** | `scripts/wiki.py search '<关键词>'`、`scripts/wiki.py show '<页面>'`、`scripts/wiki.py show '<页面>' --follow` |
| **覆盖范围** | 精选 17 个主题的快照，**不是**完整 Wiki 也不是选项目录 |
| **来源钉选** | NixOS Wiki（MIT），版本见 `sources.json` |

**使用要点**：
- 推荐版本敏感改动前，必须在该 pin 的官方手册、选项定义或源码处复核
- 最近的 wiki 修订不证明与当前 pin 兼容

---

### 7. `nix-darwin` — nix-darwin

| 项 | 内容 |
|---|---|
| **用途** | 配置、构建、排错 nix-darwin macOS 系统配置与 `darwin-rebuild` generation |
| **触发场景** | macOS 上的 Nix 管理（本机不适用，保留供跨平台参考） |
| **关键参考** | `references/readme.md`（前提、flake/channel 设置、更新、卸载） |
| **来源钉选** | nix-darwin（MIT），版本见 `sources.json` |

**使用要点**：
- `darwin-rebuild build` / `switch` / `test` 三模式
- 先确认 nix-darwin 与 Nixpkgs 的 pin

---

### 8. `devenv-project` — devenv 项目环境

| 项 | 内容 |
|---|---|
| **用途** | 创建、解释、审查、调试 devenv 项目环境（`devenv.nix`、`devenv.yaml`、lockfile、语言、任务、服务、shell 激活） |
| **触发场景** | 项目级开发环境配置、`devenv up` 失败排查、添加新语言/服务 |
| **关键参考** | 按需读取 references 中的相关章节 |
| **来源钉选** | devenv（Apache-2.0），版本见 `sources.json` |

**使用要点** |
- 先读项目的 `devenv.nix`、`devenv.yaml`、`devenv.lock` 及本地配置
- 新项目优先用 `devenv init`，检查输出后再加最小配置
- 区分 `devenv version`、锁定的 devenv 模块修订、nixpkgs 修订、`require_version` —— 三者独立变化
- `devenv info` 评估配置；`devenv search NAME` 用项目包输入

---

### 9. `microvm-nix` — microvm.nix

| 项 | 内容 |
|---|---|
| **用途** | 配置与排错 microvm.nix 声明式微虚拟机 |
| **触发场景** | NixOS flake 中声明式部署轻量 VM |
| **关键参考** | `references/declaring.md`（模块形态）、`references/intro.md`、`references/declarative.md`（声明式部署）、`references/host.md`（主机集成）、`references/host-systemd`、`references/options.md`、网络 references、`references/shares.md` |
| **来源钉选** | microvm.nix（MIT），版本见 `sources.json` |

**使用要点** |
- 区分 VM 的 NixOS 配置与主机的 `microvm.vms` 管理配置
- 主机路径、共享 store、网络接口、设备透传 = 信任边界
- 已部署的 VM 可能需要旧版模块形态

---

### 10. `nixos-coding-agents` — NixOS AI 编码 Agent

| 项 | 内容 |
|---|---|
| **用途** | 选择、安装、沙箱化 AI 编码 agent（llm-agents.nix 包、agent-images 容器、agent-box 一次性工作区） |
| **触发场景** | 在 NixOS 上部署隔离的编码 agent 环境 |
| **三层架构** | ① **包**：[numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) ≈200 个 agent（Claude Code、Codex、Gemini CLI、OpenCode 等）作为 flake 包 + overlay，带 binary cache，每日更新；② **镜像**：[nothingnesses/agent-images](https://github.com/nothingnesses/agent-images) 每个 agent 一个 Nix 构建的 OCI 镜像，以非 root 用户在 `/workspace` 运行；③ **编排**：[0xferrous/agent-box](https://github.com/0xferrous/agent-box) `ab` 命令创建一次性 Git worktree 或 Jujutsu workspace 并在容器内运行 agent |
| **来源** | 链接上游而非复制，示例于 2026-09-23 核对上游；上游每日更新，依赖前需确认 |

**使用要点** |
- 按需选用层数（只用包 / 包+镜像 / 全套）
- 上游变化频繁，flag 与参数以上游为准

---

## 选择指南

| 我要… | 用哪个 skill |
|---|---|
| 理解/调试一段 Nix 表达式 | `nix-language` |
| 不确定该用哪个 Nix 命令 | `nix-workflow` |
| 重建/回滚/清理 NixOS 系统 | `nixos-operations` |
| 给 nixpkgs 加包或写 overlay | `nixpkgs-development` |
| 配置用户级环境（本机 `home.nix`） | `home-manager` |
| 查社区经验（官方手册没覆盖的） | `nixos-wiki` |
| macOS 上的 Nix 管理 | `nix-darwin` |
| 项目级开发环境 | `devenv-project` |
| 声明式微 VM | `microvm-nix` |
| 在 NixOS 上跑隔离的 AI agent | `nixos-coding-agents` |
| 安装新软件到本机 | `nix-ins`（本机自建，不在本批） |

## 复核命令

- 确认 skill 安装完整：`ls ~/.agents/skills/ | grep -E '^(devenv-project|home-manager|microvm-nix|nix-darwin|nix-language|nix-workflow|nixos-coding-agents|nixos-operations|nixos-wiki|nixpkgs-development)$'`（应返回 10 行）
- 确认软链接生效：`readlink -f ~/.kimi-code/NIX-SKILLS.md`（应指向 `~/nixos-config/NIX-SKILLS.md`）
- 查看某 skill 的钉选版本：`cat ~/.agents/skills/<name>/sources.json`
