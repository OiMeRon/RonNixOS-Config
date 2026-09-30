# 鼠标指针主题
#
# 鼠标指针主题
#
# 素材（Xcursor 文件）在 ~/Data/apps/icons/，不在 store：
# 从 vsthemes.org 下载的第三方包，无许可证声明，仅自用。
# 骨架由 user-file-structure.nix 声明，此模块只做引用。
#
#   moga-cursor/       上游原包（纯黑白：#1a1a1a 填充 + #ffffff 描边）
#   moga-cursor-blue/  同上，灰黑填充改为蓝 #1a8aff，白描边保留
#                      由 /tmp 的一次性脚本改色生成；换配色需重跑
#
# 这里只负责"把软链挂上"。光标主题名本身声明在 home.nix 的
# dconf.settings 里（org/gnome/desktop/interface/cursor-theme）——
# 那是唯一声明源，dconf 每次 switch 整份覆盖，不要在这里用 gsettings
# 设同一个键，会被 dconf 打回（2026-09-30 踩过）。
#
# 原理：GNOME/Wayland 的光标主题读的就是 Xcursor 格式（gdk/xcursor 库），
# 所以这些"X11 老格式"文件在 Wayland 下同样生效。Windows 侧的 .ani 动画
# 光标 Linux 不支持，忙碌状态会是静态图标 —— 包本身不含 Linux 动画光标。
{ lib, ... }:

let
  # 目录名必须等于 dconf 里 cursor-theme 的值，X11 靠目录名索引
  themeName = "Moga-Cursor-Blue";
  cursorSource = "/home/ron/Data/apps/icons/moga-cursor-blue";
in
{
  # 软链到 ~/.icons/，这样 GTK/Qt 应用和 GNOME Shell 都能找到。
  # 不用 home.file：素材在 store 外，home.file 会在构建时求值源路径。
  home.activation.cursorTheme = lib.hm.dag.entryAfter [ "writeBoundary" ]
    ''
      theme="$HOME/.icons/${themeName}"
      if [ ! -e "$theme" ]; then
        mkdir -p "$HOME/.icons"
        ln -sfn "${cursorSource}" "$theme"
        echo "cursor-theme: 已挂载 ${themeName}"
      fi
    '';
}
