# 第三方 agent 技能（78 个 / 12 个仓库）：钉 rev 拉进 store，软链到 ~/.agents/skills/<技能名>
#
# 为什么声明式：`~/.agents/skills` 原来靠 `npx skills add` 装，重装系统不恢复、
# 不可复现。改成声明后：内容由 flake 决定，更新 = 改下面 rev 再 rebuild。
#
# 为什么用 pkgs.fetchurl 而不是 pkgs.fetchFromGitHub：fetchFromGitHub 生成的
# FOD 名字由它自己定，跟 `nix store prefetch-file --name <同名>` 预热进 store 的
# 路径对不上，build 时会重新去 github.com 下载 —— 而本机直连 GitHub 大文件会
# 卡死（HEAD 正常、GET body 45 秒不返数据），必须走 ghfast.top 代理。
# 显式给 fetchurl 传 name + 扁平 sha256，Nix 就能直接命中 store 里的副本，
# 零网络；内容完整性仍由 sha256 保证（代理篡改会当场 hash 不匹配）。
#
# 未纳管（保持手工，见 NIX-SKILLS.md 与本文件末尾说明）：
#   nix-ins                   本机自建的安装 SOP，没有上游
#   anyrss                    查不到上游仓库，疑似本机自建
#   resolving-merge-conflicts 上游（obra/superpowers）已删除该技能
{ lib, pkgs, ... }:

