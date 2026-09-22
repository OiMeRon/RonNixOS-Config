# Window Nativizer —— 给非原生窗口补 Adwaita 圆角 / GPU 阴影 / GTK 原生拉伸边框
#
# 上游：https://github.com/everyx/gnome-shell-extension-window-nativizer
# 上架状态：不在 nixpkgs，也不在 extensions.gnome.org（2026-09-22 查证），
#           只能从 GitHub Release 的 zip 封装。
# 支持版本：metadata.json 里 shell-version 只有 ["50"]，本机 GNOME Shell 50.4 ✓
#
# 注意：本扩展和 rounded-window-corners 是同类竞品，**不要同时启用**
#       （会重复画圆角/阴影）。本机 rounded-window-corners@fxgn 当前是「已安装未启用」。
#
# 升级：改 version，hash 用报错里的新值（或 nix-prefetch-url）。
#
# 打包踩的三个坑：
#   1. 网络：Nix 守护进程没有代理，直连 github.com 会被掐断（安装错误总结 §22），
#      必须走 gh-proxy 镜像；镜像字节与直连一致，hash 可复用
#   2. 解包：Release zip 的根目录直接是 lib/ effects/ icons/ 等，
#      **没有单一顶层目录**，stdenv 默认 unpackPhase 会报
#      "unpacker produced multiple directories"，必须自己覆盖 unpackPhase
#   3. schema：zip 里**没有 gschemas.compiled**，必须自己跑 glib-compile-schemas，
#      否则扩展加载时找不到 schema，设置项全失效
#
# 另外：上游自带 locale/zh_CN 翻译，装进去设置界面就是中文。

{ lib, ... }:

let
  uuid = "window-nativizer@everyx.github.io";
  version = "0.6.0";
  # 直连地址；镜像 = gh-proxy 前缀 + 直连地址
  directUrl = "https://github.com/everyx/gnome-shell-extension-window-nativizer"
    + "/releases/download/v${version}"
    + "/window-nativizer%40everyx.github.io.shell-extension.zip";
in
{
  nixpkgs.overlays = [
    (final: prev:
      let
        src = final.fetchurl {
          # ghfast.top 在前：gh-proxy.com 在无代理环境下会卡死（安装错误总结 §22.8）。
          # 该包只有 79KB，当初 gh-proxy 侥幸下完了；换成大文件必挂。
          urls = [
            "https://ghfast.top/${directUrl}"
            "https://gh-proxy.com/${directUrl}"
            directUrl
          ];
          hash = "sha256-jKi1v2RkKdncZJifa9NikEE9I4jtrj9HlqUbW94SGDg=";
        };
      in
      {
        gnomeExtensions = prev.gnomeExtensions // {
          window-nativizer = final.stdenv.mkDerivation {
            pname = "gnome-shell-extension-window-nativizer";
            inherit version src;

            # zip 根目录没有单一顶层目录，默认解包器会拒绝 → 自己解
            unpackPhase = ''
              runHook preUnpack
              unzip -q "${src}"
              runHook postUnpack
            '';

            nativeBuildInputs = [
              final.unzip
              final.glib
            ];

            buildPhase = ''
              runHook preBuild
              if [ -d schemas ]; then
                glib-compile-schemas --strict schemas
              fi
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out/share/gnome-shell/extensions
              cp -r -T . $out/share/gnome-shell/extensions/${uuid}
              runHook postInstall
            '';

            passthru.extensionUuid = uuid;

            meta = {
              description = "Brings native GNOME ergonomics and appearance to non-native windows";
              homepage = "https://github.com/everyx/gnome-shell-extension-window-nativizer";
              license = lib.licenses.gpl2Plus;
              platforms = lib.platforms.linux;
            };
          };
        };
      })
  ];
}
