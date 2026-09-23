# 情报 — 本机记忆与用户偏好

> **单一事实源**：源文件在 `~/nixos-config/MEMORY.md`（受 git 版本控制，会推到 GitHub）。
> 软链接（由 `home.nix` 的 `mkOutOfStoreSymlink` 声明式维护）：
> `~/.clinerules/03-machine-memory.md`（Cline）、`~/.kimi-code/MEMORY.md`（Kimi CLI）。
> 情报会腐烂：**必须带日期**；过期项以日期更新者为准，并标 ⚠️ 供人裁决。

## 用户偏好

- 语言：中文
- 执行操作前需确认（安装/更新软件、重建系统、**删除类操作**等）
- 不要修改与问题无关的主题、图标、配置内容
- **重建节奏（2026-09-22 用户裁定）：攒批** —— 小改动做完就停、不每次催切换；用户说切时给一条命令，把累积改动一起生效
- 变更前先问；不要为了"顺手"扩大范围

## 重要规则

- **安装软件前必须读取**：`~/Data/文档/安装错误总结.md`（最后更新 2026-09-21，18 节）
- **安装后发现新错误必须追加**：写入同一文档，保持更新
- **所有软件安装必须声明式**：含 AppImage、外部下载的软件；配置写入 `configuration.nix` 或 `home.nix`
- **不用 Flatpak（已裁定 2026-09-21 17:2x）**：用户批准彻底退出 flatpak。`services.flatpak.enable` 3 行声明已从 `configuration.nix` 移除并在 **Gen 138**（17:25:36）生效；`flatpak` 命令已从 PATH 消失。**剩余 = 清残留（待用户批）**：`/var/lib/flatpak` 1.4G（仅 runtime，无应用）+ `~/.local/share/flatpak` 52K + `~/.cache/flatpak` 7.4M + `~/.var/app` 88K ≈ **1.5G**。⚠️ 删除不可逆（红线 10），必须用户点头后执行
- **GitHub 推送**：用 `gh auth login` 配置；activationScript 无法访问用户凭据，用 systemd timer。**`push.autoSetupRemote = true` 已声明式开启**（`home.nix`，Gen 139 待 switch）—— 根因是 filter-repo 重加 remote 时丢 upstream 跟踪，timer 裸 `git push` 炸 exit 128
- **Agent 宪法**：`~/Data/文档/Agent宪法.md`

## NixOS 配置经验

### AppImage 封装（`appimageTools.wrapType2`）

1. **图标需手动提取**：`appimageTools` 不会自动提取 AppImage 内部图标
   - 先用 `appimageTools.extract` 解压，找内部图标路径（通常在 `usr/share/icons/hicolor/256x256/apps/` 或 `.DirIcon`）
   - 在 `extraInstallCommands` 中复制到 `$out/share/icons/hicolor/<size>/apps/`
2. **desktop 文件 `Icon=` 字段必须与实际文件名匹配**（不含 `.png` 扩展名）

### 图标不显示排查清单（按序）

1. `.desktop` 文件是否存在
2. `Icon=` 字段的值是什么
3. 对应图标文件是否存在（`find .../share/icons -name "<name>.png"`）
4. 图标文件是否有效（大小 > 1KB，不是占位符）
5. 清理用户缓存：`rm -rf ~/.cache/thumbnails/*`，注销重登

### 多次 `nixos-rebuild` 后图标缓存失效

- 原因：用户级缓存指向旧 store 路径
- 解决：`rm -rf ~/.cache/thumbnails/* ~/.cache/gtk-*/icon-cache*`，然后注销重登

### 系统目录只读

- `/run/current-system/sw/` 只读，不能直接 `gtk-update-icon-cache`
- 图标缓存刷新依赖系统重建后的自动机制 + 用户重新登录

### Nix 的体积口径（2026-09-22 实测方法）

- 依赖闭包大小 ≠ 实际占用：大量依赖系统里别处也在用
- 正确算法：取系统闭包 → 把目标包从引用图里摘掉 → 重新 BFS → 少掉的部分才是边际占用
- 同版本同 ABI 可能有**多个 store path**（不同 nixpkgs 输入各一份）：本机 `webkitgtk-2.52.6+abi=4.1` 就有 `0kai0wnr…`（nixpkgs 26.05）和 `iv6vjwxn…`（nixpkgs-unstable）两份
- 复核命令：`nix path-info -rSh <pkg>`；`nix why-depends <A> <B>` 看依赖链路

