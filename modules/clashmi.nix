# Clash Mi — 开源代理客户端（mihomo 内核，Flutter 壳）
#
# 上游：https://github.com/KaringX/clashmi  ·  官网 https://clashmi.app（其余域名均为仿冒）
# 定位：与 FlClash 共存的轻量代理 GUI；无 Linux TUN helper → 不需要 capability/wrapper，
#       纯 LD_LIBRARY_PATH 即可（与 Hiddify 的 AT_SECURE/RPATH 三层坑不同）。
#
# ── 安装模式：模式 A（解压版）──────────────────────────────────────
# 本体手动放 Applications/Extracted/clashmi/，Nix 只声明启动器 + desktop + 图标。
# 依据：~/OmniStudio/AGENTS.md、DIRECTORY.md；与 gopeed/herdr 同款。
#
# 代价：重建系统后要手动解压 AppImage；升级 = 替换文件；版本号只是注释。
#
# ── 本体信息（重下时用）────────────────────────────────────────────
#   AppImage: ~/OmniStudio/Applications/AppImage/clashmi_1.0.30.1605_linux_amd64.AppImage
#   来源: https://github.com/KaringX/clashmi/releases
#   镜像: https://ghfast.top/https://github.com/KaringX/clashmi/releases/download/...
#         （gh-proxy.com 大文件会卡死，见 安装错误总结 §22.8）
#   sha256: 10624cffc75a1ce0ca10d47a13f7fe6a783d85b67e49a32306377db1cab2ab75
#   解压:
#     cd ~/OmniStudio/Applications/AppImage
#     ./clashmi_1.0.30.1605_linux_amd64.AppImage --appimage-extract
#     mv squashfs-root ~/OmniStudio/Applications/Extracted/clashmi
#
# ── 库依赖 ─────────────────────────────────────────────────────────
# 相对 gopeed 多了 pkgs.libgcrypt（否则 libgtk 传递依赖缺 libgcrypt.so.20）。
# 插件自带的 DT_RUNPATH 指向打包机死路径，但无 capability → LD_LIBRARY_PATH 仍生效。

{ pkgs, ... }:

let
  appdir = "$HOME/OmniStudio/Applications/Extracted/clashmi";

  clashmiWrapper = pkgs.writeShellScriptBin "clashmi" ''
    if [ ! -x ${appdir}/clashmi ]; then
      echo "clashmi: 找不到本体 ${appdir}/clashmi" >&2
      echo "  这个包是模式 A：软件本体不在 Nix 里，需要手动解压 AppImage。" >&2
      echo "  重下/解压见 modules/clashmi.nix 头注释。" >&2
      exit 127
    fi

    export LD_LIBRARY_PATH="${appdir}/lib:${appdir}/usr/lib:${
      pkgs.lib.makeLibraryPath (
        with pkgs;
        [
          glib
          gtk3
          libx11
          libxcursor
          libxrandr
          libxcomposite
          libxdamage
          libxfixes
          libxinerama
          libGL
          libpulseaudio
          pipewire
          alsa-lib
          dbus
          fontconfig
          freetype
          pango
          cairo
          gdk-pixbuf
          openssl
          nspr
          nss
          at-spi2-core
          at-spi2-atk
          harfbuzz
          libdrm
          libgbm
          libuuid
          libsecret
          wayland
          zlib
          stdenv.cc.cc.lib
          libnotify
          libxrender
          libxkbcommon
          libxcb
          libxshmfence
          cups
          expat
          udev
          mesa
          icu
          libepoxy
          libgcrypt
        ]
      )
    }:$LD_LIBRARY_PATH"

    # IBus（与系统一致）
    export GTK_IM_MODULE=ibus
    export QT_IM_MODULE=ibus
    export XMODIFIERS=@im=ibus

    cd "${appdir}"
    exec ./clashmi "$@"
  '';

  clashmiDesktop = pkgs.makeDesktopItem {
    name = "clashmi";
    desktopName = "Clash Mi";
    genericName = "Clash Mi";
    comment = "Proxy client based on mihomo";
    exec = "clashmi %U";
    startupNotify = true;
    # Flutter/GTK 窗口类待 switch 后 xprop 确认；先用二进制名
    startupWMClass = "clashmi";
    terminal = false;
    icon = "clashmi";
    type = "Application";
    categories = [ "Network" ];
    keywords = [ "Clash" "Mi" "Proxy" "mihomo" ];
    mimeTypes = [
      "x-scheme-handler/clash"
      "x-scheme-handler/clashmi"
    ];
  };

  # 图标进 system profile（§19.4：不要 tmpfiles 到 /usr/share，XDG_DATA_DIRS 不含它）
  # 激活时 system.activationScripts.icon-cache 会刷新缓存
  clashmiIcons = pkgs.runCommand "clashmi-icons" { } ''
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp ${../assets/clashmi.png} $out/share/icons/hicolor/256x256/apps/clashmi.png
  '';
in
{
  environment.systemPackages = [
    clashmiWrapper
    clashmiDesktop
    clashmiIcons
  ];
}
