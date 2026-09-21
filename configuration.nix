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

  # Nix-daemon proxy settings
  systemd.services.nix-daemon.environment = {
    HTTP_PROXY = "http://127.0.0.1:7897";
    HTTPS_PROXY = "http://127.0.0.1:7897";
    ALL_PROXY = "socks://127.0.0.1:7897";
  };
 
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

  programs.clash-verge = {
    package = pkgs-unstable.clash-verge-rev;
    enable = true;
    serviceMode = true;
    tunMode = true;
    autoStart = true;
  };


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
    obs-studio
    openjdk
    php
    pkgs.gnomeExtensions.user-themes
    pkgs.gnomeExtensions.dash-to-dock
    pnpm
    python3
    ruby
    rustup
    superfile
    uv
    yarn
    zen-browser.packages.${pkgs.system}.twilight
    gnome-tweaks
    gnome-icon-theme
    gnomeExtensions.rounded-window-corners-reborn
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
