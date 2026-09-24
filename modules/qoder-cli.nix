{ config, pkgs, ... }:

let
  version = "1.1.62";

  qoderCli = pkgs.stdenvNoCC.mkDerivation {
    pname = "qoder-cli";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://qoder-ide.oss-accelerate.aliyuncs.com/qodercli/releases/${version}/qodercli-linux-x64.tar.gz";
      hash = "sha256-uKv5qYNgK8ergGgziKwgRnEfI3uxOJRp/DiO3+R9ll8=";
    };

    sourceRoot = ".";
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/libexec/qoder-cli $out/bin
      cp -r . $out/libexec/qoder-cli/
      ln -s $out/libexec/qoder-cli/qodercli $out/bin/qodercli
      ln -s $out/libexec/qoder-cli/qodercli $out/bin/qoder
      runHook postInstall
    '';

    meta = {
      description = "Qoder CLI terminal coding assistant";
      homepage = "https://qoder.com/cli";
      platforms = [ "x86_64-linux" ];
      mainProgram = "qoder";
    };
  };
in
{
  assertions = [
    {
      assertion = config.programs.nix-ld.enable;
      message = "qoder-cli requires programs.nix-ld.enable = true.";
    }
  ];

  environment.systemPackages = [ qoderCli ];
}
