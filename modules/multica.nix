# Multica CLI — 把 AI 编码 agent 当同事派活的协作平台（命令行端）
#
# 上游：https://multica.ai  ·  https://github.com/multica-ai/multica
# 定位：项目管理看板那一层 —— 给 issue 指定 agent 当 assignee，它自己领活、
#       在你自己的机器（daemon）上干、边干边评论、干完移到 review。
#       它**不带模型**，只驱动你已经装好并登录的 agent CLI（支持 26 个，含 dim）。
#
# 为什么不用 nixpkgs 的 multica-cli：
#   1. nixpkgs（stable 26.05）里是 0.3.2，nixpkgs-unstable / master 也只到 0.4.43，
#      而上游最新是 0.5.1 —— nixpkgs 的封装是社区志愿者单独维护的，永远滞后
#   2. 上游仓库**没有 flake.nix**（根目录没有任何 nix 文件），所以没有
#      `github:multica-ai/multica` 这种 input 可以加，社区也没有现成 flake
#   3. 想拿最新版只能自己封装
#
# 为什么打预编译包、不照 nixpkgs 那样 buildGoModule：
#   nixpkgs 用 buildGoModule + vendorHash，构建时要拉 Go 依赖；本机 Nix 守护进程
#   没有代理（见 ~/Data/文档/安装错误总结.md §22），大概率卡死。
#   官方 CLI 产物是**静态链接**的 Go 二进制（实测无 PT_INTERP），在这台 NixOS 上
#   直接能跑，不需要 autoPatchelfHook、不需要 LD_LIBRARY_PATH。
#
# 网络注意：镜像要挑 —— gh-proxy.com 在无代理环境下会卡死（安装错误总结 §22.8），
#   ghfast.top 才正常。字节一致，hash 通用。
#
# ⚠ 不要用 `multica ... update` 之类的自更新（如果有）：
#   那会把新二进制装到 Nix 管不到的地方。升级请改本文件的 version，
#   hash 用报错里的新值。
#
# 升级检查：
#   curl -sS https://api.github.com/repos/multica-ai/multica/releases/latest
#   hash: nix-hash --type sha256 --flat --sri <下载的 tar.gz>
#   注意产物名带版本号：multica-cli-<version>-linux-amd64.tar.gz（aarch64 是另一个）

{ lib, pkgs, ... }:

let
  version = "0.5.1";
  # 直连地址；镜像 = 镜像前缀 + 直连地址
  directUrl = "https://github.com/multica-ai/multica/releases/download/v${version}"
    + "/multica-cli-${version}-linux-amd64.tar.gz";

  # 绑定成 Nix 变量，才能在下面的 installPhase 字符串里插值
  src = pkgs.fetchurl {
    urls = [
      "https://ghfast.top/${directUrl}"
      "https://gh-proxy.com/${directUrl}"
      directUrl
    ];
    hash = "sha256-N/Ek8fRTZRj5PS2LxajDKqjX8dVgRchOb82QiwL9FQk=";
  };

  multica = pkgs.stdenv.mkDerivation {
    pname = "multica-cli";
    inherit version src;

    # 预编译二进制，要原样落地：stdenv 的 fixup 阶段默认会 strip ELF，
    # 把上游产物改掉（安装错误总结 §22.9）。
    dontStrip = true;

    # 这个 tar 根目录全是文件（multica / LICENSE / NOTICE / README…），**没有目录**。
    # stdenv 只在顶层目录里推断 sourceRoot（stdenv setup 第 1343-1363 行）：
    #   0 个目录 → "unpacker appears to have produced no directories"
    #   多个目录 → "unpacker produced multiple directories"
    # 但该推断是 `elif [ -z "$sourceRoot" ]` —— 预先设好就整个跳过。
    # 所以正解是显式声明，而不是覆盖 unpackPhase（安装错误总结 §22.5）。
    sourceRoot = ".";

    nativeBuildInputs = [ pkgs.installShellFiles ];

    installPhase = ''
      runHook preInstall

      install -Dm755 multica $out/bin/multica

      # 补全脚本离线生成（实测无副作用：不建目录、不连服务）。
      # --cmd 形式下 bash 会装成 multica.bash、zsh 装成 _multica、fish 装成 multica.fish
      # —— 都是对的：bash-completion 的 _comp_load 会同时找 `<cmd>` 和 `<cmd>.bash`
      # 两个名字（源码 bash_completion 第 3459 行），实测两种都能注册成功。
      export HOME=$TMPDIR
      installShellCompletion --cmd multica \
        --bash <($out/bin/multica completion bash) \
        --zsh  <($out/bin/multica completion zsh) \
        --fish <($out/bin/multica completion fish)

      install -Dm644 LICENSE $out/share/licenses/multica-cli/LICENSE
      install -Dm644 NOTICE  $out/share/licenses/multica-cli/NOTICE

      runHook postInstall
    '';

    meta = {
      description = "CLI for the Multica managed agents platform";
      longDescription = ''
        Command-line client for Multica — an open-source, self-hostable workspace
        where work is assigned to AI coding agents like teammates. Drives the
        agent CLIs you already have installed; ships no model.
      '';
      homepage = "https://multica.ai";
      changelog = "https://github.com/multica-ai/multica/releases/tag/v${version}";
      license = lib.licenses.asl20;
      mainProgram = "multica";
      platforms = [ "x86_64-linux" ];
      # 预编译二进制，非从源码构建 —— NixOS 的卫生要求
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };
in
{
  environment.systemPackages = [ multica ];
}
