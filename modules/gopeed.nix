# Gopeed - 下载管理器（Motrix 继任者）

{ pkgs, ... }:

let
  gopeedWrapper = pkgs.writeShellScriptBin "gopeed" ''
    # 2026-09-23 修正：原来这里写死 ~/.cache/appimage-run/<hash>/ ——
    # 那是 appimage-run 的**缓存**目录，被清掉（清理工具 / 重装系统 /
    # 手动删 ~/.cache）gopeed 就直接废。现在本体放 Applications/Extracted/gopeed/
    # （稳定路径），符合 ~/OmniStudio/DIRECTORY.md「Extracted/ = 解压版软件」。
    # 迁移时把原缓存目录整体复制过来，所以下载记录/设置没丢。
    APPDIR="$HOME/OmniStudio/Applications/Extracted/gopeed"

    if [ ! -x "$APPDIR/gopeed" ]; then
      echo "gopeed: 找不到本体 $APPDIR/gopeed" >&2
      echo "  从 AppImage 重新解压：" >&2
      echo "    cd ~/OmniStudio/Applications/AppImage" >&2
      echo "    ./Gopeed-v1.9.3-linux-amd64.AppImage --appimage-extract" >&2
      echo "    mv squashfs-root ~/OmniStudio/Applications/Extracted/gopeed" >&2
      exit 127
    fi

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
