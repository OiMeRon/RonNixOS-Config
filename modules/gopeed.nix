# Gopeed - 下载管理器（Motrix 继任者）

{ pkgs, ... }:

let
  gopeedWrapper = pkgs.writeShellScriptBin "gopeed" ''
    # 指向 appimage-run 已解压的目录
    APPDIR=/home/ron/.cache/appimage-run/cc641ec5d2350e38cd4b955412ab0e0355ac01931e6b082404beef464d6f946c

    export LD_LIBRARY_PATH="$APPDIR/lib:$APPDIR/usr/lib:${
      pkgs.lib.makeLibraryPath [
        pkgs.glib pkgs.gtk3 pkgs.libx11 pkgs.libxcursor pkgs.libxrandr
        pkgs.libxcomposite pkgs.libxdamage pkgs.libxfixes pkgs.libxinerama
        pkgs.libGL pkgs.libpulseaudio pkgs.pipewire pkgs.alsa-lib
        pkgs.dbus pkgs.fontconfig pkgs.freetype pkgs.pango pkgs.cairo
        pkgs.gdk-pixbuf pkgs.openssl pkgs.nspr pkgs.nss
        pkgs.at-spi2-core pkgs.at-spi2-atk pkgs.harfbuzz
        pkgs.libdrm pkgs.libgbm pkgs.libuuid pkgs.libsecret
        pkgs.wayland pkgs.zlib pkgs.stdenv.cc.cc.lib
        pkgs.libnotify pkgs.libxrender pkgs.libxkbcommon
        pkgs.libxcb pkgs.libxshmfence pkgs.cups pkgs.expat
        pkgs.udev pkgs.mesa pkgs.icu pkgs.libepoxy
      ]
    }:$LD_LIBRARY_PATH"

    export ELECTRON_OZONE_PLATFORM_HINT=wayland

    cd "$APPDIR"
    exec ./gopeed \
      --enable-features=WaylandWindowDecorations \
      --no-sandbox \
      "$@"
  '';

  gopeedDesktop = pkgs.makeDesktopItem {
    name = "gopeed";
    desktopName = "Gopeed";
    genericName = "Download Manager";
    comment = "Modern download manager";
    exec = "gopeed %U";
    startupNotify = true;
    startupWMClass = "Gopeed";
    terminal = false;
    icon = "gopeed";
    type = "Application";
    categories = [ "Network" "FileTransfer" ];
    mimeTypes = [ "application/x-bittorrent" "x-scheme-handler/magnet" ];
  };
in
{
  environment.systemPackages = [
    gopeedWrapper
    gopeedDesktop
    pkgs.appimage-run
  ];

  # 安装图标
  systemd.tmpfiles.rules = [
    "L+ /usr/share/icons/hicolor/scalable/apps/gopeed.svg - - - - /home/ron/Data/apps/icons/gopeed.svg"
  ];
}
