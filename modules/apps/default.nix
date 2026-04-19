{ ... }:

{
  imports = [
    # This module declares the cypher-os.apps.enable option.
    ./options.nix
    # Each of these modules declares its own cypher-os.apps.[group].enable option.
    # and handles all its relevant modules within the group.
    ./browser
    ./cli
    ./common
    ./dev
    ./editor
    ./productivity
    ./shell
    ./terminal
  ];
}
