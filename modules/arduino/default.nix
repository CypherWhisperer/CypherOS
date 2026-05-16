# modules/arduino/default.nix
#
# Router — exposes the Arduino subsystem to Home Manager evaluation.

{ ... }:

{
  imports = [
    ./options.nix
    ./hm.nix
  ];
}
