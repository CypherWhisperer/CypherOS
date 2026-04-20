# modules/devops/system.nix
#
# Top-level aggregator for the devops module subtree.
#
# WHAT THIS FILE OWNS:
#   - Importing all devops submodules into the NixOS module system
#   - Nothing else — it is a pure router. No packages, no services here.
#
# WHAT THIS FILE DOES NOT OWN:
#   - Individual tooling declarations (those live in the submodules)
#   - The Docker daemon (declared in containers.nix, extracted from configuration.nix)
#
# ARCHITECTURE:
#   This module directory is structured as NixOS modules, NOT Home Manager modules.
#   The reason: several devops components are system-level services (k3s, postgresql,
#   redis, docker, podman daemon) that must be declared in the NixOS module system.
#   CLI tools that have no daemon counterpart could live in HM, but keeping the
#   entire devops subtree in one place avoids confusing split ownership.
#
#   Import this file from your host configuration:
#
#     imports = [
#       ...
#       ../../modules/devops
#       # or explicitly: ../../modules/devops/default.nix
#     ];
#
#   Then toggle subsystems from your host configuration.nix:
#
#     devops.containers.enable  = true;
#     devops.kubernetes.enable  = true;
#     devops.databases.enable   = true;
#     devops.iac.enable         = true;
#     devops.secrets.enable     = true;
#
# ADDING NEW SUBMODULES:
#   1. Create modules/devops/<name>.nix
#   2. Add it to the imports list below
#   3. Add its enable option to your host configuration

{
  # config,
  # pkgs,
  # lib,
  ...
}:

{

  imports = [
    ../profile/options.nix
    ./options.nix
    ./containers.nix
    ./kubernetes.nix
    ./databases.nix
    ./iac.nix
    ./secrets.nix
  ];

  # config = lib.mkIf config.cypher-os.devops.enable  {
  #   # Enable the options from the imported modules.
  #   # ─────────────────────────────────────────────────────────────────────────────
  #   # DEVOPS MODULE TOGGLES
  #   # ─────────────────────────────────────────────────────────────────────────────
  #   # Each line here activates an entire devops subsystem defined in modules/devops/.
  #   # Set to false (or remove the line) to exclude a subsystem from this host.
  #   # Useful when building a lighter config for a machine that doesn't need all tooling.
  #   cypher-os.devops.containers.enable = lib.mkDefault true; # Docker + Podman stacks, image tooling
  #   cypher-os.devops.kubernetes.enable = lib.mkDefault true; # k3s service, kubectl, Helm, k3d, kind
  #   cypher-os.devops.databases.enable = lib.mkDefault true; # PostgreSQL + Redis services, DB GUIs
  #   cypher-os.devops.iac.enable = lib.mkDefault true; # Terraform, OpenTofu, Ansible, Pulumi
  #   cypher-os.devops.secrets.enable = lib.mkDefault true; # sops, age, gnupg, vault
  # };
}
