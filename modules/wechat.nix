# wechat（微信 4.x universal）- 直装版（无 nixpak 沙盒，适配 Wayland）
# 适配环境：Wayland + Liquid Glass + IBus + MacTahoe-Dark + Rounded Window Corners
{ config, pkgs, ... }:

let
  # 微信需要 32 位 libtiff，但 NixOS 只有 64 位，需要 patchelf 修复
  wechatPackage = let
    pname = "wechat";
    version = "4.1.13";
    # 使用本地 AppImage（不重新下载）
    localAppImage = ./../appimages/WeChat.AppImage;
    appimageContents = pkgs.appimageTools.extract {
      inherit pname version;
      src = localAppImage;
      postExtract = ''
        patchelf --replace-needed libtiff.so.5 libtiff.so $out/opt/wechat/wechat
      '';
    };
  in
  pkgs.appimageTools.wrapAppImage {
    inherit pname version;
    src = appimageContents;
    extraPkgs = pkgs: with pkgs; [
      gtk3 glib dbus fontconfig freetype pango cairo gdk-pixbuf
      openssl nspr nss at-spi2-core at-spi2-atk harfbuzz
      libdrm libgbm libsecret pipewire alsa-lib libnotify
      libxkbcommon libxcb libxshmfence cups udev mesa icu
    ];
    extraInstallCommands = ''
      mkdir -p $out/share/applications
      cp ${appimageContents}/wechat.desktop $out/share/applications/
      mkdir -p $out/share/icons/hicolor/256x256/apps
      cp ${appimageContents}/wechat.png $out/share/icons/hicolor/256x256/apps/
      substituteInPlace $out/share/applications/wechat.desktop --replace-fail AppRun wechat
    '';
  };

  # Wrapper 脚本：适配 Wayland + IBus + HiDPI
  wechatWrapper = pkgs.writeShellScriptBin "wechat" ''
    # IBus 输入法（与系统一致）
    export GTK_IM_MODULE=ibus
    export QT_IM_MODULE=ibus
    export XMODIFIERS=@im=ibus

    # Wayland 适配
    export ELECTRON_OZONE_PLATFORM_HINT=wayland

    # HiDPI 缩放（解决字体太小）
    export GDK_SCALE=2

    # 禁用 GPU 沙盒（避免 Wayland 下崩溃）
    exec ${wechatPackage}/bin/wechat \
      --no-sandbox \
      --disable-gpu-sandbox \
      --force-device-scale-factor=2 \
      "$@"
  '';

  wechatDesktop = pkgs.makeDesktopItem {
    name = "wechat";
    desktopName = "WeChat";
    genericName = "WeChat";
    comment = "Messaging and calling app";
    exec = "wechat %U";
    startupNotify = true;
    startupWMClass = "WeChat";
    terminal = false;
    icon = "wechat";
    type = "Application";
    categories = [ "InstantMessaging" "Network" ];
    mimeTypes = [ "x-scheme-handler/wechat" ];
  };

in
{
  environment.systemPackages = [
    wechatWrapper
    wechatDesktop
  ];
}
