# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, zen-browser, pkgs-unstable, ... }:

let
  # Motrix wrapper（AppImage 在用户目录）
  motrix-wrapper = pkgs.writeShellScriptBin "motrix" ''
    export LD_LIBRARY_PATH=${
      pkgs.lib.makeLibraryPath [
        pkgs.glib pkgs.gtk3 pkgs.qt5.qtbase pkgs.qt5.qtdeclarative pkgs.qt5.qtquickcontrols2 pkgs.SDL2
        pkgs.libx11 pkgs.libxcursor pkgs.libxrandr
        pkgs.libGL pkgs.libpulseaudio pkgs.pipewire pkgs.alsa-lib
        pkgs.cups pkgs.dbus pkgs.fontconfig pkgs.freetype
        pkgs.pango pkgs.cairo pkgs.gdk-pixbuf pkgs.openssl
        pkgs.nspr pkgs.nss pkgs.at-spi2-core pkgs.at-spi2-atk
        pkgs.harfbuzz pkgs.libdrm pkgs.libgbm pkgs.libuuid
        pkgs.libsecret pkgs.wayland pkgs.zlib pkgs.stdenv.cc.cc.lib
      ]
    }:$LD_LIBRARY_PATH
    exec ${pkgs.appimage-run}/bin/appimage-run $HOME/nixos-config/appimages/Motrix-2.0.0-beta.39-x86_64.AppImage "$@"
  '';

  # DimAgent wrapper（解压版 Electron 应用）
  dimagent-wrapper = pkgs.writeShellScriptBin "dimagent" ''
    export LD_LIBRARY_PATH=$HOME/Applications/DimAgent:${
      pkgs.lib.makeLibraryPath [
        pkgs.alsa-lib pkgs.at-spi2-core pkgs.at-spi2-atk pkgs.cairo pkgs.cups
        pkgs.dbus pkgs.expat pkgs.gdk-pixbuf pkgs.glib pkgs.glib-networking
        pkgs.gtk3 pkgs.harfbuzz pkgs.atk pkgs.libxcb pkgs.libx11 pkgs.libXcomposite
        pkgs.libXdamage pkgs.libXext pkgs.libXfixes pkgs.libxkbcommon pkgs.libXrandr
        pkgs.libdrm pkgs.libgbm pkgs.libGL pkgs.libglvnd
        pkgs.libuuid pkgs.libsecret pkgs.libnotify pkgs.libxinerama pkgs.libxrender
        pkgs.mesa pkgs.nspr pkgs.nss pkgs.openssl
        pkgs.pango pkgs.pipewire pkgs.libpulseaudio
        pkgs.stdenv.cc.cc.lib pkgs.udev pkgs.wayland
        pkgs.fontconfig pkgs.freetype pkgs.libxcursor pkgs.libxshmfence
        pkgs.libusb1 pkgs.zlib pkgs.icu
      ]
    }:$LD_LIBRARY_PATH
    cd $HOME/Applications/DimAgent
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

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # Use the WirePlumber session manager
    #wireplumber.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Flatpak
  services.flatpak.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."ron" = {
    isNormalUser = true;
    description = "Ron";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;
  # gh CLI 通过环境变量配置代理

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
    fontconfig
    freetype
    gtk4
    hicolor-icon-theme
    adwaita-icon-theme
    pkgs-unstable.blender
    obsidian
    gh
    curl
    bun
    git
    deno
    ghostty
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
    gnomeExtensions.rounded-window-corners-reborn
    brave-beta
    motrix-wrapper
    dimagent-wrapper
  ];

  # You can use https://search.nixos.org/ to find more packages (and options).
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
