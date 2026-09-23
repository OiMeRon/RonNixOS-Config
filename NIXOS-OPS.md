# 细则库 — NixOS 事实与依据

> **单一事实源**：源文件在 `~/nixos-config/NIXOS-OPS.md`（受 git 版本控制，会推到 GitHub）。
> 软链接（由 `home.nix` 的 `mkOutOfStoreSymlink` 声明式维护）：
> `~/.clinerules/02-nixos-ops.md`（Cline）、`~/.kimi-code/NIXOS-OPS.md`（Kimi CLI）。
> 每条事实必须带核实状态：`[官方核实]` / `[知识库]` / `[本机探测]` / `[未验证]`。

## [官方核实]

- `nixos-rebuild` 四子命令：`build`（只构建）/ `test`（激活不写 boot）/ `switch`（激活 + 写 boot）/ `boot`（写 boot，重启生效）
- `hardware-configuration.nix` 不应手改（`nixos-generate-config` 会覆盖）
- `stateVersion` 记录首次安装版本，改它**不会**升级系统，可能损坏旧数据
- `/etc` 多数条目指向 `/etc/static` → `/nix/store`；`/etc/passwd` 等是可变的真实文件
- `/nix/store` 只读挂载；**除 `/bin/sh` 与 `/usr/bin/env` 外无原生二进制** ← 这条是 2026-09-21 故障的根因，见 [本机探测结果]
- `/bin/sh` 由 NixOS 自建的 activation script 生成，原文（nixpkgs rev `cf9d2fb`，`nixos/modules/config/shells-environment.nix`）：
  `system.activationScripts.binsh = mkdir -p /bin; chmod 0755 /bin; ln -sfn "$binsh" /bin/.sh.tmp; mv /bin/.sh.tmp /bin/sh`
  且 `environment.binsh = lib.mkDefault "${pkgs.bashInteractive}/bin/sh"` ⇒ **补 `/bin/bash` 照抄这套即可**（用 `pkgs.bashInteractive` + activationScript）

## 补充（来自 `~/Data/文档/Agent宪法.md` §8）

- 回滚可走开机菜单选旧 generation；每次改配置都会给菜单加一项
- 声明式系统里手改系统配置**不可能持久**：改动必须走改配置 + `nixos-rebuild switch`
- **所有未被 Git 跟踪的文件都会被 Nix 忽略** → 报文件 not found，先查是否漏 `git add`
- `/nix/var/nix/profiles`、`/run/booted-system`、`/nix/var/nix/gcroots/auto` 都是 GC root；删掉旧 generation 链接才真正释放空间
- 多个同优先级值定义同一 option 会报参数冲突，需人工解决；`config = if config.foo then ...` 会 infinite recursion，必须用 `lib.mkIf`
- `nix shell` 用完即走不落 profile；NixOS 上**没有 `/usr/include`**，直接 `./configure` 找不到头文件

## [本机探测结果]

- (2026-09-17) 用户 `ron`，wheel 组，sudo **需密码**（非无密码）
- (2026-09-17) 桌面 GNOME 50 / Wayland
- (2026-09-17) 配置仓库 `~/nixos-config/`（git tracked）
- **(2026-09-21) 本机无 `/bin/bash`** → Cline 的命令工具硬编码 `/bin/bash`，**任何命令都执行失败**：
  `posix_spawn '/bin/bash'` → `ENOENT: no such file or directory`。复核：`ls -l /bin/bash /bin/sh`（预期只有 `/bin/sh`）。
  影响：Cline 侧跑不了 `git` / `nix flake check` / `nixos-rebuild`，即[唯一写入路径]的可执行段**全部阻塞**，只余读写文件。（**已于 2026-09-21 17:15 修复，见下**）
