# modules/devops/vault.nix
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
          vault
        ];
      };
}
