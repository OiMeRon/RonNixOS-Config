# QQ - 通过 AppImage 运行
# 使用 IBus 输入法（与系统一致）

{ config, pkgs, ... }:

let
  # 使用本地 AppImage（不重新下载）
  localAppImage = ./../appimages/QQ.AppImage
  
  qqWrapper = pkgs.writeShellScriptBin "qq" ''
    export LD_LIBRARY_PATH=${
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
        pkgs.udev pkgs.mesa pkgs.icu pkgs.xorg.libXrender
      ]
    }:$LD_LIBRARY_PATH

    # IBus 输入法配置
    export GTK_IM_MODULE=ibus
    export QT_IM_MODULE=ibus
    export XMODIFIERS=@im=ibus
    export ELECTRON_OZONE_PLATFORM_HINT=wayland

    cd ~/AppImages
    # --ozone-platform=wayland 与 Vulkan 不兼容，只启用窗口装饰
    exec ${pkgs.appimage-run}/bin/appimage-run ${localAppImage} \
      --enable-features=WaylandWindowDecorations \
      "$@"
  '';

  qqDesktop = pkgs.makeDesktopItem {
    name = "qq";
    desktopName = "QQ";
    genericName = "QQ";
    comment = "Tencent QQ";
    exec = "qq %U";
    startupNotify = true;
    startupWMClass = "QQ";
    terminal = false;
    icon = "qq";
    type = "Application";
    categories = [ "InstantMessaging" "Network" ];
    mimeTypes = [ "x-scheme-handler/qq" ];
  };
in
{
  environment.systemPackages = [
    qqWrapper
    qqDesktop
    pkgs.appimage-run
  ];

  # QQ 需要内核支持（inotify）
  boot.kernel.sysctl."max_user_watches" = 524288;
}