- (2026-09-21) Cline 规则入口原本全空：`~/.clinerules/`、`~/.cline/rules/`、`~/.agents/AGENTS.md` 均不存在，`~/Documents/` 不存在
- (2026-09-21) `/tmp/handoff-2026-09-21-nixos-rules.md` **不存在**（handoff 文档自述的路径失效；实际文件是 `/tmp/handoff.md`）
- (2026-09-21) `flake.lock` 的 `nixpkgs-unstable` 已在上游 `nixos-unstable` 分支 HEAD（`20b1ddd1aa5a`，2026-09-19T02:38:33Z）；该锁定版本中 clash-verge-rev 已是 `2.5.2` = 上游最新 release（2026-07-19）→ **「clash 需要更新」结案（2026-09-21 17:2x 已确认）**：本机运行 `/nix/store/57bvz0rnnky1dxf6bnyvmb44z7ygxr3l-clash-verge-rev-2.5.2/bin/clash-verge` = `2.5.2` = 上游最新 ⇒ **无需 `nix flake update`**（复核：`readlink -f /run/current-system/sw/bin/clash-verge`）
- (2026-09-21) **三份规则文件曾互为副本**：`~/.clinerules/{01,02,03}-*.md` 复刻自 `~/.kimi-code/{AGENTS,NIXOS-OPS,MEMORY}.md`；改源文件后必须手动复刻，否则两边漂移。同日已完成一次双向同步。（**已于 2026-09-22 改为软链接，见下**）
- **(2026-09-21) Cline 规则作用域 = 等效全局（实测 + 决策）**：本机三份规则在 `/home/ron/.clinerules/`，官方语义是 **workspace 级**（project root 的 `.clinerules/` 或 `.cline/rules/`）。但本机 Cline 的 workspace root 就是家目录 `/home/ron`，故覆盖范围 = 家目录下一切，**等效于 KimiCode 的 `~/.kimi-code/` 全局作用域**；仅当 workspace 位于 `/home/ron` 之外时不覆盖。
  Cline 的真全局槽位（官方）：`~/Documents/Cline/Rules`（本机 `~/Documents` **不存在**）或 `~/.cline/rules`（本机 `~/.cline` 目录存在、`rules/` 不存在）。同一文件在两处并存时**都会加载**，冲突时 workspace 优先。
  **决策（2026-09-21，用户口径）：保持现状——不搬、不做副本。** 重复放两处 = 同一套规则被加载两次（备份），明确不要。

