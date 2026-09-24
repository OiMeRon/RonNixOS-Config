# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, zen-browser, pkgs-unstable, ... }:

let
  commonLibs = with pkgs; [
    alsa-lib at-spi2-core at-spi2-atk cairo cups dbus expat
    fontconfig freetype gdk-pixbuf glib glib-networking gtk3
    harfbuzz atk libxcb libx11 libXcomposite libXdamage libXext
    libXfixes libxkbcommon libXrandr libdrm libgbm libGL libglvnd
    libuuid libsecret libnotify libxinerama libxrender mesa nspr nss
    openssl pango pipewire libpulseaudio stdenv.cc.cc.lib udev wayland
    libxcursor libxshmfence libusb1 zlib icu
  ];

  motrixPath = "$HOME/OmniStudio/Applications/AppImage/Motrix-2.0.0-beta.39-x86_64.AppImage";
  dimagentPath = "$HOME/OmniStudio/Applications/Extracted/DimAgent";

  motrix-wrapper = pkgs.writeShellScriptBin "motrix" ''
    export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath (commonLibs ++ [ pkgs.qt5.qtbase pkgs.qt5.qtdeclarative pkgs.qt5.qtquickcontrols2 pkgs.SDL2 ])}:$LD_LIBRARY_PATH
    exec ${pkgs.appimage-run}/bin/appimage-run ${motrixPath} "$@"
  '';

  dimagent-wrapper = pkgs.writeShellScriptBin "dimagent" ''
    export LD_LIBRARY_PATH=${dimagentPath}:${pkgs.lib.makeLibraryPath commonLibs}:$LD_LIBRARY_PATH
    cd ${dimagentPath}
    exec ./DimAgent "$@"
  '';
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos";
  # Enable networking
  networking.networkmanager.enable = true;

  # Nix-daemon 代理已移除（2026-09-22，随 clash-verge 退役）。
  # 实测所有 nix 上游直连可达：cache.nixos.org 0.55s / channels.nixos.org 0.91s /
  # mirrors.ustc.edu.cn 0.32s —— 不再需要 127.0.0.1:7897。
  # 若将来某上游不通，在这里恢复这三行即可。

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";

  # IBus + Rime 输入法配置
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs; [
      ibus-engines.rime
    ];
  };

  # 中文字体支持
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
  ];

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = [ pkgs.gnome-software ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "cn";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Flatpak
  services.flatpak.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."ron" = {
    isNormalUser = true;
    description = "Ron";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  programs.firefox.enable = true;

  # clash-verge-rev 于 2026-09-22 退役（用户裁定，省 ~804 MB）。
  # 退役前提已验证：
  #   ① git push 改走 SSH-443（~/.ssh/config 把 github.com 映射到 ssh.github.com:443），
  #      实测真实 push 成功 → 不再依赖 127.0.0.1:7897
  #   ② nix 的上游全部直连可达（cache.nixos.org / channels.nixos.org / USTC / gh-proxy 实测均 200）
  #      → nix-daemon 的代理三行也已移除
  #   ③ 被墙的只有 github.com 这一个域名；HTTPS clone 可走 gh-proxy 前缀
  # Proxy client: Clash Mi only (modules/clashmi.nix, no TUN).
  # Hiddify removed 2026-09-24 (fragile AppImage RPATH).

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      sqlite
      xz
    ];
  };


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # 让 ~/.local/bin 进入 PATH
  environment.localBinInPath = true;

  # 国内镜像源加速配置
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    pkgs-unstable.blender
    obsidian
    gh
    curl
    bun
    git
    deno
    ghostty
    # GNOME 默认终端键(xdg-terminal-exec)的实现；具体挑哪个终端看 ~/.config/xdg-terminals.list
    xdg-terminal-exec
    go
    godot
    helix
    nodejs
    # 终端 AI 编码代理。26.05 稳定版冻结在 1.15.10 太旧，改走 nixpkgs-unstable（2026-09-23）
    pkgs-unstable.opencode
    obs-studio
    openjdk
    php
    pkgs.gnomeExtensions.user-themes
    pkgs.gnomeExtensions.dash-to-dock
    pnpm
    python3
    ruby
    rustup
    # yazi（TUI 文件管理器）取代 superfile（2026-09-22 用户裁定）
    yazi
    # yazi 的预览/搜索配套（缺了预览会退化成占位符）
    ffmpegthumbnailer  # 视频缩略图
    # PDF 预览（pdftoppm）。注意：pkgs.poppler 只是 GLib 绑定库、poppler_min 也没有工具；
    # 本 nixpkgs 里属性名是带连字符的 poppler-utils（旧名 poppler_utils 已重命名），Nix 里必须加引号
    pkgs."poppler-utils"
    chafa              # 终端内显示图片
    fzf                # 模糊查找
    zoxide             # 智能目录跳转
    fd                 # 搜索（yazi 默认用 fd）
    ripgrep            # 全文搜索
    uv
    yarn
    zen-browser.packages.${pkgs.system}.twilight
    gnome-tweaks
    gnome-icon-theme
    gnomeExtensions.rounded-window-corners-reborn
    # PaperWM 148（= 50.0.1，shell-version 含 "50"）—— 可滚动平铺窗口管理
    # 官方 README：Dash to Dock 属「Recommended extensions」；Rounded Window Corners
    # 属「Incompatible extensions」（会改窗口形状 → 视觉 glitch，issue #763/#431）
    gnomeExtensions.paperwm
    motrix-wrapper
    dimagent-wrapper
  ];

  system.stateVersion = "26.05";

  system.activationScripts.icon-cache = ''
    ${pkgs.gtk3}/bin/gtk-update-icon-cache -f /run/current-system/sw/share/icons/hicolor/ 2>/dev/null || true
    ${pkgs.gtk3}/bin/gtk-update-icon-cache -f /run/current-system/sw/share/icons/Adwaita/ 2>/dev/null || true
  '';

  # 补 /bin/bash（NixOS 默认只有 /bin/sh），写法与上游 activationScripts.binsh 一致
  system.activationScripts.binbash = ''
    mkdir -p /bin
    chmod 0755 /bin
    ln -sfn ${pkgs.bashInteractive}/bin/bash /bin/.bash.tmp
    mv /bin/.bash.tmp /bin/bash
  '';

}
