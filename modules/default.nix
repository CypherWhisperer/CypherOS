{ ... }:

{
  imports = [
    ./profile # declares cypher-os.profile.{desktop,server}.enable
    ./shell # declares cypher-os.shell.* options
    ./de # declares cypher-os.de.{gnome,plasma,hyprland}.enable
    ./dm # declares cypher-os.dm.{gdm,sddm}.enable
    ./apps # declares cypher-os.apps.* options + wires app modules
    ./gaming # declares cypher-os.gaming.enable
    ./devops # declares cypher-os.devops.* options
    ./virtualisation # declares cypher-os.virtualisation.helpers.enable

    # imported directly in configuration.nix for now.
    # ./users # declares the cypher-whisperer user identity
  ];

}
