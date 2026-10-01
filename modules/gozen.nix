# GoZen - 极简视频编辑器（Godot 引擎 + FFmpeg）
# https://github.com/VoylinsGamedevJourney/gozen (已迁至 codeberg.org/gozen/gozen)
{ config, pkgs, ... }:

let
  gozenWrapper = pkgs.writeShellScriptBin "gozen" ''
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
        pkgs.udev pkgs.mesa pkgs.icu pkgs.libepoxy
      ]
    }:$LD_LIBRARY_PATH

    export ELECTRON_OZONE_PLATFORM_HINT=wayland

    cd ~/OmniStudio/Applications/AppImage
    exec ${pkgs.appimage-run}/bin/appimage-run \
      ./gozen-v0.12-alpha-x86_64.AppImage \
      --enable-features=WaylandWindowDecorations \
      --no-sandbox \
      "$@"
  '';

  gozenDesktop = pkgs.makeDesktopItem {
    name = "gozen";
    desktopName = "GoZen";
    genericName = "Video Editor";
    comment = "Minimalist video editor built with Godot";
    exec = "gozen %F";
    startupNotify = true;
    startupWMClass = "GoZen";
    terminal = false;
    icon = "gozen";
    type = "Application";
    categories = [ "AudioVideo" "Video" "AudioVideoEditing" ];
    mimeTypes = [
      "video/mp4" "video/x-matroska" "video/webm" "video/avi"
      "video/quicktime" "video/x-flv" "video/x-msvideo"
      "audio/mpeg" "audio/ogg" "audio/x-wav" "audio/flac"
    ];
  };

  # 用 derivation 装进 system profile，落到 /run/current-system/sw/share/icons/，
  # 在 XDG_DATA_DIRS 里，应用程序才能查到（/usr/share/icons 不在 XDG_DATA_DIRS 里）
  gozenIconSrc = builtins.path {
    path = /home/ron/Data/apps/icons/gozen.png;
    name = "gozen-icon-src";
  };
  gozenIcon = pkgs.runCommand "gozen-icon" { } ''
    mkdir -p $out/share/icons/hicolor/128x128/apps
    cp ${gozenIconSrc} $out/share/icons/hicolor/128x128/apps/gozen.png
  '';
in
{
  environment.systemPackages = [
    gozenWrapper
    gozenDesktop
    gozenIcon
    pkgs.appimage-run
  ];
}
