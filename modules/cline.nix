# Cline CLI - 终端 AI 编码助手（https://github.com/cline/cline）
#
# 官方 npm 包只发布平台二进制：@cline/cli-linux-x64，
# 已内嵌 Bun，运行时不依赖 node/bun，也不需要 patchelf（只链 glibc）。

{ pkgs, ... }:

let
  version = "3.0.62";

  clineCli = pkgs.stdenvNoCC.mkDerivation {
    pname = "cline-cli";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@cline/cli-linux-x64/-/cli-linux-x64-${version}.tgz";
      hash = "sha256-8f32Taueo3VG/jlmKtAzZxLjFJfu6VT9ggA9fHmzUyA=";
    };

    sourceRoot = "package";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/libexec/cline $out/bin
      cp -r . $out/libexec/cline/

      # 软链而非 wrapper：保留 bin/cline 与 cline-hub/、extensions/ 的相对位置
      ln -s $out/libexec/cline/bin/cline $out/bin/cline

      runHook postInstall
    '';

    meta = {
      description = "Autonomous coding agent CLI";
      homepage = "https://github.com/cline/cline";
      platforms = [ "x86_64-linux" ];
      mainProgram = "cline";
    };
  };
in
{
  environment.systemPackages = [
    clineCli
  ];
}
