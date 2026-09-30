# MOSS 听写（全局语音输入）运行所需的三项系统权限。
#
# 背景：项目 ~/Data/项目/语音输入法测试/moss-voice 通过 /dev/input 读物理按键
# 作为听写触发键，通过 /dev/uinput 合成 Ctrl+V 粘贴键把文字送进焦点窗口。
# 三项缺一不可，且必须与 home.nix 里的 systemd.user.services.moss-voice
# 在同一次 rebuild 生效——否则常驻的是一个必然失败的进程。
#
# 决策依据：docs/adr/0001（弃用 IBus，改用合成按键）、
#          docs/adr/0002（剪贴板 + 合成粘贴键注入）
{ config, lib, pkgs, ... }:

{
  # 1) 读 /dev/input/event*：捕获麦克风静音键的按下/抬起。
  #    组成员写在 configuration.nix 的 users.users.ron.extraGroups
  #    （普通 list 是覆盖语义，模块里再赋一次会冲掉 networkmanager/wheel）。
  #    红线声明：input 组可读取本机所有键盘的输入流，在权限模型上等同于
  #    为该账号安装 keylogger。本项目不外传、不记录任何按键内容，只比较
  #    一个 keycode 做边沿触发。撤销方式：从 extraGroups 移除 "input"。

  # 2) uinput 内核模块：创建虚拟键盘设备，用它合成粘贴按键。
  #    实测缺此模块时 /dev/uinput 只是残留节点（root:root 0600）。
  boot.kernelModules = [ "uinput" ];

  # 3) 允许 ron 写 /dev/uinput。
  #    实测默认状态：crw------- root:root，ron 打开直接 EACCES。
  #    只给 uinput 一个节点授权，不扩大到其它 input 设备。
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess"
  '';
}
