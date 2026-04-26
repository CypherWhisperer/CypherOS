# NOTE:
# vault ≥ 1.15 is BSL/unfree. Hydra last built 1.14.8.
# If you need vault for secrets management, you have two real options:
# use the vault package with nixpkgs.config.allowUnfree = true and accept
# that it will build from source (it's Go, so it will compile, just takes time and RAM),
# or switch to bws (Bitwarden Secrets Manager CLI) or age/sops-nix for secrets
# management — both of which are fully free, Hydra-cached, and arguably better
# suited to a NixOS declarative workflow than vault anyway.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config =
    lib.mkIf (config.cypher-os.devops.secrets.enable && config.cypher-os.devops.secrets.vault.enable)
      {
        environment.systemPackages = with pkgs; [
          # ── HashiCorp Vault (CLI) ─────────────────────────────────────────────────
          # vault: CLI for interacting with HashiCorp Vault, the enterprise-grade
          # secrets management platform. Vault runs as a server; this is the client.
          # You'll encounter Vault in team/production contexts. Learn the concepts:
          #   - Secrets engines (KV, database, PKI, SSH)
          #   - Auth methods (token, AppRole, Kubernetes)
          #   - Policies and leases
          # For a local Vault dev server: vault server -dev
          # Usage: vault kv put secret/my-app api_key=abc123
          #        vault kv get secret/my-app
          #
          # Since hydra does not build the package due to a change in licensing,
          # We have two options:
          #   1. Build from source (compute and time)
          #   2. Use the (container) 'hack'
          # Currently going with option 2 - hence the import. Uncomment for build and run:
          #
          # Build vault in isolation — one job, two cores, explicitly allow the source build.
          # Do this when the machine is idle
          #      nix build nixpkgs#vault \
          #        --option max-jobs 1 \
          #        --option cores 2 \
          #        --option fallback true \
          #        --option sandbox true
          #
          vault
        ];
      };
}
