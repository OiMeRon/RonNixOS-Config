#!/usr/bin/env python3
"""
PaperWM 设置界面中文化 —— 把英文字符串改成「English / 中文」双语。

为什么需要这个：PaperWM 上游没有 i18n 基础设施
  - prefs.js / prefsKeybinding.js 里是 `const _ = s => s;`（空壳 gettext）
  - Settings.ui 里 136 个字符串标了 translatable="yes"，但 JS 侧没有
    set_translation_domain，GTK 不会去查翻译
所以只能直接改字符串。

三个改动点（对应 UI 上文字的三个来源）：
  1. *.ui              —— GtkBuilder 界面（label / title / tooltip_text / text）
  2. schemas/*.gschema.xml —— 快捷键页的说明文字（UI 调 get_summary()）
  3. prefs.js          —— 少量硬编码字符串

用法：python3 paperwm-zh.py <扩展目录>
      python3 paperwm-zh.py --check <扩展目录>   # 只统计不改
"""

import sys
import os
import re
import glob
import html

# ─────────────────────────────────────────────────────────────
# 翻译表：键 = 界面上的英文原文（未转义），值 = 中文
# 最终显示为「英文原文 / 中文」
# ─────────────────────────────────────────────────────────────
MAP = {
    # ===== Settings.ui：页面 / 分组标题 =====
    "General": "常规",
    "Settings": "设置",
    "Workspaces": "工作区",
    "Keybindings": "快捷键",
    "Winprops": "窗口属性",
    "Advanced": "高级",
    "About": "关于",
    "Border | Gaps | Margins": "边框 | 间隙 | 边距",
    "Animation | Visual Settings": "动画 | 视觉设置",
    "Touchpad Gestures": "触控板手势",
    "Tiling Edge Preview Settings": "平铺边缘预览设置",
    "PaperWM Component Size Settings": "PaperWM 组件尺寸设置",
    "Other Settings": "其他设置",
    "PaperWM Version Information": "PaperWM 版本信息",
    "Three-finger Swipe Sensitivity": "三指滑动灵敏度",

    # ===== 常规页 =====
    "Position when creating new windows":
        "新建窗口的位置",
    "Sets the position when creating/inserting new tiled windows, e.g. to the right/left of the current window, or at the start/end of all tiled windows.":
        "设置新建/插入平铺窗口时的位置，例如当前窗口的右侧/左侧，或所有平铺窗口的开头/末尾。",
    "Default <i>window focus mode</i> for workspaces":
        "工作区的默认<i>窗口聚焦模式</i>",
    "Sets default focus mode used in workspaces":
        "设置工作区使用的默认聚焦模式",
    "Enable Window Position Bar":
        "启用窗口位置条",
    "Enables PaperWM's Window Position Bar (colored bar overlay on the Gnome topbar)":
        "启用 PaperWM 的窗口位置条（叠加在 GNOME 顶栏上的彩色条）",
    "Enable Gnome Workspace Indicator Pill":
        "启用 GNOME 工作区指示药丸",
    "Replaces PaperWM's workspace indicator with the Gnome Workspace Indicator Pill (introduced in Gnome 45)":
        "用 GNOME 的工作区指示药丸（GNOME 45 引入）替换 PaperWM 的工作区指示器",
    "Show scratch windows in overview":
        "在概览中显示暂存窗口",
    "Show workspace indicator":
        "显示工作区指示器",
    "Shows/hides the workspace indicator element in Topbar":
        "显示/隐藏顶栏的工作区指示器",
    "Show focus mode icon":
        "显示聚焦模式图标",
    "Shows/hides the focus mode icon in TopBar":
        "显示/隐藏顶栏的聚焦模式图标",
    "Show open window position icon":
        "显示打开位置图标",
    "Shows/hides the open window position icon in TopBar":
        "显示/隐藏顶栏的「打开位置」图标",
    "Enable Top Bar styling <i>(required for Window Position Bar)</i>":
        "启用顶栏样式 <i>（窗口位置条需要它）</i>",
    "Disables PaperWM's ability to style the Gnome TopBar":
        "禁用 PaperWM 对 GNOME 顶栏的样式修改",
    "Maximised horizontal width":
        "横向最大化的宽度",
    "Sets the percentage of workspace width the \"window maximize horizontally\" function (default keybind Super+F) uses.":
        "设置「窗口横向最大化」（默认快捷键 Super+F）占工作区宽度的百分比。",
    "Maximize within tiling":
        "在平铺范围内最大化",
    "Enables handling maximize events (like double clicking the header bar) by stretching window width but not going out of the tiling margins":
        "把最大化事件（如双击标题栏）处理为拉伸窗口宽度，但不超出平铺边距",
    "Mouse scrolling on Top Bar switches window (left/right)":
        "顶栏鼠标滚轮切换窗口（左右）",
    "Enables mouse scrolling on Top Bar to switch window (left/right)":
        "允许在顶栏用鼠标滚轮切换窗口（左右）",

    # ===== 边框 / 间隙 / 边距 =====
    "Selected window border size (px)":
        "选中窗口边框粗细（px）",
    "The size / thickness of the selected/focused window border":
        "选中/聚焦窗口边框的尺寸/粗细",
    "Selected window border-radius for top corners (px)":
        "选中窗口上圆角半径（px）",
    "The pixel size of border-radius for top corners":
        "上圆角的像素半径",
    "Selected window border-radius for bottom corners (px)":
        "选中窗口下圆角半径（px）",
    "The pixel size of border radius for bottom corners":
        "下圆角的像素半径",
    "Gap between windows":
        "窗口之间的间隙",
    "Horizontal margin":
        "水平边距",
    "The minimum margin to the left and right monitor edge":
        "与显示器左右边缘的最小边距",
    "Top margin":
        "上边距",
    "Bottom margin":
        "下边距",

    # ===== 窗口宽度 / 高度循环 =====
    "Useful window widths":
        "常用窗口宽度",
    "Semicolon separated values of \"useful window widths\" that will be cycled through. Values types can be either percentage (of available screen width), e.g. \"50%\" or pixel values, e.g. \"500px\". Mixed value types are not supported.":
        "用分号分隔的「常用窗口宽度」列表，会循环切换。值可以是百分比（占可用屏幕宽度），如 \"50%\"；或像素值，如 \"500px\"。不支持混用两种类型。",
    "Resets width values to the default PaperWM width values":
        "把宽度重置为 PaperWM 默认值",
    "Useful window heights":
        "常用窗口高度",
    "Semicolon separated values of \"useful window heights\" that will be cycled through. Values types can be either percentage (of available screen width), e.g. \"50%\" or pixel values, e.g. \"500px\". Mixed value types are not supported.":
        "用分号分隔的「常用窗口高度」列表，会循环切换。值可以是百分比（占可用屏幕高度），如 \"50%\"；或像素值，如 \"500px\"。不支持混用两种类型。",
    "Resets height values to the default PaperWM height values":
        "把高度重置为 PaperWM 默认值",

    # ===== 工作区页 =====
    "All workspaces": "所有工作区",
    "Per workspace": "单个工作区",
    "Configure workspace": "配置工作区",
    "Use default GNOME Shell background": "使用 GNOME Shell 默认背景",
    "Launch gnome background picker": "打开 GNOME 背景选择器",
    "Reset workspace names": "重置工作区名称",
    "Resets workspace names to default.": "把工作区名称重置为默认。",
    "Background": "背景",
    "Directory": "目录",
    "Select workspace background": "选择工作区背景",
    "Select workspace directory": "选择工作区目录",
    "Clear workspace background": "清除工作区背景",
    "Clear workspace directory": "清除工作区目录",
    "Hide Gnome Top Bar": "隐藏 GNOME 顶栏",
    "Hide Window Position Bar": "隐藏窗口位置条",

    # ===== 动画 / 视觉 =====
    "Animation / transition time (seconds)":
        "动画/过渡时长（秒）",
    "Sets the duration of PaperWM animated transitions (e.g. switching windows, workspaces etc.). Lower values result in faster transitions.":
        "设置 PaperWM 动画过渡的时长（如切换窗口、工作区等）。值越小过渡越快。",
    "Drift speed (px/ms) when using \"viewport drift\" keybinds":
        "「视口漂移」快捷键的漂移速度（px/ms）",
    "Sets the drift speed (px/ms) when using \"drifting view to the left/right\" keybinds.":
        "使用「视口向左/右漂移」快捷键时的漂移速度（px/ms）。",
    "Drift speed (px/ms) when dragging windows (at edge)":
        "拖动窗口到边缘时的漂移速度（px/ms）",
    "Sets the drift speed (px/ms) when mouse is at edge of montior when dragging windows.":
        "拖动窗口时鼠标位于显示器边缘的漂移速度（px/ms）。（原文 montior 系上游拼写错误）",

    # ===== 概览 =====
    "GNOME overview exit <i>select window</i> animation":
        "GNOME 概览退出<i>选中窗口</i>动画",
    "Sets the animation when exiting GNOME overview and ensuring selected window is in view":
        "设置退出 GNOME 概览并确保选中窗口可见时的动画",
    "<i>Minimum</i> number of windows per GNOME overview row":
        "GNOME 概览每行<i>最少</i>窗口数",
    "Sets the minimum number of windows for each row in Gnome overview. Increasing this can make Gnome overview appear more like the current tiling layout.":
        "设置 GNOME 概览中每行最少窗口数。调大可以让概览更接近当前的平铺布局。",
    "<i>Maximum</i> window scale (%) of GNOME overview windows":
        "GNOME 概览窗口的<i>最大</i>缩放（%）",
    "Controls the maximum window \"size\" of GNOME overview windows, as compared to their actual window size (e.g. \"95\" corresponds to an edge preview size being approximately 95% of the actual window size)":
        "控制 GNOME 概览窗口的最大「大小」，相对实际窗口大小。例如 \"95\" 表示约为实际窗口的 95%。",

    # ===== 边缘预览 =====
    "Enable tiling edge previews":
        "启用平铺边缘预览",
    "Enables tiling edge previews":
        "启用平铺边缘预览",
    "Tiling edge preview scale (%)":
        "平铺边缘预览缩放（%）",
    "Controls the \"size\" of tiling edge window previews, as compared to their actual window size (e.g. \"15\" corresponds to an edge preview size being approximately 15% of the actual window size)":
        "控制平铺边缘窗口预览的「大小」（相对实际窗口大小）。例如 \"15\" 表示预览约为实际窗口的 15%。",
    "Click to activate edge window":
        "点击激活边缘窗口",
    "Enables activating edge window by mouse click":
        "允许点击激活边缘窗口",
    "Hover to activate edge window":
        "悬停激活边缘窗口",
    "Enables activating edge window by hover timeout":
        "允许悬停超时后激活边缘窗口",
    "Hover timeout (milliseconds)":
        "悬停超时（毫秒）",
    "Sets the timeout before activating window (milliseconds)":
        "激活窗口前的超时（毫秒）",
    "<i>Continual </i> edge window activation on hover":
        "悬停时<i>持续</i>激活边缘窗口",
    "Enables the continual activation of windows if pointer is still at edge of monitor":
        "指针持续停在显示器边缘时不断激活窗口",

    # ===== 组件尺寸 =====
    "Mini-map scale (%) <i>(0 hides Mini-map)</i>":
        "小地图缩放（%）<i>（0 = 隐藏小地图）</i>",
    "Controls the \"size\" of mini-map tiles (as shown during window navigation keybinds), as compared to their actual window size (e.g. \"15\" corresponds to a mini-map tile size being approximately 15% of the actual window size)":
        "控制小地图缩略图的「大小」（窗口导航快捷键时显示），相对实际窗口大小。例如 \"15\" 表示缩略图约为实际窗口的 15%。",
    "Dimming opacity of windows during mini-map navigation":
        "小地图导航时窗口的变暗不透明度",
    "Sets the opacity [5-255] of the dimming/shade used on non-selected windows during mini-map navigation.":
        "设置小地图导航时非选中窗口变暗的不透明度 [5-255]。",
    "Window-switcher preview scale (%)":
        "窗口切换器预览缩放（%）",
    "Controls the \"size\" of window switcher previews (e.g. Super+Tab switcher), as compared to their actual window size (e.g. \"15\" corresponds to an edge preview size being approximately 15% of the actual window size)":
        "控制窗口切换器预览的「大小」（如 Super+Tab），相对实际窗口大小。例如 \"15\" 表示预览约为实际窗口的 15%。",

    # ===== 手势 =====
    "Enable Touchpad Gestures":
        "启用触控板手势",
    "Enables / disables PaperWM gestures. Disabling this restores Gnome's default touchpad gestures.":
        "启用/禁用 PaperWM 手势。禁用后恢复 GNOME 默认的触控板手势。",
    "Swipe tiling windows <i>(swipe left/right)</i>":
        "滑动平铺窗口 <i>（左右滑）</i>",
    "Sets the number of fingers used for moving the tiling viewport (windows) left/right.":
        "设置左右移动平铺视口（窗口）所需的手指数。",
    "PaperWM workspace switching <i>(swipe down)</i>":
        "PaperWM 工作区切换 <i>（下滑）</i>",
    "Sets the number of fingers used for PaperWM workspace stack view.":
        "设置 PaperWM 工作区堆叠视图所需的手指数。",
    "Horizontal sensitivity": "水平灵敏度",
    "Horizontal friction": "水平摩擦",
    "Vertical sensitivity": "垂直灵敏度",
    "Vertical friction": "垂直摩擦",

    # ===== 打开窗口位置选项 =====
    "Availble options for the <i>open window position</i> button. \n\nSelected options will be cycled through when clicking the\nbutton or using the <i>Switch between positions for creating windows (e.g. right, left)</i> shortcut.":
        "<i>打开窗口位置</i>按钮的可用选项。\n\n点击该按钮或使用<i>切换新建窗口位置</i>快捷键时，会在已选选项之间循环。（原文 Availble 系上游拼写错误）",
    "RIGHT": "右侧",
    "LEFT": "左侧",
    "DOWN": "下方",
    "UP": "上方",
    "START": "开头",
    "END": "末尾",

    # ===== Winprops 页 =====
    "Add Winprop": "添加窗口属性",
    "<i>Winprops allow setting window properties to be applied to new windows</i>":
        "<i>窗口属性（Winprops）可以为新窗口预设属性</i>",
    "wm_class": "窗口类名",
    "Window class value used to identify windows to have this winprop applied.  Can be a <b>string</b> or <b>javascript regex expression literal</b>, e.g. <b>/.*terminal.*/i</b> would match on any value that contains the word <b>terminal</b> (case-insensitive).":
        "用于识别要应用此属性的窗口的「窗口类名」值。可以是 <b>字符串</b>，也可以是 <b>JavaScript 正则字面量</b>；例如 <b>/.*terminal.*/i</b> 会匹配任何包含 <b>terminal</b> 的值（不区分大小写）。",
    "title": "窗口标题",
    "Window title value used to identify windows to have this winprop applied.  Can be a <b>string</b> or <b>javascript regex expression literal</b>, e.g. <b>/.*terminal.*/i</b> would match on any value that contains the word <b>terminal</b> (case-insensitive).":
        "用于识别要应用此属性的窗口的「窗口标题」值。可以是 <b>字符串</b>，也可以是 <b>JavaScript 正则字面量</b>；例如 <b>/.*terminal.*/i</b> 会匹配任何包含 <b>terminal</b> 的值（不区分大小写）。",
    "Open on scratch layer": "在暂存层打开",
    "Preferred width <i>(with <b>%</b> or <b>px</b> unit)</i>":
        "首选宽度 <i>（带 <b>%</b> 或 <b>px</b> 单位）</i>",
    "Preferred width.  Can be a percent value (e.g. <i>50%</i>) or pixel value (e.g. <i>500px</i>). <i>Note: this property is ignored for windows opened on the scratch layer.</i>":
        "首选宽度。可以是百分比（如 <i>50%</i>）或像素值（如 <i>500px</i>）。<i>注意：在暂存层打开的窗口会忽略此属性。</i>",
    "Insert into workspace": "插入到工作区",
    "Focus window after inserting into workspace": "插入工作区后聚焦该窗口",
    "Delete": "删除",

    # ===== 快捷键页（行内按钮）=====
    "Add shortcut…": "添加快捷键…",
    "<i>Add shortcut…</i>": "<i>添加快捷键…</i>",
    "Remove shortcut": "移除快捷键",
    "Enter keyboard shortcut, <b>Backspace</b> to delete or <b>Esc</b> to cancel":
        "按下键盘快捷键；<b>Backspace</b> 删除，<b>Esc</b> 取消",
    "Conflicts": "冲突",
    "Conflicts:": "冲突：",
    "Disabled": "已禁用",
    "Reset": "重置",
    "Copies PaperWM version information to clipboard":
        "复制 PaperWM 版本信息到剪贴板",

    # ===== 快捷键说明（来自 gschema.xml 的 summary）=====
    # --- Windows ---
    "Open new window": "打开新窗口",
    "Close the active window": "关闭当前窗口",
    "Switch to the next window": "切到下一个窗口",
    "Switch to the previous window": "切到上一个窗口",
    "Switch to the left window": "切到左边窗口",
    "Switch to the right window": "切到右边窗口",
    "Switch to the window above": "切到上方窗口",
    "Switch to the window below": "切到下方窗口",
    "Switch to the next window (with wrap-around)": "切到下一个窗口（循环）",
    "Switch to the previous window (with wrap-around)": "切到上一个窗口（循环）",
    "Switch to the left window (with wrap-around)": "切到左边窗口（循环）",
    "Switch to the right window (with wrap-around)": "切到右边窗口（循环）",
    "Switch to the window above (with wrap-around)": "切到上方窗口（循环）",
    "Switch to the window below (with wrap-around)": "切到下方窗口（循环）",
    "Drift tiling viewport to the left": "平铺视口向左漂移",
    "Drift tiling viewport to the right": "平铺视口向右漂移",
    "Switch to window or monitor to the left": "切到左侧的窗口或显示器",
    "Switch to window or monitor to the right": "切到右侧的窗口或显示器",
    "Switch to window or monitor above": "切到上方的窗口或显示器",
    "Switch to window or monitor below": "切到下方的窗口或显示器",
    "Switch to window or workspace above": "切到上方窗口；没有了就切上方工作区",
    "Switch to window or workspace below": "切到下方窗口；没有了就切下方工作区",
    "Switch to the first window": "切到第 1 个窗口",
    "Switch to the second window": "切到第 2 个窗口",
    "Switch to the third window": "切到第 3 个窗口",
    "Switch to the fourth window": "切到第 4 个窗口",
    "Switch to the fifth window": "切到第 5 个窗口",
    "Switch to the sixth window": "切到第 6 个窗口",
    "Switch to the seventh window": "切到第 7 个窗口",
    "Switch to the eighth window": "切到第 8 个窗口",
    "Switch to the ninth window": "切到第 9 个窗口",
    "Switch to the tenth window": "切到第 10 个窗口",
    "Switch to the eleventh window": "切到第 11 个窗口",
    "Switch to the last window": "切到最后一个窗口",
    "Switch to previously active window": "切到上一次活动的窗口（实时 Alt+Tab）",
    "Switch to previously active window, backward order": "切到上一次活动的窗口（反向顺序）",
    "Switch to previously active scratch window": "切到上一次活动的暂存层窗口",
    "Switch to previously active scratch window, backward order": "切到上一次活动的暂存层窗口（反向顺序）",
    "Switch between Window Focus Modes (e.g. default, center)": "切换窗口聚焦模式（默认 / 居中 / 边缘）",
    "Switch between positions for creating/dropping windows": "切换新建/放置窗口的位置",
    "Create/drop windows to the right": "在右侧创建/放置窗口",
    "Create/drop windows to the left": "在左侧创建/放置窗口",
    "Create/drop windows in vertical stack (down)": "在下方垂直堆叠创建/放置窗口",
    "Create/drop windows in vertical stack (up)": "在上方垂直堆叠创建/放置窗口",
    "Create/drop windows at start position": "在开头创建/放置窗口",
    "Create/drop windows at end position": "在末尾创建/放置窗口",
    "Move the active window to the left": "当前窗口左移",
    "Move the active window to the right": "当前窗口右移",
    "Move the active window up": "当前窗口上移",
    "Move the active window down": "当前窗口下移",
    "Consume window into the active column": "把相邻窗口并入当前列",
    "Expel the bottom window into its own column": "把最下方窗口拆成独立列",
    "Expel the active window into its own column": "把当前窗口拆成独立列",
    "Center window horizontally": "窗口水平居中",
    "Center window vertically (non-tiled window)": "窗口垂直居中（非平铺窗口）",
    "Center window": "窗口居中",
    "Toggle fullscreen": "切换全屏",
    "Maximize the width of the active window": "最大化当前窗口宽度",
    "Increment window height": "增加窗口高度",
    "Decrement window height": "减小窗口高度",
    "Increment window width": "增加窗口宽度",
    "Decrement window width": "减小窗口宽度",
    "Cycle through useful window widths": "循环切换常用窗口宽度",
    "Cycle through useful window widths backwards": "循环切换常用窗口宽度（反向）",
    "Cycle through useful window heights": "循环切换常用窗口高度",
    "Cycle through useful window heights backwards": "循环切换常用窗口高度（反向）",
    "Take the window, dropping it when finished navigating": "抓取窗口，导航结束后放下",
    "Activate the window under mouse cursor": "激活鼠标指针下的窗口",
    # --- Workspaces ---
    "Switch to previously active workspace": "切到上一次活动的工作区",
    "Switch to the previously active workspace, backward order": "切到上一次活动的工作区（反向顺序）",
    "Move the active window to the previously active workspace": "把当前窗口移到上一次活动的工作区",
    "Move the active window to the previously active workspace, backward order": "把当前窗口移到上一次活动的工作区（反向顺序）",
    "Switch to workspace above (ws only from current monitor)": "切到上方工作区（仅当前显示器）",
    "Switch to workspace below (ws only from current monitor)": "切到下方工作区（仅当前显示器）",
    "Switch to workspace above (ws from all monitors)": "切到上方工作区（跨所有显示器）",
    "Switch to workspace below (ws from all monitors)": "切到下方工作区（跨所有显示器）",
    "Move window one workspace up": "把窗口上移一个工作区",
    "Move window one workspace down": "把窗口下移一个工作区",
    "Toggle the Top Bar and Window Position Bar on current workspace": "切换当前工作区的顶栏和窗口位置条",
    "Toggle the Top Bar on current workspace": "切换当前工作区的顶栏",
    "Toggle the Window Position Bar on current workspace": "切换当前工作区的窗口位置条",
    # --- Monitors ---
    "Switch to the right monitor": "切到右侧显示器",
    "Switch to the left monitor": "切到左侧显示器",
    "Switch to the above monitor": "切到上方显示器",
    "Switch to the below monitor": "切到下方显示器",
    "Move workspace to monitor on the right": "把工作区移到右侧显示器",
    "Move workspace to monitor on the left": "把工作区移到左侧显示器",
    "Move workspace to monitor above": "把工作区移到上方显示器",
    "Move workspace to monitor below": "把工作区移到下方显示器",
    "Swap workspace with monitor to the right": "与右侧显示器交换工作区",
    "Swap workspace with monitor to the left": "与左侧显示器交换工作区",
    "Swap workspace with monitor above": "与上方显示器交换工作区",
    "Swap workspace with monitor below": "与下方显示器交换工作区",
    "Move the active window to the right monitor": "把当前窗口移到右侧显示器",
    "Move the active window to the left monitor": "把当前窗口移到左侧显示器",
    "Move the active window to the above monitor": "把当前窗口移到上方显示器",
    "Move the active window to the below monitor": "把当前窗口移到下方显示器",
    # --- Scratch ---
    "Toggles the floating scratch layer": "显示/隐藏浮动暂存层",
    "Attach/detach the active window into the scratch layer": "把当前窗口加入/移出暂存层",
    "Toggle the most recent scratch window": "显示/隐藏最近用过的暂存窗口",
}

