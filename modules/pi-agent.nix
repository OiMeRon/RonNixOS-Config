# Pi agent (https://github.com/earendil-works/pi)
# Latest pre-built standalone binary (nixpkgs stable 停在 0.75.4，故从 GitHub Release 拉最新版)。
# 主命令 `pi`。
{ config, pkgs, ... }:

let
  pi-agent = pkgs.stdenv.mkDerivation rec {
    pname = "pi-agent";
    version = "0.99.1";

    src = pkgs.fetchurl {
      url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-linux-x64.tar.gz";
      sha256 = "c81b9a367bb2985fa45a2c0d4f12b147acc43655683910a5abf937fe22208425";
    };

    nativeBuildInputs = [
      pkgs.gnutar
      pkgs.makeWrapper
    ];

    # 这个二进制是 bun build --compile 的单文件可执行文件，内嵌模块图用尾部偏移
    # 定位代码。两个开关都必须开：
    #  - dontStrip：stdenv 的 fixupPhase 会对 $out/libexec 也跑 `strip -S -p`，
    #    改写文件后内嵌偏移失效，二进制不报错而是**退化成 Bun 自己的 CLI**
    #    （pi --version 打印 Bun 版本 1.3.14、pi --help 打印 Bun 的 Usage）。
    #    这是本次安装踩的最隐蔽的一个坑：构建日志不报错，运行才暴露。
    #  - dontPatchELF：patchelf 同样不该碰它，且 $out/bin 里是 wrapper 脚本。
    dontStrip = true;
    dontPatchELF = true;

    unpackPhase = ''
      tar xzf $src
    '';

    # tar 里是顶层 pi/ 目录，不是裸的 pi 文件（2026-09-30 实测踩过：
    # `cp pi $out/bin/pi` 报 "cp: -r not specified; omitting directory 'pi'"）。
    installPhase = ''
      runHook preInstall
      # 整棵树一起装：主程序靠同目录的 theme/*.json、assets/、
      # native/linux/prebuilds/linux-x64/*.node、photon_rs_bg.wasm、
      # package.json 加载资源，所以不能让它们和二进制分开。
      # cp -r 不会自建中间目录，$out/libexec 得先有
      mkdir -p $out/libexec
      cp -r pi $out/libexec/pi
      chmod +x $out/libexec/pi/pi
      # makeWrapper 生成的脚本默认就是 exec 目标 + "$@"，
      # argv[0] 语义和上游 tarball 直接运行一致（$out/bin 里放裸二进制会让
      # strip 去改它，见上面的 dontStrip）。
      makeWrapper $out/libexec/pi/pi $out/bin/pi
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Pi interactive coding agent CLI";
      homepage = "https://pi.dev/";
      license = licenses.mit;
      mainProgram = "pi";
      platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    };
  };
in
{
  environment.systemPackages = [ pi-agent ];
}
