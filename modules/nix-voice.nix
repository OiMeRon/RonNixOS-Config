# Nix Voice lives in its own repository. This file is only the import, so the
# systemd unit, the uinput module and the udev rule are defined once, next to
# the code they run, instead of being copied here and drifting.
#
# Project: ~/OmniStudio/Applications/Owned/nix-voice
# Flake:  there too, exposing nixosModules.nix-voice — imported below through
#         the input declared in ../flake.nix, not through a path.
#
# The group membership itself stays in configuration.nix
# (users.users.ron.extraGroups): a plain list there is override semantics, so
# setting it from a module would drop networkmanager and wheel.
{ nix-voice, ... }:

{
  # The module comes from the nix-voice flake input, declared in ../flake.nix.
  #
  # This used to be `imports = [ /home/ron/nix-voice/nix/module.nix ]`. Two
  # things were wrong with it: an absolute path literal is refused in pure
  # evaluation mode, so `nix flake check` failed on every run; and the module was
  # invisible to the flake, so nothing tracked when nix-voice's own flake.nix
  # changed shape.
  imports = [ nix-voice.nixosModules.nix-voice ];

  services.nix-voice.enable = true;
}