# 数值/占位字符串，跳过
SKIP = {"0", "0,0"}
# 这几个词太通用：在 JS 里会被当成对象键替换掉代码，只对 JS 文件跳过
# （在 .ui 里它们是 Winprops 的字段标签，需要翻译）
JS_SKIP = SKIP | {"title", "wm_class"}

UI_PROP = re.compile(
    r'<property name="([a-z_]+)" translatable="yes">([^<]*)</property>'
)
SUMMARY = re.compile(r"<summary>([^<]+)</summary>")
JS_STR = re.compile(r"'([^'\\]*)'")


def _norm(s):
    return re.sub(r"\s+", " ", s).strip()


# 归一化后的查找表：原文里有多处双空格、折行缩进，统一成单空格再查
NMAP = {_norm(k): v for k, v in MAP.items()}


def _zh(plain, skip=SKIP):
    """查表，返回中文；查不到返回 None。plain 会先归一化空白。"""
    key = _norm(plain)
    if key in skip or key not in NMAP:
        return None
    return NMAP[key]


def _tr(plain, skip=SKIP):
    """返回 '英文 / 中文'（用于单行场景）；查不到返回 None"""
    key = _norm(plain)
    if key in skip or key not in NMAP:
        return None
    return f"{key} / {NMAP[key]}"


