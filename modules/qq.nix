# QQ - 通过 nixpak 沙盒化运行
# 使用 IBus 输入法（与系统一致）

{ config, pkgs, inputs, ... }:

let
  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit pkgs;
    inherit (pkgs) lib;
  };

  appId = "com.tencent.QQ";

  wrapped = mkNixPak {
    config =
      { sloth, ... }:
      {
        app.package = pkgs.qq;
        app.binPath = "bin/qq";
        flatpak.appId = appId;
        fonts.enable = false;

        dbus.enable = true;
        dbus.policies = {
          "org.freedesktop.portal.Notification" = "talk";
          "org.freedesktop.portal.Settings" = "talk";
          "org.freedesktop.portal.Screenshot" = "talk";
          "org.freedesktop.Notifications" = "talk";
          "ca.desrt.dconf" = "talk";
          "org.kde.StatusNotifierWatcher" = "talk";
          "org.freedesktop.StatusNotifierHost" = "own";
        };

        etc.sslCertificates.enable = true;

        gpu.enable = true;
        gpu.provider = "bundle";

        bubblewrap = {
          network = true;

          env = {
            GTK_IM_MODULE = "ibus";
            QT_IM_MODULE = "ibus";
            XMODIFIERS = "@im=ibus";
            ELECTRON_OZONE_PLATFORM_HINT = "wayland";
          };

          bind.dev = [
            "/dev/dri"
            "/dev/snd"
            "/dev/shm"
            "/dev/video0"
          ];

          bind.rw = with sloth; [
            (sloth.concat [
              sloth.runtimeDir
              "/"
              (sloth.envOr "WAYLAND_DISPLAY" "no")
            ])
            (sloth.concat' sloth.runtimeDir "/at-spi/bus")
            (sloth.concat' sloth.runtimeDir "/gvfsd")
            (sloth.concat' sloth.runtimeDir "/dconf")

            (sloth.concat' sloth.xdgCacheHome "/fontconfig")
            (sloth.concat' sloth.xdgCacheHome "/mesa_shader_cache")
            (sloth.concat' sloth.xdgCacheHome "/mesa_shader_cache_db")
            (sloth.concat' sloth.xdgCacheHome "/radv_builtin_shaders")

            (sloth.env "XDG_RUNTIME_DIR")
            (sloth.mkdir "/tmp/QQ")

            (sloth.concat' sloth.runtimeDir "/doc")

            # QQ 配置和数据
            [
              (sloth.mkdir (sloth.concat' sloth.homeDir "/data/Programs/Chat/qq/config"))
              (sloth.concat' sloth.homeDir "/.config/QQ")
            ]

            # QQ 下载文件
            [
              (sloth.mkdir (sloth.concat' sloth.homeDir "/data/Soft_tmp/Chat/qq/Downloads"))
              (sloth.concat' sloth.homeDir "/Downloads")
            ]
          ];

          bind.ro = [
            (sloth.concat' sloth.xdgConfigHome "/kdeglobals")
            (sloth.concat' sloth.xdgConfigHome "/gtk-2.0")
            (sloth.concat' sloth.xdgConfigHome "/gtk-3.0")
            (sloth.concat' sloth.xdgConfigHome "/gtk-4.0")
            (sloth.concat' sloth.xdgConfigHome "/fontconfig")
            (sloth.concat' sloth.xdgConfigHome "/dconf")

            "/etc/fonts"
            "/etc/localtime"
            "/etc/egl"
            "/etc/static/egl"
            "/etc/static/alsa"
            "/etc/alsa"

            "/run/current-system/sw/share/mime"
            "/run/current-system/sw/share/icons"
            "/run/current-system/sw/share/applications"
            "/run/current-system/sw/share/fonts"
          ];

          sockets = {
            wayland = true;
            x11 = false;
            pipewire = true;
          };
        };
      };
  };

  qqWrapper = pkgs.writeShellScriptBin "qq-sandboxed" ''
    exec ${pkgs.lib.getExe wrapped.config.script} "$@"
  '';

  qqDesktop = pkgs.makeDesktopItem {
    name = "qq-sandboxed";
    desktopName = "QQ (Sandboxed)";
    genericName = "QQ";
    comment = "Tencent QQ - Running in nixpak sandbox";
    exec = "qq-sandboxed %U";
    startupNotify = true;
    startupWMClass = "QQ";
    terminal = false;
    icon = "${pkgs.qq}/share/icons/hicolor/512x512/apps/qq.png";
    type = "Application";
    categories = [ "InstantMessaging" "Network" ];
    mimeTypes = [ "x-scheme-handler/qq" ];
  };
in
{
  environment.systemPackages = [ qqWrapper qqDesktop ];

  # QQ 需要内核支持（可选，但推荐）
  boot.kernel.sysctl."max_user_watches" = 524288;
}
