{ lib, pkgs, ... }:

let
  version = "1.65.2";

  commandCode = pkgs.buildNpmPackage {
    pname = "command-code";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/command-code/-/command-code-${version}.tgz";
      hash = "sha256-LJnA8XC9Vd+ZUh0mKP7013AMchklvkGlpmA5YG+s/hY=";
    };

    postPatch = ''
      cp ${./command-code-package-lock.json} package-lock.json
      ${pkgs.nodejs_24}/bin/npm pkg delete devDependencies
    '';

    nodejs = pkgs.nodejs_24;
    npmDepsHash = "sha256-BweGfO+FZmQQ+uKI29fSdLCIHrS6HREUE7zQItFsbNU=";
    dontNpmBuild = true;
    dontStrip = true;

    meta = {
      description = "Command Code coding agent CLI";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "command-code";
    };
  };
in
{
  environment.systemPackages = [ commandCode ];
}
