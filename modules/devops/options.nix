# modules/devops/options.nix
#
# Declares cypher-os.devops.* options.
# Imported unconditionally by modules/home/default.nix so the option
# exists in the merged set before any mkIf references it.
# No config lives here — only option shapes.

{ lib, ... }:

{
  options.cypher-os.devops = {
    enable = lib.mkEnableOption "Enable DevOps infrastructure";

    databases.enable = lib.mkEnableOption  "local development database services (PostgreSQL, Redis, SQLite, MongoDB tools)";
    containers.enable = lib.mkEnableOption "container tooling (Docker, Podman, image inspection, scanning)";
    iac.enable = lib.mkEnableOption    "Infrastructure as Code tooling (Terraform, OpenTofu, Ansible, Pulumi)";
    kubernetes.enable = lib.mkEnableOption "Kubernetes tooling (k3s, kubectl, Helm, k3d, kind, cluster utilities)";
    secrets.enable = lib.mkEnableOption "secrets management tooling (sops-nix, age, Vault)";
    n8n.enable = lib.mkEnableOption "n8n Automation tool";
  };
}