def do_ui(path, check):
    src = open(path, encoding="utf-8").read()
    hits = []

    def repl(mo):
        name, raw = mo.group(1), mo.group(2)
        zh = _zh(html.unescape(raw))
        if zh is None:
            return mo.group(0)
        hits.append(html.unescape(raw).strip()[:40])
        # 保留原文（含折行），中文追加在后面
        return (f'<property name="{name}" translatable="yes">'
                f'{raw} / {html.escape(zh, quote=False)}</property>')

    new = UI_PROP.sub(repl, src)
    if not check and hits:
        open(path, "w", encoding="utf-8").write(new)
    return hits


def do_schema(path, check):
    src = open(path, encoding="utf-8").read()
    hits = []

    def repl(mo):
        plain = html.unescape(mo.group(1)).strip()
        out = _tr(plain)
        if out is None:
            return mo.group(0)
        hits.append(plain)
        return f"<summary>{html.escape(out, quote=False)}</summary>"

    new = SUMMARY.sub(repl, src)
    if not check and hits:
        open(path, "w", encoding="utf-8").write(new)
    return hits


def do_prefs(path, check):
    """
    用精确字面量替换，不用正则。
    原因：JS 里双引号字符串中的撇号（如 "it's"）会让 '...' 的配对错位，
    通用正则匹配到的是错的片段（实测 277 个匹配里一个目标都没有）。
    这里只替换「'英文原文'」或「"英文原文"」这种完整字面量 —— 英文原文都是
    很具体的句子，不会误伤。
    """
    src = open(path, encoding="utf-8").read()
    hits = []
    for en, zh in MAP.items():
        if en in JS_SKIP:
            continue
        for q in ("'", '"'):
            lit = f"{q}{en}{q}"
            n = src.count(lit)
            if n:
                src = src.replace(lit, f"{q}{en} / {zh}{q}")
                hits.extend([en] * n)
    if not check and hits:
        open(path, "w", encoding="utf-8").write(src)
    return hits


def main():
    args = [a for a in sys.argv[1:] if a != "--check"]
    check = "--check" in sys.argv
    if not args:
        print("用法: paperwm-zh.py [--check] <扩展目录>")
        return 1
    root = args[0]
    if not os.path.isdir(root):
        print(f"目录不存在: {root}")
        return 1

    total = 0
    files = sorted(glob.glob(os.path.join(root, "*.ui")))
    files += sorted(glob.glob(os.path.join(root, "schemas", "*.gschema.xml")))
    files += [os.path.join(root, "prefs.js")]

    for f in files:
        if not os.path.isfile(f):
            continue
        if f.endswith(".ui"):
            hits = do_ui(f, check)
        elif f.endswith(".gschema.xml"):
            hits = do_schema(f, check)
        else:
            hits = do_prefs(f, check)
        if hits:
            total += len(hits)
            print(f"  {os.path.basename(f):26} {len(hits):3} 处")
    print(f"  {'合计':26} {total:3} 处 {'（--check 模式，未写入）' if check else '已中文化'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