- (2026-09-21 17:2x **命令复核，修正前一条推断**）**Flatpak 真实状态**：`flatpak list` 只有 **5 条 runtime**（org.freedesktop.Platform 25.08 / GL.default / VAAPI.Intel / codecs-extra），**无任何应用**；`flatpak remotes` 仅 `flathub system`；`~/.var/app/org.blender.Blender` 是历史痕迹（曾用 flatpak 装 Blender，已卸，现用 `pkgs-unstable.blender`）。⇒ "在用所以不能删"推断**不成立**；`services.flatpak.enable = true;` 目前**无任何应用依赖** → 删配置重新可行，**待用户复评**
- (2026-09-21 **已生效**，17:15) **`/bin/bash` 补丁成功**：`configuration.nix` 新增 `system.activationScripts.binbash`（照抄上游 `binsh` 写法：`mkdir -p /bin; chmod 0755 /bin; ln -sfn … /bin/.bash.tmp; mv`）。证据：`/bin/bash -> /nix/store/yisa2lg79zcvgk4ck4yr6r0lz6j63hs3-bash-interactive-5.3p9/bin/bash`（root，9月21日 17:15）；Generation **136**（构建 17:14:16）；`git diff --stat` 仅 `configuration.nix` +8 行；**Cline 命令工具恢复**（`whoami`/`git`/`flatpak` 等实测可跑）

- (2026-09-21 17:2x **命令恢复后发现并修复**）**git-sync 双 bug**：① `home.nix:189` unit 内 `$(date +%Y-%m-%d_%H:%M)` 被 **systemd 说明符展开**吞掉（真实 message 变成 store 路径 + credentials 目录）→ 修法 `%` 写 `%%`（已改声明 + `flake check`/`build` 通过，**待 switch**）；② 历史提交 `9b75903` 把 `appimages/QQ.AppImage`(259M)/`appimages/WeChat.AppImage`(297M) 写进历史 → GitHub 拒推（GH001），**25 个提交自 09-20 11:21 起积压**。修法 `git filter-repo` 清路径 → 已推送（`d731206..420b524`），`.git` **554M → 320K**。备份：`/home/ron/nixos-config-history-backup-2026-09-21.bundle`
- (2026-09-21) `.git` 内有 2 个 root 属主残留（空 blob）→ 未来 `git gc` 可能告警；可选修 `sudo chown -R ron:users /home/ron/nixos-config/.git`

- **(2026-09-22) 规则文档改为「单一事实源 + 软链接」**（用户裁定）：源 = `~/.kimi-code/{AGENTS,NIXOS-OPS,MEMORY}.md`，内容以 Cline 版（更完整的重排版超集）为准合并；`~/.clinerules/0{1,2,3}-*.md` 与 `~/AGENTS.md` 全部改为**指向源文件的软链接**。
  ⇒ 上一条的「复刻副本 / 需手动复刻」**作废**：不再有副本，不存在漂移。
  ⇒ DimAgent 的读取路径（实测 app.asar 源码）：全局 `~/AGENTS.md` + 从 cwd 向上逐级找 `AGENTS.md`。
  ⚠️ 未验证：若 Cline 同时支持 `AGENTS.md` 与 `.clinerules/`，workspace root = `/home/ron` 时同一份规则可能被加载两次（token 成本，非正确性问题）。

- **(2026-09-22) GC 根不只在 profiles —— `/tmp` 下的构建产物软链也是根（实战踩坑）**
  退役 clash-verge 后删光旧代际，`nix-store -q --referrers <clash>` 仍返回 4 个引用者，804 MB 回收不掉。
  逐级追引用链 → 最后落到：
  ```
  $ nix-store --gc --print-roots | grep nixos-system
  "/tmp/result-minimax" -> /nix/store/1gxpwjd2…-nixos-system-nixos-26.05.20260916.4c78701   ← 9月19日遗留
  ```
  一个 3 天前某次 `nixos-rebuild build -o /tmp/result-minimax` 留下的**符号链接**，成了间接根（注册在 `/nix/var/nix/gcroots/auto/`），钉着旧系统 → 旧系统钉着 clash。
  **`/tmp` 在本机不是 tmpfs**（`findmnt -no FSTYPE /tmp` 无输出 = 挂在根分区），重启不会清掉它。
  **教训**：
  1. 排查"为什么 GC 收不掉 X"时，除了 `system-*-link` / `current-system` / `booted-system`，**必须看 `nix-store --gc --print-roots` 的完整输出**，特别是 `/tmp`、`/root` 下的 `result*` 软链
  2. `nixos-rebuild build` 默认在当前目录留 `result`；用 `-o /tmp/xxx` 就在 /tmp 留根 —— 清理时最容易漏
  3. bootloader 条目（`/boot/loader/entries/`）也是根；本机有 50 条，其中 7 条指向 26.11（unstable）的历史系统
  4. 移除单个软链是非破坏性的（`rm` 一个 symlink）；**真正的删除发生在 `nix-collect-garbage`**，后者才需要人批
  5. 验证方法：`rm <遗留根>` 后用 `nix-store --gc --print-dead | grep <包名>` 确认目标已进入待回收列表（`--print-dead` 只列不删）

## 运行方式决策

| 需求 | 用这个 |
|---|---|
| 临时工具 | `nix shell nixpkgs#<包>`（用完即走，不落 profile） |
| 长期服务 | `systemd.services.<name>` 配置模块 |
| 定时任务 | `systemd.timers` 配置模块 |
| 先试再上真机 | `nixos-rebuild build-vm` |

## 反例库

| 冲动 | 正确做法 |
|---|---|
| 手改 /etc 配置 | 改 `~/nixos-config/` 后 rebuild |
| `nix-env -i` 装测试包 | `nix shell nixpkgs#pkg` |
| 删 generation 省空间 | 先 `--dry-run` 给人看 |
| 改 `stateVersion` "升级" | 永不改 |

同源补充（宪法 §9）：新增文件没 `git add` → 构建报 not found → **先 add 再构建**。

## 核实命令

- 确认 /etc 是否符号链接：`readlink -f /etc/<file>`
- 确认 store 挂载：`findmnt -no OPTIONS /nix`
- 确认 generation 列表：`nixos-rebuild list-generations`
- 确认 `/bin/bash` 是否存在：`ls -l /bin/bash /bin/sh`
- 确认规则软链接：`readlink -f ~/AGENTS.md ~/.clinerules/*.md`
