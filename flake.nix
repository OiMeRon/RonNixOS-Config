{
  description = "Ron NixOS configuration";

  nixConfig = {
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";
    nixpkgs-unstable.url = "https://gh-proxy.com/https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
    home-manager = {
      url = "https://gh-proxy.com/https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "https://gh-proxy.com/https://github.com/0xc000022070/zen-browser-flake/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    appimage-install = {
      url = "https://gh-proxy.com/https://github.com/rxtsel/appimage-install/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, zen-browser, nixpkgs-unstable, appimage-install, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit zen-browser appimage-install;
        pkgs-unstable = import nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };
      modules = [
        ./modules/brave-overlay.nix
        ./configuration.nix
        ./modules/qq.nix
        ./modules/wechat.nix
        ./modules/gopeed.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit appimage-install; };
          home-manager.users.ron = import ./home.nix;
        }
      ];
    };
  };
}
