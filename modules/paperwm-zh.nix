# PaperWM 设置界面中文化
#
# 背景：PaperWM 上游没有可用的 i18n
#   - prefs.js / prefsKeybinding.js 里是 `const _ = s => s;`（空壳 gettext）
#   - Settings.ui 里 136 个字符串标了 translatable="yes"，但 JS 侧没有
#     set_translation_domain，GTK 不会去查翻译
#   → 只能直接改字符串。本模块用 overlay 在构建时把英文改成「English / 中文」。
#
# 改动点（UI 上文字的三个来源，共 238 处）：
#   1. *.ui                   —— GtkBuilder 界面（label / title / tooltip_text / text）
#   2. schemas/*.gschema.xml  —— 快捷键页的说明（UI 调 get_summary() 读）
#   3. prefs.js               —— 少量硬编码字符串
#
# 维护提示：上游更新（版本号变化）后，若新增了字符串，翻译表里没有的会保持英文，
#   不会报错。要补翻译就改 modules/paperwm-zh.py 里的 MAP。
#   先跑 `python3 modules/paperwm-zh.py --check <扩展目录>` 可以看命中多少处。

{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      gnomeExtensions = prev.gnomeExtensions // {
        paperwm = prev.gnomeExtensions.paperwm.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            ${final.python3}/bin/python3 ${./paperwm-zh.py} .
          '';
        });
      };
    })
  ];
}
