# 用户文件结构 —— 声明式创建目录骨架
#
# ── 为什么有这个模块 ────────────────────────────────────────────────
# 本机的用户文件组织一直只靠「约定」：~/OmniStudio/AGENTS.md 和 DIRECTORY.md
# 写了目录该长什么样，但**没有任何东西去创建它们**。后果是漂移 ——
# 2026-09-23 实测：DIRECTORY.md 里 8 条声明，5 条目录根本不存在
# （workers/ 整个树、Applications/Scripts/）。
#
# 这个模块把骨架变成声明：新机器上目录自动出现，文档和现实不会再分叉。
#
# ── 事实源 ──────────────────────────────────────────────────────────
#   ~/OmniStudio/AGENTS.md     「第三方软件统一放 Applications/」
#                              「不放数据文件（数据在 ~/Data/）」
#   ~/OmniStudio/DIRECTORY.md  OmniStudio 各子目录用途
#   ~/Data/                    没有自己的索引文档，本模块按实际结构声明骨架
#
# ── 边界：只声明「骨架」，不管「应用自己的目录」──────────────────────
# 声明的是**组织性目录**。应用自己创建/管理的目录不在这里，否则会和应用打架：
#   不声明：~/Data/文档/ObsidianVault（Obsidian 保管）、
#           ~/Data/文档/xwechat_files（微信）、
#           ~/Data/apps/{motrix,qq,wechat}（各应用的运行时数据）、
#           ~/Data/backups/*（备份内容）
#
# ── 实现方式 ────────────────────────────────────────────────────────
# 用 systemd.tmpfiles.rules（本仓库 gopeed.nix 已在用同一机制装图标）。
# 用 `d` 而非 `D`：只保证存在 + 校正属主，**不删除任何东西**。
# 父目录写在子目录前面，避免依赖 tmpfiles 自动建父级的细节行为。

{ ... }:

let
  # 目录规则：mode 0755，属主 ron:users
  dir = path: "d ${path} 0755 ron users -";

  # OmniStudio —— 严格照 DIRECTORY.md 声明（让文档成真）
  omniStudio = [
    "/home/ron/OmniStudio"
    "/home/ron/OmniStudio/workers"
    "/home/ron/OmniStudio/workers/coder"
    "/home/ron/OmniStudio/workers/reviewer"
    "/home/ron/OmniStudio/workers/writer"
    "/home/ron/OmniStudio/workers/ops"
    "/home/ron/OmniStudio/workflows"
    "/home/ron/OmniStudio/state"
    "/home/ron/OmniStudio/Applications"
    "/home/ron/OmniStudio/Applications/AppImage"
    "/home/ron/OmniStudio/Applications/Extracted"
    "/home/ron/OmniStudio/Applications/Scripts"
  ];

  # ~/Data —— 组织性骨架（不含应用自己管的目录，见文件头说明）
  data = [
    "/home/ron/Data"
    "/home/ron/Data/公共"
    "/home/ron/Data/模板"
    "/home/ron/Data/视频"
    "/home/ron/Data/图片"
    "/home/ron/Data/图片/截图"
    "/home/ron/Data/文档"
    "/home/ron/Data/文档/Nix"
    "/home/ron/Data/下载"
    "/home/ron/Data/下载/Program"
    "/home/ron/Data/项目"
    "/home/ron/Data/音乐"
    "/home/ron/Data/桌面"
    "/home/ron/Data/apps"
    "/home/ron/Data/apps/icons"
    "/home/ron/Data/apps/shaders"
    "/home/ron/Data/apps/Programs"
    "/home/ron/Data/backups"
  ];
in
{
  systemd.tmpfiles.rules = map dir (omniStudio ++ data);
}
