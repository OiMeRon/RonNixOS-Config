# Tolaria - 应用容器/沙箱管理工具

{ pkgs, ... }:

let
  # 用 buildFHSEnv 创建完整 FHS 环境
  tolariaFHS = pkgs.buildFHSEnv {
    name = "tolaria-fhs";
    targetPkgs = pkgs: with pkgs; [
      fontconfig freetype xorg.libX11 xorg.libXcursor xorg.libXrandr
      xorg.libXcomposite xorg.libXdamage xorg.libXfixes xorg.libXinerama
      xorg.libXrender xorg.libxcb libxshmfence libxkbcommon
      glib cairo pango gdk-pixbuf atk harfbuzz openssl icu libxml2
      libsoup_3 sqlite brotli libsecret libnotify dbus cups pipewire
      alsa-lib libpulseaudio libdrm libgbm libGL mesa udev krb5
      libgpg-error libgcrypt libassuan fribidi libepoxy webkitgtk_4_1
      at-spi2-core at-spi2-atk gsettings-desktop-schemas
    ];
    runScript = "bash -c 'export GDK_BACKEND=wayland; export WAYLAND_DISPLAY=wayland-0; exec ~/.cache/appimage-run/4f4d54bd35877bc7f49c6becad4e6dc6c982bf7f464b374d086e6e44e2979323/AppRun.wrapped --no-sandbox \"$@\"'";
  };

  tolariaWrapper = pkgs.writeShellScriptBin "tolaria" ''
    APPDIR=~/.cache/appimage-run/4f4d54bd35877bc7f49c6becad4e6dc6c982bf7f464b374d086e6e44e2979323
    if [ ! -d "$APPDIR" ]; then
      mkdir -p ~/.cache/appimage-run
      cd ~/.cache/appimage-run
      appimage-run ~/OmniStudio/Applications/AppImage/Tolaria_2026.9.8_amd64.AppImage --appimage-extract >/dev/null 2>&1 || true
    fi
    exec ${tolariaFHS}/bin/tolaria-fhs
  '';

  tolariaDesktop = pkgs.makeDesktopItem {
    name = "tolaria";
    desktopName = "Tolaria";
    genericName = "App Container";
    comment = "Application container and sandbox manager";
    exec = "tolaria %U";
    startupNotify = true;
    startupWMClass = "Tolaria";
    terminal = false;
    icon = "tolaria";
    type = "Application";
    categories = [ "Utility" "System" ];
  };
in
{
  environment.systemPackages = [
    tolariaWrapper
    tolariaDesktop
    pkgs.appimage-run
  ];

  systemd.tmpfiles.rules = [
    "L+ /usr/share/icons/hicolor/256x256/apps/tolaria.png - - - - /home/ron/.cache/appimage-run/4f4d54bd35877bc7f49c6becad4e6dc6c982bf7f464b374d086e6e44e2979323/tolaria.png"
  ];
}