## 已安装技能

- `security-audit`（Cloudflare）：`~/.agents/skills/security-audit/`，2026-09-18 安装，涉及系统安全问题时选择性调用
- `nix-ins`（本项目自建）：NixOS 软件安装标准流程，`~/.agents/skills/nix-ins/SKILL.md`

## 当前系统状态

- (2026-09-18) NixOS 26.05 (Yarara) / GNOME 50 / Wayland；Flake 管理 `~/nixos-config/`
- (2026-09-18) nix-daemon 代理已配置：`127.0.0.1:7897`
- (2026-09-18) 已装：Blender、Obsidian、Zen Browser
- **(2026-09-22) 当前 Generation 141**（2026-09-21 18:16:59 构建；复核：`nixos-rebuild list-generations`）
- (2026-09-21) 桌面：Adwaita 图标主题、MacTahoe-Dark GTK 主题、Liquid Glass（Dock 自适应）、Rounded Window Corners
- (2026-09-21) 图标系统改由**系统级** `system.activationScripts.icon-cache` 生成（`configuration.nix:199`）：**不要再动图标主题，也不要往 `home.nix` 加图标激活脚本**
- (2026-09-21) 输入法：IBus + Rime + 雾凇拼音
- (2026-09-21) AppImage 第三方软件（→ `~/OmniStudio/Applications/AppImage/`）：QQ、WeChat、Motrix、Gopeed
- (2026-09-21 17:25) **已移除**：Brave（deb 解包 overlay，重建极慢）、Tolaria（linuxdeploy 强制 X11）、**Flatpak（Gen 138 生效；声明 3 行已删，磁盘残留 ≈1.5G 待批清理）**
- (2026-09-21 17:3x) **git-sync 状态**：timer 每半小时跑；`%`→`%%` 已生效（Gen 138），`dd1489c auto: 2026-09-21_17:25` 信息格式正常且已推送；main↔origin/main 跟踪已手工恢复；声明式 `push.autoSetupRemote` 已提交（`73ac75d`）；`.git` = 320K
- (2026-09-21 17:4x) 备份 bundle（554M）与 `/tmp/handoff*` 均已删除（用户批准）；**重写前旧历史不可再恢复**（知情裁决）

## (2026-09-22) 本轮变更与状态

### 规则文档统一（已完成）

- 三份规则改为**单一事实源 + 软链接**：源 = `~/.kimi-code/{AGENTS,NIXOS-OPS,MEMORY}.md`
- 软链接：`~/AGENTS.md`（DimAgent 全局读取路径，实测 app.asar 源码确认）、`~/.clinerules/0{1,2,3}-*.md`（Cline）
- 合并基准：Cline 版（重排版超集，事实无丢失；已做语义级比对确认）
- 备份：`~/.kimi-code/backup-2026-09-22/`（6 份，改动前的原始文件）

### 已完成 · 2026-09-22 18:13 切换生效（Generation 143）

| # | 改动 | 位置 |
|---|---|---|
| 1 | dconf 默认终端 → `ghostty` / `-e` | `home.nix` |
| 2 | 加 `xdg-terminal-exec` 包 | `configuration.nix` |
| 3 | `~/.config/xdg-terminals.list` 首选 Ghostty | `home.nix` |
| 4 | 新增 Hiddify 模块（AppImage + capability TUN） | `modules/Hiddify.nix`（新文件） |
| 5 | 注册 Hiddify 模块 | `flake.nix` |
| 6 | 加 `flclash` 包 | `configuration.nix` |
| 7 | **删 `programs.clash-verge`**（退役） | `configuration.nix` |
| 8 | **删 nix-daemon 代理三行**（不再需要 7897） | `configuration.nix` |

**切换后体检全部通过**（2026-09-22 18:1x）：
- `/run/current-system/sw/bin`：`FlClash` / `FlClashCore` / `hiddify`；clash 残留 unit **0**
- `getcap /run/wrappers/bin/hiddify-app` → `cap_net_bind_service,cap_net_admin,cap_net_raw=ep` ← **TUN 能力已生效**
- `nix eval` 拉包成功（无代理）→ 证明上游直连可达
- `git ls-remote origin` 走 SSH-443 成功；timer 已自动推送（HEAD 更新）