let
  # key = store 里的名字，必须和预热时 `nix store prefetch-file --name <key>` 一致
  repos = {
    mattpocock-skills = {
      owner = "mattpocock";
      repo = "skills";
      rev = "d81f3a183412";
      sha256 = "sha256-xBljN9wsaQzwTttEphTfTO3TFFZ9nsd255nkXWEdKPw=";
    };
    obra-superpowers = {
      owner = "obra";
      repo = "superpowers";
      rev = "8ca22dba9a94";
      sha256 = "sha256-KXFLLExyfsxmAPnlmCoNy7gphgunlibxlBoPIz6FMxo=";
    };
    olafkfreund-nix-skills = {
      owner = "olafkfreund";
      repo = "nix-skills";
      rev = "f5c8e8b3b325";
      sha256 = "sha256-4EK8VBKwhzevtSVd+ZqCXSgqvGt2l/2/h3dNJTr8Sh0=";
    };
    ponytail = {
      owner = "DietrichGebert";
      repo = "ponytail";
      rev = "e3ba2aa6f1e6";
      sha256 = "sha256-h71tBdfATJZoxBDt0DWVgMMQG+rSSRlC5RF9mDLji34=";
    };
    stablyai-orca = {
      owner = "stablyai";
      repo = "orca";
      rev = "f09458796db5";
      sha256 = "sha256-FNwDgKs65OCG6TuFmewRFEwcwm04F8z6XfLyJ6TrLo8=";
    };
    vercel-labs-skills = {
      owner = "vercel-labs";
      repo = "skills";
      rev = "3694740352ee";
      sha256 = "sha256-DVB2feA4g/dANOWQHqHwH7f67FLvr5lGDxGXbbOW+oI=";
    };
    typesafe-ai-skills = {
      owner = "typesafe-ai";
      repo = "skills";
      rev = "65a39f393687";
      sha256 = "sha256-ZVMQeEawuk9Cooo+50W1cK2uFN5AGO2BkUy1HN9g/To=";
    };
    security-audit-skill = {
      owner = "cloudflare";
      repo = "security-audit-skill";
      rev = "c1c8a8c14710";
      sha256 = "sha256-U+cI6/dw3+NbV98FhqUFhwcIGocM0UnOMKLVfFHtKbY=";
    };
    apk-reverse = {
      owner = "newliver666";
      repo = "apk-reverse";
      rev = "7b6c6932a95f";
      sha256 = "sha256-za00SD9xiXYol/BELWbh2VEXeTDA23/yvRK+fEwKaG4=";
    };

    # --- 视觉复刻三件套（2026-09-30 加）：照着视频/网页还原视觉效果
    mblode-agent-skills = {
      owner = "mblode";
      repo = "agent-skills";
      rev = "b42cf4353847";
      sha256 = "sha256-P2bIBLtPQq4bvQtSR9dlSho/UF5JEN5LtfmcdSkcNcA=";
    };
    emilkowalski-skills = {
      owner = "emilkowalski";
      repo = "skills";
      rev = "d16ebe60d09a";
      sha256 = "sha256-VlN8S8SegCpQsIdhsq9Nrw3UTXWHRWYIJK8bcSALB0k=";
    };
    onewave-claude-skills = {
      owner = "onewave-ai";
      repo = "claude-skills";
      rev = "f317e08649a6";
      sha256 = "sha256-zB+At6gwJBX1TtLq9zW4l4kluq50foIOEhM/2dRe94w=";
    };
  };

  # GitHub archive 下来是「未解包的单文件 tarball」，而 home.file.source 需要
  # 一个目录，所以每个仓库多一个 runCommand 解包（--strip-components=1 去掉
  # tarball 里 <repo>-<rev>/ 那层）。
  # 不用 builtins.fetchTree：它只接受单个 url，没有镜像列表，新机器上直连
  # GitHub 会卡死。
  fetched = lib.mapAttrs
    (key: r:
      let
        tarball = pkgs.fetchurl {
          name = key; # 与 store 里预热副本同名 → build 不重新下载
          urls = [
            "https://github.com/${r.owner}/${r.repo}/archive/${r.rev}.tar.gz"
            # 备用镜像：本机直连 GitHub 大文件会卡死（HEAD 正常、GET body 45 秒
            # 不返数据）。Nix 仍按 sha256 校验，代理只能影响能否下到，不能改内容。
            "https://ghfast.top/https://github.com/${r.owner}/${r.repo}/archive/${r.rev}.tar.gz"
          ];
          hash = r.sha256;
        };
      in
      pkgs.runCommand key { nativeBuildInputs = [ pkgs.gnutar ]; } ''
        mkdir -p $out
        tar xf ${tarball} --strip-components=1 -C $out
      '')
    repos;

  # 技能名 = 上游目录里 SKILL.md 所在目录名（agent 按目录名识别技能）
  skillDirs = {
    # --- mattpocock/skills (37)
    "ask-matt" = "mattpocock-skills/skills/engineering/ask-matt";
    "claude-handoff" = "mattpocock-skills/skills/in-progress/claude-handoff";
    "code-review" = "mattpocock-skills/skills/engineering/code-review";
    "codebase-design" = "mattpocock-skills/skills/engineering/codebase-design";
    "diagnosing-bugs" = "mattpocock-skills/skills/engineering/diagnosing-bugs";
    "domain-modeling" = "mattpocock-skills/skills/engineering/domain-modeling";
    "git-guardrails-claude-code" = "mattpocock-skills/skills/misc/git-guardrails-claude-code";
    "grill-me" = "mattpocock-skills/skills/productivity/grill-me";
    "grill-with-docs" = "mattpocock-skills/skills/engineering/grill-with-docs";
    "grilling" = "mattpocock-skills/skills/productivity/grilling";
    "handoff" = "mattpocock-skills/skills/productivity/handoff";
    "implement" = "mattpocock-skills/skills/engineering/implement";
    "implement-spec" = "mattpocock-skills/skills/engineering/implement-spec";
    "improve-codebase-architecture" = "mattpocock-skills/skills/engineering/improve-codebase-architecture";
    "loop-me" = "mattpocock-skills/skills/in-progress/loop-me";
    "migrate-to-shoehorn" = "mattpocock-skills/skills/misc/migrate-to-shoehorn";
    "pr" = "mattpocock-skills/skills/engineering/pr";
    "prototype" = "mattpocock-skills/skills/engineering/prototype";
    "research" = "mattpocock-skills/skills/engineering/research";
    "retro" = "mattpocock-skills/skills/engineering/retro";
    "scaffold-exercises" = "mattpocock-skills/skills/misc/scaffold-exercises";
    "setup-matt-pocock-skills" = "mattpocock-skills/skills/engineering/setup-matt-pocock-skills";
    "setup-pre-commit" = "mattpocock-skills/skills/misc/setup-pre-commit";
    "setup-ts-deep-modules" = "mattpocock-skills/skills/in-progress/setup-ts-deep-modules";
    "tdd" = "mattpocock-skills/skills/engineering/tdd";
    "teach" = "mattpocock-skills/skills/productivity/teach";
    "to-questionnaire" = "mattpocock-skills/skills/productivity/to-questionnaire";
    "to-spec" = "mattpocock-skills/skills/engineering/to-spec";
    "to-tickets" = "mattpocock-skills/skills/engineering/to-tickets";
    "triage" = "mattpocock-skills/skills/engineering/triage";
    "wait-what" = "mattpocock-skills/skills/productivity/wait-what";
    "wayfinder" = "mattpocock-skills/skills/engineering/wayfinder";
    "wizard" = "mattpocock-skills/skills/engineering/wizard";
    "writing-beats" = "mattpocock-skills/skills/in-progress/writing-beats";
    "writing-for-agents" = "mattpocock-skills/skills/productivity/writing-for-agents";
    "writing-fragments" = "mattpocock-skills/skills/in-progress/writing-fragments";
    "writing-shape" = "mattpocock-skills/skills/in-progress/writing-shape";

    # --- obra/superpowers (15)
    "brainstorming" = "obra-superpowers/skills/brainstorming";
    "diagnosing-superpowers" = "obra-superpowers/skills/diagnosing-superpowers";
    "dispatching-parallel-agents" = "obra-superpowers/skills/dispatching-parallel-agents";
    "executing-plans" = "obra-superpowers/skills/executing-plans";
    "finishing-a-development-branch" = "obra-superpowers/skills/finishing-a-development-branch";
    "receiving-code-review" = "obra-superpowers/skills/receiving-code-review";
    "requesting-code-review" = "obra-superpowers/skills/requesting-code-review";
    "subagent-driven-development" = "obra-superpowers/skills/subagent-driven-development";
    "systematic-debugging" = "obra-superpowers/skills/systematic-debugging";
    "test-driven-development" = "obra-superpowers/skills/test-driven-development";
    "using-git-worktrees" = "obra-superpowers/skills/using-git-worktrees";
    "using-superpowers" = "obra-superpowers/skills/using-superpowers";
    "verification-before-completion" = "obra-superpowers/skills/verification-before-completion";
    "writing-plans" = "obra-superpowers/skills/writing-plans";
    "writing-skills" = "obra-superpowers/skills/writing-skills";

    # --- olafkfreund/nix-skills (10)，见 NIX-SKILLS.md
    "devenv-project" = "olafkfreund-nix-skills/skills/devenv-project";
    "home-manager" = "olafkfreund-nix-skills/skills/home-manager";
    "microvm-nix" = "olafkfreund-nix-skills/skills/microvm-nix";
    "nix-darwin" = "olafkfreund-nix-skills/skills/nix-darwin";
    "nix-language" = "olafkfreund-nix-skills/skills/nix-language";
    "nix-workflow" = "olafkfreund-nix-skills/skills/nix-workflow";
    "nixos-coding-agents" = "olafkfreund-nix-skills/skills/nixos-coding-agents";
    "nixos-operations" = "olafkfreund-nix-skills/skills/nixos-operations";
    "nixos-wiki" = "olafkfreund-nix-skills/skills/nixos-wiki";
    "nixpkgs-development" = "olafkfreund-nix-skills/skills/nixpkgs-development";

    # --- DietrichGebert/ponytail (6)
    "ponytail" = "ponytail/skills/ponytail";
    "ponytail-audit" = "ponytail/skills/ponytail-audit";
    "ponytail-debt" = "ponytail/skills/ponytail-debt";
    "ponytail-gain" = "ponytail/skills/ponytail-gain";
    "ponytail-help" = "ponytail/skills/ponytail-help";
    "ponytail-review" = "ponytail/skills/ponytail-review";

    # --- stablyai/orca (3)
    "computer-use" = "stablyai-orca/skills/computer-use";
    "orca-cli" = "stablyai-orca/skills/orca-cli";
    "orchestration" = "stablyai-orca/skills/orchestration";

    # --- 单技能仓库 (4)
    "find-skills" = "vercel-labs-skills/skills/find-skills";
    "typesafe-ai" = "typesafe-ai-skills/skills/typesafe-ai";
    "security-audit" = "security-audit-skill/skills/security-audit";
    "apk-reverse" = "apk-reverse/skills/apk-reverse";

    # --- 视觉复刻 (3)：照着视频/网页还原效果，作者不给源码时用
    # ui-animation：从录像拟合曲线，触发词含 "reverse engineer this motion"
    "ui-animation" = "mblode-agent-skills/skills/ui-animation";
    # animation-vocabulary：把「那个弹一下的」翻译成精确定义词
    "animation-vocabulary" = "emilkowalski-skills/skills/animation-vocabulary";
    # screenshot-to-code：截图 → 代码，并渲染回图片对比收敛视觉差距
    # 注意该技能在仓库里位于根目录（不是 skills/ 下）
    "screenshot-to-code" = "onewave-claude-skills/screenshot-to-code";
  };
  # "mattpocock-skills/skills/engineering/ask-matt" → "<store>/skills/engineering/ask-matt"
  resolve = spec:
    let parts = lib.splitString "/" spec;
    in "${fetched.${builtins.head parts}}/${lib.concatStringsSep "/" (builtins.tail parts)}";
in
{
  # home.file 默认就是链接到 store（不复制），所以 ~/.agents/skills/<name>
  # 是指向 store 的符号链接。未纳管的 3 个技能在这个目录里保持普通实体
  # 目录，home-manager 不声明它们，因此不会被 switch 覆盖。
  home.file = lib.mapAttrs'
    (name: spec: lib.nameValuePair ".agents/skills/${name}" { source = resolve spec; })
    skillDirs;
}
