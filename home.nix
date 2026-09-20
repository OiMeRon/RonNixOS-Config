{ appimage-install, pkgs, ... }:

{
  home.username = "ron";
  home.homeDirectory = "/home/ron";
  home.stateVersion = "26.05";

  # kimi 的路径
  home.sessionPath = [
    "/home/ron/.kimi-code/bin"
    "/home/ron/.minimax-code/releases/0.4.12/bin"
  ];

  home.packages = [
    appimage-install.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.gtk3
    pkgs.imagemagick
  ];


  # DimAgent 桌面文件
  home.file.".local/share/applications/dimagent.desktop" = {
    text = ''
      [Desktop Entry]
      Name=DimAgent
      Comment=DimAgent - Desktop Automation
      Exec=dimagent %U
      Icon=dimagent
      Type=Application
      Categories=Utility;Development;
      Terminal=false
      StartupWMClass=DimAgent
      StartupNotify=true
    '';
  };

  # Obsidian 桌面文件（修复任务栏图标）
  home.file.".local/share/applications/obsidian.desktop" = {
    text = ''
      [Desktop Entry]
      Categories=Office
      Comment=Knowledge base
      Exec=obsidian %u
      Icon=obsidian
      MimeType=x-scheme-handler/obsidian
      Name=Obsidian
      StartupWMClass=obsidian
      StartupNotify=true
      Type=Application
      Version=1.5
    '';
  };

  # Motrix 桌面文件（由 AppImage 自带，无需声明）

  programs.bash.enable = true;

  # GNOME 主题设置
  dconf.settings = {
    "org/gnome/shell/extensions/user-theme" = {
      name = "MacTahoe-Dark";
    };
    "org/gnome/desktop/interface" = {
      gtk-theme = "MacTahoe-Dark";
      icon-theme = "Adwaita";
      cursor-theme = "Adwaita";
    };

    # Rounded Window Corners Reborn 设置
    "org/gnome/shell/extensions/rounded-window-corners" = {
      corner-radius = 28;
      keep-rounded-maximized = true;
    };

    # Dash to Dock 设置
    "org/gnome/shell/extensions/dash-to-dock" = {
      background-opacity = 0.0;
      custom-background-color = false;
      apply-custom-theme = false;
      autohide = true;
      dock-fixed = false;
      dock-position = "BOTTOM";
    };

    # Liquid Glass 扩展设置
    "org/gnome/shell/extensions/liquid-glass" = {
      # 启用各元素玻璃效果
      enable-dock-glass = true;
      enable-menu-glass = true;
      enable-notification-glass = true;
      enable-quick-settings-glass = true;
      enable-osd-glass = true;
      enable-desktop-menu-glass = true;
      enable-application-glass = false;

      # Dock 设置（自适应效果）
      dock-blur-radius = 15;
      dock-corner-radius = 24;
      dock-tint-strength = 0.15;
      dock-brightness = 0.85;
      dock-tint-color = "#303030";
      dock-glass-expand = 1;
      dock-margin-bottom = 3;
      dock-saturation = 0.0;
      dock-contrast = 1.15;

      # 应用窗口设置
      application-blur-radius = 8;
      application-corner-radius = 25;
      application-tint-strength = 0.08;
      application-content-opacity = 0.8;
      application-brightness = 0.85;
      application-tint-color = "#3d3846";

      # 玻璃物理效果
      glass-ior = 2.8;
      glass-displacement-scale = 80;
      glass-edge-smoothing = 1.5;
      glass-max-z = 30;
      glass-specular-intensity = 1.2;
      glass-chroma-strength = 3.5;
      glass-profile-shape-n = 8;
      glass-blur-downscale = 2;

      # 快速设置
      quick-settings-apply-to = 0; # Background 模式
      quick-settings-tint-color = "#ffffff";
      quick-settings-tint-strength = 0.08;
      quick-settings-brightness = 0.85;
      quick-settings-enable-adaptive-text-color = true;

      # 采样设置（更快响应）
      menu-sample-interval-ms = 50;
      notification-sample-interval-ms = 50;
      quick-settings-sample-interval-ms = 50;
      osd-sample-interval-ms = 50;
      panel-menu-sample-interval-ms = 50;
      menu-sample-per-element = true;
      quick-settings-sample-per-element = true;

      # 菜单弹性
      menu-spring-stiffness = 150;
      menu-spring-damping = 40;
      menu-spring-mass = 0.25;

      # 快速设置弹性
      quick-settings-spring-stiffness = 150;
      quick-settings-spring-damping = 40;
      quick-settings-spring-mass = 0.25;

      # 面板菜单弹性
      panel-menu-spring-stiffness = 150;
      panel-menu-spring-damping = 40;
      panel-menu-spring-mass = 0.25;
    };
  };

  # 确保应用图标可见（系统 hicolor 缓存只读，用户级兜底）
  home.file."local/share/icons/hicolor/index.theme" = {
    text = ''
      [Icon Theme]
      Name=hicolor
      Comment=Fallback icon theme
      Directories=16x16/apps,32x32/apps,48x48/apps,64x64/apps,128x128/apps,256x256/apps,512x512/apps

      [16x16/apps]
      Size=16
      Type=Threshold

      [32x32/apps]
      Size=32
      Type=Threshold

      [48x48/apps]
      Size=48
      Type=Threshold

      [64x64/apps]
      Size=64
      Type=Threshold

      [128x128/apps]
      Size=128
      Type=Threshold

      [256x256/apps]
      Size=256
      Type=Threshold

      [512x512/apps]
      Size=512
      Type=Threshold
    '';
  };

  # 自动提交脚本
  home.file.".local/bin/git-sync" = {
    source = pkgs.writeShellScript "git-sync" ''
      #!/usr/bin/env bash
      set -e
      cd ~/nixos-config
      git add -A
      if git diff --cached --quiet; then
        echo "无变更"
      else
        git commit -m "sync: $(date '+%Y-%m-%d %H:%M:%S')"
        git push
        echo "已提交并推送"
      fi
    '';
    executable = true;
  };

  # 定时自动同步（每 30 分钟检查一次）
  systemd.user.timers.git-sync = {
    Unit.Description = "Auto-sync NixOS config to GitHub";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "30min";
    };
    Install.WantedBy = [ "timers.target" ];
  };
  systemd.user.services.git-sync = {
    Unit.Description = "Sync NixOS config to GitHub";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'cd /home/ron/nixos-config && ${pkgs.git}/bin/git add -A && (${pkgs.git}/bin/git diff --cached --quiet || (${pkgs.git}/bin/git commit -m \"auto: $(date +%Y-%m-%d_%H:%M)\" && ${pkgs.git}/bin/git push))'";
    };
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "Ron";
      email = "1757093971@qq.com";
    };
  };
}
