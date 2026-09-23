# Multica CLI — 把 AI 编码 agent 当同事派活的协作平台（命令行端）
#
# 上游：https://multica.ai  ·  https://github.com/multica-ai/multica
# 定位：项目管理看板那一层 —— 给 issue 指定 agent 当 assignee，它自己领活、
#       在你自己的机器（daemon）上干、边干边评论、干完移到 review。
#       它**不带模型**，只驱动你已经装好并登录的 agent CLI（支持 26 个，含 dim）。
#
# ── 安装模式：模式 A ────────────────────────────────────────────────
# 软件本体手动放在 Applications/，Nix 只声明启动器。
# 依据：~/OmniStudio/AGENTS.md「第三方软件统一放 Applications/」
#      ~/OmniStudio/DIRECTORY.md「Applications/Extracted/ = 解压版软件」
#
# 代价：重建系统后要手动放回本体；升级 = 替换文件。
#       补全脚本改由 home.nix 的 activation 生成（构建期读不到 $HOME）。
#
# ── 本体信息（重下时用）────────────────────────────────────────────
#   目录: ~/OmniStudio/Applications/Extracted/multica/（含 multica + LICENSE/NOTICE/README）
#   来源: https://github.com/multica-ai/multica/releases/download/v0.5.1/multica-cli-0.5.1-linux-amd64.tar.gz
#   tar.gz sha256: N/Ek8fRTZRj5PS2LxajDKqjX8dVgRchOb82QiwL9FQk=（SRI）
#   解出来的 multica 是静态 Go 二进制，不需要 LD_LIBRARY_PATH
#
# 为什么不用 nixpkgs 的 multica-cli：
#   nixpkgs（stable 26.05）是 0.3.2，unstable / master 也只到 0.4.43，
#   上游最新是 0.5.1。上游仓库没有 flake.nix，社区也没有现成 flake。
#
# ⚠ 不要用自更新命令：会把新二进制装到别处。升级请替换上面那个文件。

{ pkgs, ... }:

let
  multicaDir = "$HOME/OmniStudio/Applications/Extracted/multica";

  multicaWrapper = pkgs.writeShellScriptBin "multica" ''
    if [ ! -x ${multicaDir}/multica ]; then
      echo "multica: 找不到本体 ${multicaDir}/multica" >&2
      echo "  这个包是模式 A：软件本体不在 Nix 里，需要手动放在 Applications/。" >&2
      echo "  重下：https://github.com/multica-ai/multica/releases/download/v0.5.1/multica-cli-0.5.1-linux-amd64.tar.gz" >&2
      exit 127
    fi
    exec ${multicaDir}/multica "$@"
  '';
in
{
  environment.systemPackages = [ multicaWrapper ];
}