**磁盘清理：`/nix` 43G → 36G，释放 ≈ 7 GB**
（clash 独占 804 MB + 历次卸载遗留：brave-beta 463M、zen-twilight 397M、blender-5.2.1 286M、linux-firmware 798M 等）
- 关键：clash 一度回收不掉，根因是 **`/tmp/result-minimax`** 这个 9月19日遗留的构建软链（间接 GC 根）。详见 `NIXOS-OPS.md` 的 2026-09-22 条目。
- 代价：旧代际已全删，`--rollback` 只能回退到后续新代际；但 git 历史仍在，可 `git checkout <commit>` 重建。
（背景：GNOME 出厂值 `org.gnome.desktop.default-applications.terminal` 指向系统里不存在的 `xdg-terminal-exec`；Ghostty 的 desktop 文件自带 `X-TerminalArgExec=-e`，是合格候选。）

### clash-verge-rev 更新弹窗（已处理）

- 根因：app 的 silent updater 把 **2.5.4 的 Debian .deb（92MB）** 下到 `update_cache/pending_update.bin`，每次启动读它 → 弹窗（实测卡了 91 秒）
- 处理：① 删除 `pending_update.{bin,json}`；② `auto_check_update` 已由用户在 UI（设置 → Verge 基础设置 → 杂项设置）改为 `false`（2026-09-22 15:25:09 由 app 自己写回，非手改）
- 上游事实：nixpkgs（26.05 与 unstable）都停在 **2.5.2**；上游有 v2.5.4（含 rc），`/releases/latest` 仍指向 2.5.2
- 关键机制（源码）：`src-tauri/src/feat/window.rs:19` 的 `quit()` → `Config::apply_all_and_save_file()` → **退出时会把内存配置整份写回 `verge.yaml`**，所以运行中改文件无效

### 代理客户端选型（进行中）

- 背景：clash-verge-rev 在 NixOS 上的边际磁盘占用 **804 MB**（含 webkitgtk 168M + Qt 系统 350M，因 Tauri 依赖系统 WebView）
- 候选对比（2026-09-22 调研）：**FlClash** / **Clash Mi** / **Hiddify**
  - 三者都是 Flutter 壳（不依赖 WebView，体积小）；FlClash 与 Clash Mi 是 mihomo 内核，Hiddify 是 sing-box 内核
  - **Linux TUN 提权三者都有坑**：FlClash 的 Rust helper 要往 `/etc/systemd/system` 写 unit（本机该路径 → `/nix/store`，**只读，装不了**）；Clash Mi 无 Linux helper；nixpkgs 的 flclash 包不构建 helper
  - `flclash` 在 nixpkgs-unstable **已于 2026-08-17 移除**（`aliases.nix:858`，"low number of users and lack of maintenance"），26.05 冻结在 0.8.92
  - Hiddify 最新发版 **2026-03-05**（6.5 个月前），许可证为 GPL-3.0 + 7 条附加条款（含禁止商用）
- **用户裁定（2026-09-22）：选 Hiddify** —— 待办：实测 AppImage 能否在本机跑起来（预期踩 `libayatana-appindicator3` + `libepoxy`，见安装错误总结 §13.3），再决定是否写 `modules/hiddify.nix`

## ⚠️ 待裁决 / 待更新

