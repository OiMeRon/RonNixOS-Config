# Ghidra —— NSA 软件逆向工程套件（用户指定：装上游最新版）
#
# ── 为什么不用 pkgs.ghidra ──────────────────────────────────────────
# 2026-09-27 实测：本机 nixpkgs 渠道（nixos-26.05）里的 pkgs.ghidra 是 **12.0.4**，
# 上游 NSA 最新是 **12.1.4**（2026-09-21 发布）。用户明确要最新版，所以本模块
# 照抄 nixpkgs 官方的「release zip」打包方案（pkgs/tools/security/ghidra/default.nix），
# 只改版本号 / 发布日期 / 哈希。等渠道追上后可以删掉本模块换回 pkgs.ghidra。
#
# 哈希来源：GitHub release 资产自带 digest
#   ghidra_12.1.4_PUBLIC_20260921.zip
#   sha256:ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db
#   2026-09-27 用 GitHub API 核对过，tag = Ghidra_12.1.4_build
#
# ── 为什么用 fetchurl 而不是 nixpkgs 那套 fetchzip ────────────────
# 2026-09-27 实测：本机直连 GitHub release 只有 ~45KB/s，570MB 要 3.5 小时。
# fetchzip 的输出路径是**解压后 NAR 的哈希**，没法预先塞进 store；fetchurl 用
# zip 自身的 flat 哈希，所以可以：并行分块下到本地 → sha256 校验 →
# nix store prefetch-file 放进 store → rebuild 直接命中，不重复下载。
# 声明里的 url 仍是官方地址，store 里被 gc 掉后会照常回官方源重下。
#
# ── 放哪（按本机目录宪法）──────────────────────────────────────────
#   程序本体  → /nix/store/...-ghidra-12.1.4（不可变，声明式管）
#               **不放** ~/OmniStudio/Applications/：那条规则针对 store 外的
#               AppImage / 解压版（模式 A，见重装后需手动放回的文件.md）；
#               声明式包一律留在 store，升级走 rebuild（和 blender/godot 同理）
#   命令      → ghidra（GUI）、ghidra-analyzeHeadless（无头分析）
#   菜单图标  → 随 derivation 装 desktop item + ico→png，GNOME 里直接可见
#   分析项目  → ~/Data/项目/Ghidra（数据归 ~/Data/，创建项目时选这个目录）
#   应用配置  → ~/.config/ghidra/（Ghidra 自己管，不声明、不搬家）
#
# ── 依赖 ───────────────────────────────────────────────────────────
#   JDK 21 是上游最低要求；用 wrapProgram 注入，不依赖系统 openjdk。
#   Python 3.13（Ghidra 支持 3.9–3.13）同样注入，PyGhidra / .py 脚本能直接跑。

{ pkgs, lib, ... }:

let
  version = "12.1.4";
  versiondate = "20260921";

  src = pkgs.fetchurl {
    url = "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${version}_build/ghidra_${version}_PUBLIC_${versiondate}.zip";
    # 显式写死 name：fetchurl 的 store 路径 = flat 哈希 + name，
    # 预下载塞 store 时要能算出同一个路径
    name = "ghidra_${version}_PUBLIC_${versiondate}.zip";
    hash = "sha256-3wwet6id3kovxledhzompe4vbgfzym6p2mtzxzptdpiahb6s2tnq";
  };

  pkgPath = "$out/lib/ghidra";

  desktopItem = pkgs.makeDesktopItem {
    name = "ghidra";
    exec = "ghidra";
    icon = "ghidra";
    desktopName = "Ghidra";
    genericName = "Ghidra Software Reverse Engineering Suite";
    comment = "Software reverse engineering suite by NSA";
    categories = [ "Development" "Security" ];
    terminal = false;
    startupWMClass = "ghidra-Ghidra";
    startupNotify = true;
  };

  ghidra = pkgs.stdenv.mkDerivation rec {
    pname = "ghidra";
    inherit version src;

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.icoutils
      pkgs.unzip  # fetchurl 只负责下 zip，unpackPhase 解压要 unzip
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];

    buildInputs = [
      (lib.getLib pkgs.stdenv.cc.cc)
      pkgs.pam
    ];

    # release zip 里是预编译 jar + 少量 .so，strip 只会弄坏它们
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "${pkgPath}" "$out/share/applications"
      cp -a . "${pkgPath}"
      ln -s ${desktopItem}/share/applications/* $out/share/applications

      # support/ghidra.ico → hicolor 多尺寸 png，GNOME 菜单/任务栏才有图标
      icotool -x "${pkgPath}/support/ghidra.ico"
      rm ghidra_4_40x40x32.png
      for f in ghidra_*.png; do
        res=$(basename "$f" ".png" | cut -d"_" -f3 | cut -d"x" -f1-2)
        mkdir -pv "$out/share/icons/hicolor/$res/apps"
        mv "$f" "$out/share/icons/hicolor/$res/apps/ghidra.png"
      done

      runHook postInstall
    '';

    postFixup = ''
      runHook preFixup

      mkdir -p "$out/bin"
      ln -s "${pkgPath}/ghidraRun" "$out/bin/ghidra"
      ln -s "${pkgPath}/support/analyzeHeadless" "$out/bin/ghidra-analyzeHeadless"

      # launch.sh 自己会在 PATH 上找兼容 JDK；这里直接把 21 顶到最前面，
      # 免得弹出「Failed to find a supported JDK」让你手填 java_home
      wrapProgram "${pkgPath}/support/launch.sh" \
        --prefix PATH : ${lib.makeBinPath [ pkgs.openjdk21 pkgs.python3 ]}

      runHook postFixup
    '';

    meta = {
      description = "Software reverse engineering (SRE) suite of tools developed by NSA's Research Directorate";
      longDescription = ''
        Ghidra is a software reverse engineering (SRE) suite of tools developed by
        NSA's Research Directorate in support of the Cybersecurity mission.
      '';
      mainProgram = "ghidra";
      homepage = "https://github.com/NationalSecurityAgency/ghidra";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      sourceProvenance = with lib.sourceTypes; [ binaryByteCode ];
      license = lib.licenses.asl20;
    };
  };
in
{
  environment.systemPackages = [ ghidra ];
}
