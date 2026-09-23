{ appimage-install, pkgs, lib, config, ... }:

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

    # 默认终端：GNOME 出厂值指向系统里不存在的 xdg-terminal-exec，
    # 这里显式指到 Ghostty（-e 才是 Ghostty 的执行参数，不是 schema 默认的 --）
    "org/gnome/desktop/default-applications/terminal" = {
      exec = "ghostty";
      exec-arg = "-e";
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

      # Dock 设置
      dock-blur-radius = 12;
      dock-corner-radius = 24;
      dock-tint-strength = 0.25;
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

  # ── agent 文档：源在仓库，各 agent 的读取路径做软链接 ──────────────
  # 7 个入口全部指向同一份源，不存在副本。
  #
  # 用 mkOutOfStoreSymlink 指向**仓库工作区**，不是 store —— 这是关键：
  # 文档要保持可写（MEMORY.md / NIXOS-OPS.md 由 agent 持续更新），
  # 又要受 git 版本控制。普通的 home.file.<path>.source 会把内容复制进
  # store 变成只读，那会直接打断 agent 更新记忆的流程。
  # 代价：改文档改的是仓库里那份，要 rebuild 才生效（软链接本身由 Nix 管）。
  home.file.".kimi-code/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "/home/ron/nixos-config/AGENTS.md";
  home.file.".kimi-code/MEMORY.md".source =
    config.lib.file.mkOutOfStoreSymlink "/home/ron/nixos-config/MEMORY.md";
  home.file.".kimi-code/NIXOS-OPS.md".source =
    config.lib.file.mkOutOfStoreSymlink "/home/ron/nixos-config/NIXOS-OPS.md";
  home.file."AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "/home/ron/nixos-config/AGENTS.md";
  home.file.".clinerules/01-nixos-redlines.md".source =
    config.lib.file.mkOutOfStoreSymlink "/home/ron/nixos-config/AGENTS.md";
  home.file.".clinerules/02-nixos-ops.md".source =
    config.lib.file.mkOutOfStoreSymlink "/home/ron/nixos-config/NIXOS-OPS.md";
  home.file.".clinerules/03-machine-memory.md".source =
    config.lib.file.mkOutOfStoreSymlink "/home/ron/nixos-config/MEMORY.md";

  # xdg-terminal-exec 的终端优先级列表（一行一个 Desktop Entry ID，靠前的优先）
  home.file.".config/xdg-terminals.list".text = ''
    # 首选 Ghostty（GNOME 的默认终端键走的就是 xdg-terminal-exec）
    com.mitchellh.ghostty.desktop
  '';

  # Ghostty 自定义着色器：Liquid Ghost
  # 跟随光标的液态玻璃镜头（欠阻尼弹簧物理 / 移动拉伸 / 涟漪 / 边缘色散）
  # 来源：https://gist.github.com/whexy/b6e1b76d69b31349358a8c376788d7ae
  #
  # 素材本体放在 ~/Data/apps/shaders/（照 ~/Data/apps/icons/gopeed.svg 的形状：
  # 被 Nix 声明引用的、放在 store 外的素材）。仓库里不再存副本。
  # 这里写绝对路径而不是 $HOME —— 配置文件没有 shell 去展开变量。
  # sha256: 4d79b6830d9d6ed72b3d6e19c50c6c3eaa687d207d64e3ef496ff54d89777361
  #
  # 文件名必须是 config.ghostty：Ghostty 1.3 的正式名（源码 Config.zig
  # loadDefaultFiles：先加载旧名 `config`，再加载 `config.ghostty`；
  # 两个同时存在会告警）。只写这一个，不要同时建 `config`。
  #
  # 它用到的 uniform 已逐个核对存在于 Ghostty 的 shadertoy_prefix.glsl：
  # iResolution / iTime / iCurrentCursor / iPreviousCursor / iCursorColor /
  # iFocus / iTimeCursorChange / iTimeFocus / iChannel0
  #
  # 相关设置 custom-shader-animation 默认 true：focused 终端会跑动画循环，
  # 上游注释称 CPU 增加一般不到 10%。想省电可设 false（但着色器就不动了）。
  home.file.".config/ghostty/config.ghostty".text = ''
    custom-shader = /home/ron/Data/apps/shaders/liquid-ghost.glsl
  '';

  # 模式 A 的软件（本体在 ~/OmniStudio/Applications/，不在 store）没法在构建时
  # 生成补全脚本 —— Nix 沙箱读不到 $HOME。改在这里跑：每次 switch 重新生成一次。
  # 只生成 bash 的（本机 shell 是 bash）；用 zsh/fish 的话再加对应分支。
  home.activation.shellCompletions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    compdir="$HOME/.local/share/bash-completion/completions"
    mkdir -p "$compdir"
    for spec in \
      "$HOME/OmniStudio/Applications/Extracted/herdr/herdr herdr" \
      "$HOME/OmniStudio/Applications/Extracted/multica/multica multica"
    do
      set -- $spec
      if [ -x "$1" ]; then
        "$1" completion bash > "$compdir/$2" 2>/dev/null || true
      fi
    done
  '';

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
      ExecStart = "${pkgs.bash}/bin/bash -c 'cd /home/ron/nixos-config && ${pkgs.git}/bin/git add -A && (${pkgs.git}/bin/git diff --cached --quiet || (${pkgs.git}/bin/git commit -m \"auto: $(date +%%Y-%%m-%%d_%%H:%%M)\" && ${pkgs.git}/bin/git push))'";
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Ron";
        email = "1757093971@qq.com";
      };
      # git ≥2.37：没有上游跟踪时裸 git push 自动推到同名分支
      # （防 filter-repo 类操作重加 remote 后丢 tracking，timer 再炸 exit 128）
      push.autoSetupRemote = true;
    };
  };
}
