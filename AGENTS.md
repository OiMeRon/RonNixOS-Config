# 法 — NixOS 操作宪法

> **单一事实源**：源文件在 `~/nixos-config/AGENTS.md`（受 git 版本控制，会推到 GitHub）。
> 以下路径均为指向它的软链接（由 `home.nix` 的 `mkOutOfStoreSymlink` 声明式维护）：
> `~/AGENTS.md`（DimAgent）、`~/.clinerules/01-nixos-redlines.md`（Cline）、`~/.kimi-code/AGENTS.md`（Kimi CLI）。
> —— 不再有副本，不存在漂移。**改内容改仓库里那份，改完 rebuild 生效。**
> 与任何旧副本冲突时：**停下，并排列出两边原文问人，不静默覆盖。**

这台机器是**声明式系统**：机器是构建产物，事实源是配置仓库 `~/nixos-config/`。

## 唯一写入路径

改 `~/nixos-config/` 声明 → `git diff` → `nix flake check` → `sudo nixos-rebuild build --flake .` → **停下等人批** → `sudo nixos-rebuild switch --flake .`

回滚：`sudo nixos-rebuild switch --rollback`

## 红线（命中即停，说明理由，请求人工确认）

1. 不写 `/nix/store/**`（含 chmod/chown/增删）
2. 不手改 `/etc/**` 下任何文件
3. 不手写 `/etc/systemd/system/*.service`；服务写进配置模块
4. 不用 `nix-env -i/-u` 或 `nix profile install` 装东西
5. 不改 `stateVersion`
6. 不自行跑任何清理（`nix-collect-garbage` 等）
7. 不动 bootloader / 内核 / 分区 / fstab
8. 不读、不复制、不外传凭证与私钥
9. 未走完唯一写入路径就报告"改好了" = 假成功
10. 任何不可逆的批量删除
11. 不触发完整 `nixos-rebuild switch` 做小改动（图标/文件手动处理即可）

## 完成定义

**命令 + 期望输出**。没有可复现命令佐证的结论，不算完成，按未完成处理。

## 指针

- 安装任何软件前必读踩坑记录：`~/Data/文档/安装错误总结.md`
- **用户文件结构 / 第三方软件放哪（装任何软件前必读）**：
  `~/OmniStudio/AGENTS.md`（规则：第三方软件统一放 `Applications/`，数据放 `~/Data/`）、
  `~/OmniStudio/DIRECTORY.md`（各子目录用途）。
  骨架由 `~/nixos-config/modules/user-file-structure.nix` 声明式创建，改结构改那里。
  素材（图标/着色器）放 `~/Data/apps/<类型>/`，被 Nix 声明以绝对路径引用。
- 重建系统后需手动放回的软件与素材（模式 A：本体在 store 外）：
  `~/Data/文档/重装后需手动放回的文件.md`
- 安装/更新软件的标准流程技能：`nix-ins`（本机 `~/.agents/skills/nix-ins/SKILL.md`）
- 事实与依据、本机探测、反例库（按需）：`~/.kimi-code/NIXOS-OPS.md`
- 用户偏好与当前系统状态（带日期，按需）：`~/.kimi-code/MEMORY.md`
- 立法模板出处：`~/Data/文档/Agent宪法.md`
