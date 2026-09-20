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
    nixpkgs-unstable.url = "https://gh-proxy.com/https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";
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

  outputs = { self, nixpkgs, home-manager, zen-browser, nixpkgs-unstable, appimage-install, ... }:

  let
    braveBetaOverlay = final: prev:
      let
        rpath = prev.lib.makeLibraryPath [
          final.alsa-lib
          final.at-spi2-atk
          final.at-spi2-core
          final.atk
          final.cairo
          final.cups
          final.dbus
          final.expat
          final.fontconfig
          final.freetype
          final.gdk-pixbuf
          final.glib
          final.gtk3
          final.gtk4
          final.libdrm
          final.libGL
          final.libX11
          final.libxkbcommon
          final.libXScrnSaver
          final.libXcomposite
          final.libXcursor
          final.libXdamage
          final.libXext
          final.libXfixes
          final.libXi
          final.libXrandr
          final.libXrender
          final.libxshmfence
          final.libXtst
          final.libuuid
          final.libgbm
          final.nspr
          final.nss
          final.pango
          final.pipewire
          final.udev
          final.wayland
          final.libxcb
          final.zlib
          final.snappy
          final.libkrb5
          final.qt6.qtbase
          final.libpulseaudio
          final.libva
        ];
      in {
        brave-beta = prev.stdenv.mkDerivation rec {
          pname = "brave-beta";
          version = "1.96.54";

          src = prev.fetchurl {
            url = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-browser-beta_${version}_amd64.deb";
            hash = "sha256-Q+IEI+bJ9Md/obb47woNt9Rl6GE1o0uiOQtFiKD4DE0=";
          };

          dontConfigure = true;
          dontBuild = true;
          dontPatchELF = true;

          nativeBuildInputs = [
            final.dpkg
            final.buildPackages.wrapGAppsHook3
          ];

          buildInputs = [
            final.glib
            final.gsettings-desktop-schemas
            final.gtk3
            final.gtk4
            final.adwaita-icon-theme
          ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out $out/bin

            cp -R usr/share $out
            cp -R opt/ $out/opt

            export BINARYWRAPPER=$out/opt/brave.com/brave-beta/brave-browser-beta

            substituteInPlace $BINARYWRAPPER \
                --replace-fail /bin/bash ${prev.stdenv.shell} \
                --replace-fail 'CHROME_WRAPPER' 'WRAPPER'

            ln -sf $BINARYWRAPPER $out/bin/brave-beta

            for exe in $out/opt/brave.com/brave-beta/{brave,chrome_crashpad_handler}; do
                patchelf \
                    --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
                    --set-rpath "${rpath}" $exe
            done

            substituteInPlace $out/share/applications/brave-browser-beta.desktop \
                --replace-fail /usr/bin/brave-browser-beta $out/bin/brave-beta \
                --replace-fail "Icon=brave-browser-beta" "Icon=brave-browser"
            substituteInPlace $out/share/applications/com.brave.Browser.beta.desktop \
                --replace-fail /usr/bin/brave-browser-beta $out/bin/brave-beta \
                --replace-fail "Icon=brave-browser-beta" "Icon=brave-browser"
            substituteInPlace $out/share/gnome-control-center/default-apps/brave-browser-beta.xml \
                --replace-fail /opt/brave.com $out/opt/brave.com
            substituteInPlace $out/opt/brave.com/brave-beta/default-app-block \
                --replace-fail /opt/brave.com $out/opt/brave.com

            icon_sizes=("16" "24" "32" "48" "64" "128" "256")
            for icon in ''${icon_sizes[*]}
            do
                mkdir -p $out/share/icons/hicolor/$icon\x$icon/apps
                ln -s $out/opt/brave.com/brave-beta/product_logo_''${icon}_beta.png $out/share/icons/hicolor/$icon\x$icon/apps/brave-browser.png
            done

            ln -sf ${final.xdg-utils}/bin/xdg-settings $out/opt/brave.com/brave-beta/xdg-settings
            ln -sf ${final.xdg-utils}/bin/xdg-mime $out/opt/brave.com/brave-beta/xdg-mime

            runHook postInstall
          '';

          preFixup = ''
            gappsWrapperArgs+=(
              --prefix LD_LIBRARY_PATH : ${rpath}
              --suffix PATH : ${final.lib.makeBinPath [ final.xdg-utils final.coreutils ]}
              --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"
            )
          '';

          meta = {
            homepage = "https://brave.com/";
            description = "Privacy-oriented browser (Beta channel)";
            sourceProvenance = with prev.lib.sourceTypes; [ binaryNativeCode ];
            license = prev.lib.licenses.mpl20;
            platforms = [ "x86_64-linux" "aarch64-linux" ];
            mainProgram = "brave-beta";
          };
        };
      };
  in
  {
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
        { nixpkgs.overlays = [ braveBetaOverlay ]; }
        ./configuration.nix
        ./modules/qq.nix
        ./modules/wechat.nix
        ./modules/gopeed.nix
        ./modules/tolaria.nix
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
