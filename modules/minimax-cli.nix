{ pkgs, ... }:

let
  minimax-cli = pkgs.buildNpmPackage rec {
    pname = "minimax-cli";
    version = "0.0.2";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
      hash = "sha256-ZAdqRd1qfR7sLxBNmuEfv4eaOeGv3bF/YC4fmbmLYBY=";
    };

    postPatch = "cp ${./minimax-cli-package-lock.json} package-lock.json";

    npmDepsHash = "sha256-GpwfrjNDIV79NKKHHJnAUAl4g8GebhLgo3nCDTzkKA8=";

    dontBuild = true;

    meta = {
      description = "Conversational AI CLI powered by MiniMax";
      homepage = "https://github.com/Dakkshin/minimax-cli";
      license = pkgs.lib.licenses.unfree;
      mainProgram = "minimax";
    };
  };
in
{
  home-manager.users.ron.home.packages = [ minimax-cli ];
}
