# OmO (oh-my-openagent) —— 独立 CLI 版（OmO Native）
#
# ── 选型依据（2026-09-27 查证）────────────────────────────────────
# 这仓库有三个版本，本模块只装「OmO Native」：
#   Ultimate（OpenCode 插件，`bunx oh-my-openagent install`）—— 官方推荐给 opencode 用户，
#     但它要写 opencode 配置；本机 opencode.jsonc 是 home-manager 软链进 /nix/store 的
#     （~/nixos-config/home.nix:191），安装器写不进去，要先解决配置归属问题。
#   Light（Codex CLI 插件）—— 本机不用 codex。
#   OmO Native（`omo` 单文件二进制）—— 自带 senpi 引擎，**不依赖 node/bun**，
#     首启自动在 ~/.omo/binary-runtime/<版本>/ 展开运行时。声明式安装最干净。
# 用户 2026-09-27 明确选了 Native。
#
# ── 资产选择 ────────────────────────────────────────────────────
# 官方 release v5.0.1 附件（SHA256SUMS 官方校验，2026-09-27 核对通过）：
#   omo-linux-x64           120.6MB  be33e7607f547fdc40a8698d1b483420742552d95c534f99aa5b7bc6c3ae1034
#   omo-linux-x64-baseline  同上（无 AVX2 的老 CPU 用）
#   omo-linux-x64-musl      Alpine/musl 用，本机是 glibc，不要
# 本机 CPU：Intel Core Ultra X7 358H（/proc/cpuinfo 有 avx2）→ 用 omo-linux-x64。
# 想换 baseline 只需改 url/name/hash 三处。
#
# ── 放哪（按本机目录宪法）──────────────────────────────────────────
#   本体    → /nix/store/...-omo-5.0.1/bin/omo（不可变，声明式管）
#   运行时  → ~/.omo/binary-runtime/5.0.1/（omo 首次启动自己展开，应用自管）
#   配置    → ~/.omo/omo.jsonc（omo 自己管）
#   项目数据 → 仍归 ~/Data/（omo 是 agent 工具，产物落在你给的工作目录里）
#
# ── 许可 ────────────────────────────────────────────────────────
# SUL-1.0（Sustainable Use License，上游自定义，非 OSI 开源）。故 meta 记 unfree；
# 本机 configuration.nix 已开 allowUnfree，且这是本仓库自建包，不入 nixpkgs。
#
# ── 为什么用 fetchurl 而不是 buildNpmPackage ─────────────────────
# npm 上等价物是 `omo-ai`（需 node >= 24，且 postinstall 要打 senpi 补丁）；
# 官方 release 直接给编译好的单文件二进制，省掉一整棵 node 依赖树。

{ pkgs, ... }:

let
  version = "5.0.1";

  src = pkgs.fetchurl {
    url = "https://github.com/code-yeongyu/oh-my-openagent/releases/download/v${version}/omo-linux-x64";
    # 显式 name：fetchurl 的 store 路径 = flat 哈希 + name，
    # 预下载塞 store 时要能算出同一个路径
    name = "omo-linux-x64";
    hash = "sha256-xyz6oyd7kr75yqfinggrwsbueb2ckuwzlrju7gnkln54nq5oca2a";
  };

  # 外来预编译二进制：走 autoPatchelf 把 ELF 解释器指到 nixpkgs 的 glibc，
  # 不依赖 /lib64/ld-linux-x86-64.so.2（那是指向 nix-ld 的兼容软链）
  omo = pkgs.runCommand "omo-${version}"
    {
      nativeBuildInputs = [
        pkgs.autoPatchelfHook
        pkgs.makeWrapper
      ];
    }
    ''
      install -Dm755 ${src} $out/bin/omo
      autoPatchelf $out/bin/omo
      # 顺手确认它能在这个环境里被内核加载（--version 不触发运行时展开）
      $out/bin/omo --version > /dev/null
    '';
in
{
  environment.systemPackages = [ omo ];
}
