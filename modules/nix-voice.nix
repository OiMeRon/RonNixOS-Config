# Nix Voice lives in its own repository. This file is only the import, so the
# systemd unit, the uinput module and the udev rule are defined once, next to
# the code they run, instead of being copied here and drifting.
#
# Project: ~/Data/项目/语音输入法测试/nix-voice
# Module:  nix/module.nix there — see its comments for the three permissions
#         and why they must land in the same rebuild.
#
# The group membership itself stays in configuration.nix
# (users.users.ron.extraGroups): a plain list there is override semantics, so
# setting it from a module would drop networkmanager and wheel.
{ ... }:

{
# Nix refuses a path literal containing non-ASCII bytes ("path has a trailing
  # slash"), so the import goes through an ASCII symlink.
  imports = [ /home/ron/nix-voice/nix/module.nix ];

  services.nix-voice.enable = true;
}
