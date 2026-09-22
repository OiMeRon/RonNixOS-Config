# Hiddify — sing-box 代理客户端（AppImage 声明式封装）
#
# 依赖：programs.nix-ld.enable = true
#   AppImage 内二进制的 ELF 解释器是 /lib64/ld-linux-x86-64.so.2；
#   该路径在 NixOS 上由 nix-ld 提供软链（实测 /lib64/ld-linux-x86-64.so.2 -> nix-ld）。
#   没有 nix-ld 这些二进制根本无法启动；但库仍需 LD_LIBRARY_PATH 提供
#   （裸跑实测报 libgtk-3.so.0 找不到）。文件末尾有 assertion 守住这个前提。
#
# TUN 模式（capability 方案）：
#   Hiddify 的内核 libbox（sing-box）跑在 app 进程内部，不是独立进程
#   （实测：运行中只有 hiddify 一个进程，无 HiddifyCli）。
#   所以无法"只给内核授权"，只能给整个 app 二进制加 capability ——
#   与 programs.clash-verge 的 tunMode 同款做法（security.wrappers）。
#   注意：该方案下 DNS 设置受限（同 clash 模块 tunMode 的注解）。
#
# 未用 appimage-run：其 FHS 环境缺 libepoxy（实测 appimage-run 直接跑报
#   libepoxy.so.0 找不到），故走「解压 + 完整 LD_LIBRARY_PATH」。
#   详见 ~/Data/文档/安装错误总结.md §13 / §19。

{ config, lib, pkgs, ... }:

let
  version = "4.1.1";

  src = pkgs.fetchurl {
    url = "https://github.com/hiddify/hiddify-app/releases/download/v${version}/Hiddify-Linux-x64-AppImage.AppImage";
    hash = "sha256-6yu2wIlxuY4tCgH8W2R+KboXsWYRScyfl+2g53v1vcM=";
  };

  # 解压到 store（不走 appimage-run 的 FHS）
  appimage = pkgs.appimageTools.extract {
    pname = "hiddify";
    inherit version src;
  };

  # 运行期库：AppImage 只自带 curl/krb5/ldap 那一批，
  # GTK/Flutter 需要的全部要从系统来。
  # 用 lib.makeLibraryPath（内部走 getLib），多输出包如 brotli 会自动取 lib 输出
  # —— 见安装错误总结 §19.2。
  runtimeLibs = with pkgs; [
    libepoxy brotli gtk3 gdk-pixbuf glib glib-networking pango cairo atk harfbuzz
    fontconfig freetype libpng libjpeg zlib libffi pcre2 libthai libdatrie libselinux
    libxkbcommon wayland mesa libglvnd libsecret keybinder3 libayatana-appindicator
    libsoup_3 at-spi2-core dbus cups alsa-lib libpulseaudio json-glib libxml2
    libgcrypt libgpg-error libx11 libxcb libXext libXfixes libXrandr libXrender
    libXinerama libXi libXtst libxcursor libXdamage libXcomposite libxshmfence
    libdrm libgbm expat libuuid udev nspr nss openssl icu
  ];

  # 启动器：设库路径 → 转到带 capability 的 wrapper（/run/wrappers/bin/hiddify-app）
  hiddify = pkgs.writeShellScriptBin "hiddify" ''
    APPDIR=${appimage}
    export LD_LIBRARY_PATH="$APPDIR/lib:$APPDIR/usr/lib:${
      pkgs.lib.makeLibraryPath runtimeLibs
    }:''${LD_LIBRARY_PATH:-}"
    cd "$APPDIR"
    exec /run/wrappers/bin/hiddify-app "$@"
  '';

  # 字段照 AppImage 自带的 hiddify.desktop 抄
  hiddifyDesktop = pkgs.makeDesktopItem {
    name = "hiddify";
    desktopName = "Hiddify";
    genericName = "Proxy Client";
    comment = "Multi-platform auto-proxy client (sing-box core)";
    exec = "hiddify %u";
    icon = "hiddify";
    terminal = false;
    type = "Application";
    startupNotify = true;
    startupWMClass = "app.hiddify.com";
    categories = [ "Network" ];
    mimeTypes = [
      "x-scheme-handler/hiddify"
      "x-scheme-handler/v2ray"
      "x-scheme-handler/v2rayn"
      "x-scheme-handler/v2rayng"
      "x-scheme-handler/clash"
      "x-scheme-handler/clashmeta"
      "x-scheme-handler/sing-box"
    ];
    actions = {
      start = {
        name = "Start";
        exec = "hiddify --start %u";
      };
      stop = {
        name = "Stop";
        exec = "hiddify --stop %u";
      };
    };
  };

  # 图标装进 system profile 的 hicolor（/usr/share 不在 XDG_DATA_DIRS 里，
  # 也不会被 system.activationScripts.icon-cache 覆盖）—— 见安装错误总结 §19.4
  hiddifyIcon = pkgs.runCommand "hiddify-icon" { } ''
    mkdir -p $out/share/icons/hicolor/1024x1024/apps
    cp ${appimage}/hiddify.png $out/share/icons/hicolor/1024x1024/apps/hiddify.png
  '';
in
{
  # AppImage 二进制靠 nix-ld 提供 ELF 解释器
  assertions = [
    {
      assertion = config.programs.nix-ld.enable;
      message = ''
        Hiddify 的 AppImage 二进制需要 programs.nix-ld.enable = true：
        ELF 解释器 /lib64/ld-linux-x86-64.so.2 在 NixOS 上由 nix-ld 提供软链。
      '';
    }
  ];

  # TUN 提权：给整个 app 二进制加网络能力
  # （内核 libbox 跑在进程内，无法单独授权；与 clash-verge 的 tunMode 同款）
  # 命名 hiddify-app 以免与启动器脚本 hiddify 在 PATH 上撞名
  security.wrappers.hiddify-app = {
    owner = "root";
    group = "root";
    capabilities = "cap_net_bind_service,cap_net_raw,cap_net_admin=+ep";
    source = "${appimage}/hiddify";
  };

  environment.systemPackages = [
    hiddify
    hiddifyDesktop
    hiddifyIcon
  ];
}
