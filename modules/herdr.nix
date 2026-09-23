# Herdr — 终端里的 agent 工作区管理器（智能体复用器）
#
# 上游：https://herdr.dev  ·  https://github.com/herdrdev/herdr
# 定位：tmux 的 agent 特化替代品。后台服务器持有 PTY，关客户端 / SSH 断线
#       agent 继续跑；tmux 风格前缀键 + 鼠标（点击/拖动/分割）。
#
# 为什么打预编译二进制、不从源码构建：
#   1. 官方 Linux 产物是**静态链接**的（实测无 PT_INTERP），在这台 NixOS 上
#      直接就能跑，不需要 autoPatchelfHook、不需要 LD_LIBRARY_PATH
#   2. 上游虽有 nix/package.nix，但走 rustPlatform.buildRustPackage 要拉
#      crates.io 依赖 + libghostty-vt 的 zig 依赖，而本机 Nix 守护进程没有
#      代理（见 ~/Data/文档/安装错误总结.md §22），源码构建的网络风险大得多
#   3. 单二进制、无 Electron，本来就是上游推荐的安装形态
#
# 网络注意：镜像要挑 —— gh-proxy.com 在无代理环境下会卡死（安装错误总结 §22.8），
#   ghfast.top 才正常。字节一致，hash 通用。
#
# ⚠ 不要用 `herdr update` / `herdr channel set` 自更新：
#   那会把新二进制装到 Nix 管不到的地方，下次 rebuild 又变回去（或更糟：
#   留下一个影子版本和 /run/current-system/sw/bin/herdr 打架）。
#   升级请改本文件的 version，hash 用报错里的新值。
#   同理：`herdr server stop` 之类的运行时操作没问题，但别用它装东西。
#
# 升级检查：curl -sS https://api.github.com/repos/herdrdev/herdr/releases/latest
#   注意 aarch64 是另一个产物名（herdr-linux-aarch64），本模块只声明 x86_64-linux。

{ lib, pkgs, ... }:

let
  version = "0.9.1";
  # 直连地址；镜像 = gh-proxy 前缀 + 直连地址
  directUrl = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-x86_64";

  # 绑定成 Nix 变量，才能在下面的 installPhase 字符串里插值
  src = pkgs.fetchurl {
    # 实测（不带代理，模拟守护进程环境，见安装错误总结 §22）：
    #   ghfast.top   2MB/3.9s  ✓ 可用
    #   gh-proxy.com 25s 下 0 字节，直接卡死  ✗
    #   ghproxy.net  25s 只下 292KB，太慢     ✗
    # 按可用性排序，全部字节一致（已逐个核对 sha256），hash 通用。
    urls = [
      "https://ghfast.top/${directUrl}"
      "https://gh-proxy.com/${directUrl}"
      directUrl
    ];
    hash = "sha256-KgL+0WvrZR7wBuHUPwSPZSyk3FitBTzS1ERQVj1cVLc=";
  };

  herdr = pkgs.stdenv.mkDerivation {
    pname = "herdr";
    inherit version src;

    # 预编译二进制，没有可解压的源码树
    dontUnpack = true;

    # 上游发布的二进制要原样落地。
    # stdenv 的 fixup 阶段默认会 strip ELF —— 实测把 26207464 字节削到 26175696，
    # 差异在第 41 字节（ELF 的 e_shoff，section header 表偏移），即删了节表。
    # 对静态二进制通常无害（实测 strip 后也能跑），但没必要：
    # 保留上游原始字节，出问题时更容易和上游产物逐字节对照。
    dontStrip = true;

    nativeBuildInputs = [ pkgs.installShellFiles ];

    installPhase = ''
      runHook preInstall

      install -Dm755 ${src} $out/bin/herdr

      # 补全脚本离线生成（实测无副作用：不建目录、不连后台服务）。
      # 构建沙箱里 $HOME 未必有定义，显式给一个。
      export HOME=$TMPDIR
      # 更正：这里一度写成「bash 只认文件名 == 命令名」—— **那是错的**。
      # bash-completion 的 _comp_load 同时找 `<cmd>` 和 `<cmd>.bash`
      # （源码 bash_completion 第 3459 行），实测两种命名都能注册补全。
      # 所以 installShellCompletion 的 --cmd 形式也是对的；这里保留显式文件名只为直观。
      $out/bin/herdr completion bash > herdr
      $out/bin/herdr completion zsh  > _herdr
      $out/bin/herdr completion fish > herdr.fish
      installShellCompletion --bash herdr
      installShellCompletion --zsh  _herdr
      installShellCompletion --fish herdr.fish

      runHook postInstall
    '';

    meta = {
      description = "Terminal workspace manager for AI coding agents";
      longDescription = ''
        Keeps agent terminals alive in a background server so work survives
        closing the client or losing SSH. tmux-style prefix keys plus mouse
        click/drag/split, plugin system, and a socket API agents can drive.
      '';
      homepage = "https://herdr.dev";
      license = lib.licenses.asl20;
      mainProgram = "herdr";
      platforms = [ "x86_64-linux" ];
      # 预编译二进制，非从源码构建 —— NixOS 的卫生要求
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };
in
{
  environment.systemPackages = [ herdr ];
}
