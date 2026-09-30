# Magnitude CLI - 开源 AI 推理引擎（给 Pi / Claude Code / Cline 做本地模型后端）
# https://github.com/magnitudedev/magnitude
{ pkgs, ... }:

let
  magnitude-cli = pkgs.stdenv.mkDerivation rec {
    pname = "magnitude-cli";
    version = "0.2.1";

    src = pkgs.fetchurl {
      url = "https://github.com/magnitudedev/magnitude/releases/download/%40magnitudedev/cli%40${version}/magnitude-cli-linux-x64-gnu.tar.gz";
      sha256 = "0vqvchw7g3lrzxxmcfdppgdnclksvywl02kgw116hm587h81k5mc";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    # bun/tauri 单文件编译二进制，不能 strip 或 patchelf
    dontStrip = true;
    dontPatchELF = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      tar xzf $src -C $out/bin --strip-components=1
      chmod +x $out/bin/magnitude-cli
      # 包装为 `magnitude` 命令
      makeWrapper $out/bin/magnitude-cli $out/bin/magnitude
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Open source inference engine for AI agents, optimized for your hardware";
      homepage = "https://github.com/magnitudedev/magnitude";
      license = licenses.asl20;
      mainProgram = "magnitude";
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  environment.systemPackages = [ magnitude-cli ];
}
