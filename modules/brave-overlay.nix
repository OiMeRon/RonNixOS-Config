{ pkgs, lib, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      brave-beta = let
        rpath = prev.lib.makeLibraryPath [
          final.alsa-lib final.at-spi2-atk final.at-spi2-core final.atk
          final.cairo final.cups final.dbus final.expat final.fontconfig
          final.freetype final.gdk-pixbuf final.glib final.gtk3 final.gtk4
          final.libdrm final.libGL final.libX11 final.libxkbcommon
          final.libXScrnSaver final.libXcomposite final.libXcursor
          final.libXdamage final.libXext final.libXfixes final.libXi
          final.libXrandr final.libXrender final.libxshmfence final.libXtst
          final.libuuid final.libgbm final.nspr final.nss final.pango
          final.pipewire final.udev final.wayland final.libxcb final.zlib
          final.snappy final.libkrb5 final.qt6.qtbase final.libpulseaudio final.libva
        ];
      in prev.stdenv.mkDerivation rec {
        pname = "brave-beta";
        version = "1.96.54";

        src = prev.fetchurl {
          url = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-browser-beta_${version}_amd64.deb";
          hash = "sha256-Q+IEI+bJ9Md/obb47woNt9Rl6GE1o0uiOQtFiKD4DE0=";
        };

        dontConfigure = true;
        dontBuild = true;
        dontPatchELF = true;

        nativeBuildInputs = [ final.dpkg final.buildPackages.wrapGAppsHook3 ];
        buildInputs = [ final.glib final.gsettings-desktop-schemas final.gtk3 final.gtk4 final.adwaita-icon-theme ];

        installPhase = ''
          runHook preInstall
          mkdir -p $out $out/bin
          cp -R usr/share $out
          cp -R opt/ $out/opt

          substituteInPlace $out/opt/brave.com/brave-beta/brave-browser-beta \
            --replace-fail /bin/bash ${prev.stdenv.shell} \
            --replace-fail 'CHROME_WRAPPER' 'WRAPPER'
          ln -sf $out/opt/brave.com/brave-beta/brave-browser-beta $out/bin/brave-beta

          for exe in $out/opt/brave.com/brave-beta/{brave,chrome_crashpad_handler}; do
            patchelf \
              --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
              --set-rpath "${rpath}" $exe
          done

          for f in $out/share/applications/{brave-browser-beta.desktop,com.brave.Browser.beta.desktop}; do
            substituteInPlace $f \
              --replace-fail /usr/bin/brave-browser-beta $out/bin/brave-beta \
              --replace-fail "Icon=brave-browser-beta" "Icon=brave-browser"
          done
          substituteInPlace $out/share/gnome-control-center/default-apps/brave-browser-beta.xml \
            --replace-fail /opt/brave.com $out/opt/brave.com
          substituteInPlace $out/opt/brave.com/brave-beta/default-app-block \
            --replace-fail /opt/brave.com $out/opt/brave.com

          for size in 16 24 32 48 64 128 256; do
            mkdir -p $out/share/icons/hicolor/$size\x$size/apps
            ln -s $out/opt/brave.com/brave-beta/product_logo_''${size}_beta.png \
              $out/share/icons/hicolor/$size\x$size/apps/brave-browser.png
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

        meta = with lib; {
          homepage = "https://brave.com/";
          description = "Privacy-oriented browser (Beta channel)";
          license = licenses.mpl20;
          platforms = [ "x86_64-linux" "aarch64-linux" ];
          mainProgram = "brave-beta";
        };
      };
    })
  ];
}
