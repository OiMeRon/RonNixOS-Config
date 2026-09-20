# Tolaria - 应用容器/沙箱管理工具

{ pkgs, ... }:

let
  tolariaWrapper = pkgs.writeShellScriptBin "tolaria" ''
    exec ${pkgs.appimage-run}/bin/appimage-run \
      /home/ron/OmniStudio/Applications/AppImage/Tolaria_2026.9.17-alpha.1_amd64.AppImage \
      "$@"
  '';

  tolariaDesktop = pkgs.makeDesktopItem {
    name = "tolaria";
    desktopName = "Tolaria";
    genericName = "App Container";
    comment = "Application container and sandbox manager";
    exec = "tolaria %U";
    startupNotify = true;
    startupWMClass = "Tolaria";
    terminal = false;
    icon = "tolaria";
    type = "Application";
    categories = [ "Utility" "System" ];
  };
in
{
  environment.systemPackages = [
    tolariaWrapper
    tolariaDesktop
    pkgs.appimage-run
  ];

  # 安装图标
  systemd.tmpfiles.rules = [
    "L+ /usr/share/icons/hicolor/256x256/apps/tolaria.png - - - - /home/ron/.cache/appimage-run/c8944e020331720090de5286962e0a238a161c96abd340c36663d8e8d2ffdaf3/tolaria.png"
  ];
}
