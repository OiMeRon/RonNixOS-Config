{ appimage-install, pkgs, ... }:

{
  home.username = "ron";
  home.homeDirectory = "/home/ron";
  home.stateVersion = "26.05";

  # kimi 的路径
  home.sessionPath = [
    "/home/ron/.kimi-code/bin"
  ];

  home.packages = [
    appimage-install.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Motrix 桌面文件由 appimageTools.wrapType2 自动生成

  programs.bash.enable = true;

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

  programs.git = {
    enable = true;
    settings.user = {
      name = "Ron";
      email = "1757093971@qq.com";
    };
  };
}
