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

    nativeBuildInputs = [ pkgs.gnutar ];

    unpackPhase = ''
      tar xzf $src
    '';

    installPhase = ''
      mkdir -p $out/bin
      # tar 内含 pi 二进制直接是可执行的
      cp pi $out/bin/pi
      chmod +x $out/bin/pi
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
