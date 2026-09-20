# Tolaria - 应用容器/沙箱管理工具

{ pkgs, ... }:

let
  tolariaWrapper = pkgs.writeShellScriptBin "tolaria" ''
    exec ${pkgs.appimage-run}/bin/appimage-run \
      /home/ron/OmniStudio/Applications/AppImage/Tolaria_2026.9.8_amd64.AppImage \
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

  systemd.tmpfiles.rules = [
    "L+ /usr/share/icons/hicolor/256x256/apps/tolaria.png - - - - /home/ron/.cache/appimage-run/4f4d54bd35877bc7f49c6becad4e6dc6c982bf7f464b374d086e6e44e2979323/tolaria.png"
  ];
}
