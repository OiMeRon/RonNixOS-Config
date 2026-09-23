# Herdr — 终端里的 agent 工作区管理器（智能体复用器）
#
# 上游：https://herdr.dev  ·  https://github.com/herdrdev/herdr
# 定位：tmux 的 agent 特化替代品。后台服务器持有 PTY，关客户端 / SSH 断线
#       agent 继续跑；tmux 风格前缀键 + 鼠标。
#
# ── 安装模式：模式 A ────────────────────────────────────────────────
# 软件本体手动放在 Applications/，Nix 只声明启动器。
# 依据（本仓库既有结构）：
#   ~/OmniStudio/AGENTS.md     「第三方软件统一放 Applications/」
#   ~/OmniStudio/DIRECTORY.md  「Applications/Extracted/ = 解压版软件」
#   configuration.nix 的 motrix-wrapper / dimagent-wrapper 是同一模式
#
# 代价（选这个模式就是接受它）：
#   - 重建系统后要手动把二进制放回去，Nix 不会自动下载
#   - 升级 = 替换那个文件；这里的版本号只是注释，不参与构建
#   - 补全脚本没法在构建时生成（Nix 沙箱读不到 $HOME），
#     改由 home.nix 的 activation 在每次 switch 时生成
#
# ── 本体信息（重下时用）────────────────────────────────────────────
#   文件: ~/OmniStudio/Applications/Extracted/herdr/herdr
#   来源: https://github.com/herdrdev/herdr/releases/download/v0.9.1/herdr-linux-x86_64
#   sha256: 2a02fed16beb651ef006e1d43f048f652ca4dc58ad053cd2d44450563d5c54b7
#   静态链接（无 PT_INTERP），不需要 LD_LIBRARY_PATH
#   镜像注意：gh-proxy.com 在无代理环境下会卡死，用 ghfast.top（安装错误总结 §22.8）
#
# ⚠ 不要用 `herdr update` / `herdr channel set` 自更新：
#   那会把新二进制装到别处，和这里的本体打架。升级请替换上面那个文件。

{ pkgs, ... }:

let
  # 和 motrixPath / dimagentPath 同款写法：字符串形式的 $HOME 路径，
  # 在 wrapper 脚本里由 shell 展开（不是 Nix 构建期展开）
  herdrDir = "$HOME/OmniStudio/Applications/Extracted/herdr";

  herdrWrapper = pkgs.writeShellScriptBin "herdr" ''
    if [ ! -x ${herdrDir}/herdr ]; then
      echo "herdr: 找不到本体 ${herdrDir}/herdr" >&2
      echo "  这个包是模式 A：软件本体不在 Nix 里，需要手动放在 Applications/。" >&2
      echo "  重下：https://github.com/herdrdev/herdr/releases/download/v0.9.1/herdr-linux-x86_64" >&2
      exit 127
    fi
    exec ${herdrDir}/herdr "$@"
  '';
in
{
  environment.systemPackages = [ herdrWrapper ];
}