1. **Flatpak 残留清理 → 待批**：`/var/lib/flatpak` **1.4G**（repo 1.3G + appstream 106M，全部是 runtime，无应用）+ `~/.local/share/flatpak` 52K + `~/.cache/flatpak` 7.4M + `~/.var/app` 88K ≈ **1.5G**；`flatpak: command not found` 证明无任何程序依赖；删除不可逆（红线 10）。命令集待用户批准后由 agent 或用户执行（`flatpak` 命令已卸，需用 `ostree`/`rm` 或临时 `nix shell nixpkgs#flatpak`）
2. **（2026-09-22）clash-verge-rev 退役 —— 已完成**
   曾因"删了会断 git push"而推迟。根因是**只有 `github.com` 这一个域名被墙**（其余 GitHub 域名全通）。
   **解决方案（2026-09-22 实施，用户选 A）：git 改走 SSH-443**
   - `~/.ssh/config`：`Host github.com` → `HostName ssh.github.com` / `Port 443` / `IdentityFile ~/.ssh/id_ed25519` / `IdentitiesOnly yes`
   - 密钥：ed25519（无口令，timer 需非交互），公钥已加到 GitHub。指纹记在本地，不入公开仓库。
   - remote：`git@github.com:OiMeRon/RonNixOS-Config.git`
   - **实测**：`ssh -T git@github.com` → `Hi OiMeRon!`；真实 push 临时分支成功并已删除
   **直连可达性实测（不走代理）**：
   | 主机 | 结果 |
   |---|---|
   | `github.com` | ✗ 12s 超时（唯一被墙的） |
   | `api.github.com` / `codeload.github.com` | ✓ 200 |
   | `ssh.github.com:443` | ✓ 握手成功 |
   | `cache.nixos.org` / `channels.nixos.org` / `mirrors.ustc.edu.cn` / `gh-proxy.com` / `registry.npmjs.org` | ✓ 全 200 |
   **gh-proxy 只能读不能写**：官方仅支持 Release/Raw/Archive/Gist/Git Clone；实测 `POST .../git-receive-pack` → **HTTP 405**。HTTPS clone 可用 `https://gh-proxy.com/https://github.com/...` 前缀（实测 `git ls-remote` 1.47s 成功）。
   ⇒ 因此 `configuration.nix` 里 clash-verge 与 nix-daemon 代理三行均已移除。
3. ~~切换代理客户端后的端口对齐~~ —— **已作废**（2026-09-22）：不再需要 7897。
   nix-daemon 的代理三行已删（上游全直连可达），git 走 SSH-443，所以**端口选多少都无所谓**。
   ✅ 遗留已清（2026-09-23）：`~/.gitconfig` 里那两行 `proxy = http://127.0.0.1:7897` 已删除
   （clash-verge 已卸载，7897 是死端口，留着只会让 HTTPS clone 失败）。
   复核：`git config --global --get-regexp proxy` 应无输出。

已裁定项（2026-09-21）：Brave/Tolaria 移除、Flatpak 退出（残留清理另批）、`nix-ins` 技能与法冲突已修、handoff 路径澄清（真文件 `/tmp/handoff.md`，内容已入库、文件已删）。

## ✅ 本轮已结案（2026-09-21 17:1x–17:4x）

- **`/bin/bash`**：Gen 136 生效 → Cline 命令工具恢复
- **clash-verge 更新**：运行版本 = 上游最新，无需动
- **git-sync 三连修**：① unit `%`→`%%`（Gen 138 生效，自动提交信息格式正常）；② 历史 AppImage 用 filter-repo 清除 + 25 个积压提交全部推送恢复（`.git` 554M→320K）；③ exit 128 = main 丢 upstream → 手工 `set-upstream-to` 恢复 + 声明式 `push.autoSetupRemote` 已提交（`73ac75d`）
- **Flatpak 退出**：声明已删（Gen 138 生效，`flatpak` 命令消失）；残留 ≈1.5G 待批清理
- **handoff 文档**：内容全部入库（三份规则 + 台账 §17），文件已删
- **备份 bundle**：已删（554M，用户批准）

## ✅ (2026-09-22) 已结案

- **clash 更新弹窗**：缓存已清 + `auto_check_update=false`（见上）
- **规则文档漂移**：单一事实源 + 软链接（见上）
- **终端选型结论**：本机唯一显式安装的终端是 Ghostty 1.3.1（`configuration.nix:172`）；GNOME Console (kgx) 由桌面模块自带
- **体积口径**：clash-verge-rev 边际占用 804 MB（方法见上）

## 复核命令

- 系统世代 / 版本：`nixos-rebuild list-generations | head -5`
- git 同步状态：`git -C ~/nixos-config status -sb | head -1`（期望 `## main...origin/main` 零偏差）
- flatpak 残留：`du -sh /var/lib/flatpak ~/.local/share/flatpak ~/.cache/flatpak ~/.var/app 2>/dev/null`
- Cline 规则是否被读取：查看 Cline 的 Rules 面板（`~/.clinerules/` 下 3 个文件应全部出现）
- 规则软链接是否生效：`readlink -f ~/AGENTS.md ~/.clinerules/*.md`
- clash 更新缓存是否干净：`ls -la ~/.local/share/io.github.clash-verge-rev.clash-verge-rev/update_cache/`（应为空）
