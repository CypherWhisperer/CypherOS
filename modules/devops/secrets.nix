# modules/devops/secrets.nix
#
# NixOS module for secrets management tooling.
#
# WHAT THIS FILE OWNS:
#   - sops-nix NixOS module configuration
#   - age encryption tool
#   - HashiCorp Vault CLI
#   - gnupg (required for SOPS GPG backend, optional if using age-only)
#
# WHAT THIS FILE DOES NOT OWN:
#   - The actual secrets — encrypted files live in your repo, decrypted values
#     are written to /run/secrets/ at activation time and NEVER committed
#   - Private keys — generated once, stored in ~/.config/sops/age/keys.txt
#     (for age) or the GPG keyring. Never in Nix, never in the repo.
#
# THE SOPS-NIX WORKFLOW:
#   sops-nix integrates SOPS (Secrets OPerationS) into NixOS so secrets are
#   decrypted at system activation and made available as files under /run/secrets/.
#
#   The encryption chain:
#     plaintext secret
#       → encrypted with your age public key (or GPG key)
#       → committed to git as an encrypted .yaml/.json file
#       → decrypted by sops-nix at `nixos-rebuild switch` time
#       → written to /run/secrets/<name> with correct permissions
#
#   Your app reads from /run/secrets/<name>, never from the Nix store
#   (which is world-readable). This is the correct pattern for NixOS secrets.
#
# FIRST-TIME SETUP (one-time, manual):
#   1. Generate an age key:
#        mkdir -p ~/.config/sops/age
#        age-keygen -o ~/.config/sops/age/keys.txt
#        # Note the public key printed to stdout — you need it for .sops.yaml
#
#   2. Create a .sops.yaml at the root of your repo (e.g CypherOS):
#        creation_rules:
#          - path_regex: secrets/.*\.yaml$
#            age: >-
#              <your-age-public-key-here>
#
#   3. Create and edit a secret:
#        mkdir -p secrets
#        sops secrets/my-secret.yaml
#        # This opens your editor with an empty YAML file.
#        # Add key: value pairs. Save and quit — sops encrypts automatically.
#
#   4. Reference the secret in a NixOS module:
#        sops.secrets.my_api_key = {
#          sopsFile = ../../secrets/my-secret.yaml;
#        };
#        # Then in your app config:
#        environment.variables.MY_API_KEY = config.sops.secrets.my_api_key.path;
#        # (path = /run/secrets/my_api_key — the decrypted file at runtime)
#
# ENABLE:
#   devops.secrets.enable = true;  in your host configuration.nix
#   AND add sops-nix to your flake inputs (see note below).
#
# FLAKE INTEGRATION NOTE:
#   sops-nix must be added as a flake input before this module can be fully used.
#   Add to flake.nix inputs:
#
#     sops-nix = {
#       url = "github:Mic92/sops-nix";
#       inputs.nixpkgs.follows = "nixpkgs";
#     };
#
#   And pass it through specialArgs + import the module in your host configuration:
#
#     modules = [
#       inputs.sops-nix.nixosModules.sops
#       ...
#     ];
#
#   The sops.* options below (sops.defaultSopsFile, etc.) become available only
#   after importing that NixOS module.
#
# VERIFYING THE SETUP:
#   age-keygen --version
#   sops --version
#   vault --version

{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (
    config.cypher-os.devops.enable &&
    config.cypher-os.devops.secrets.enable ) {

    # ── sops-nix Configuration ─────────────────────────────────────────────────
    # sops.* options are provided by the sops-nix NixOS module, which must be
    # imported separately in your flake (see FLAKE INTEGRATION NOTE above).
    # This block is commented out until you add sops-nix to flake.nix.
    #
    # Once Added, uncomment and adjust:
    #
    # sops = {
    #   # defaultSopsFile: the default encrypted secrets file. Individual secret
    #   # declarations can override this per-secret if needed.
    #   defaultSopsFile = ../../secrets/secrets.yaml;
    #
    #   # age.keyFile: where sops finds your private age key at activation time.
    #   # This path must exist on the machine — it's not managed by Nix (intentionally).
    #   age.keyFile = "/home/cypher-whisperer/.config/sops/age/keys.txt";
    #
    #   # age.generateKey: false. We generate the key manually (see FIRST-TIME SETUP).
    #   # Setting true would auto-generate a key, but then the public key is unknown
    #   # until the first activation — chicken-and-egg for encrypting secrets.
    #   age.generateKey = false;
    #
    #   # secrets: declare which secrets to decrypt and where to place them.
    #   # Each key becomes a file under /run/secrets/<key>.
    #   # Example:
    #   # secrets.example_api_key = {
    #   #   sopsFile = ../../secrets/api-keys.yaml;
    #   #   owner = "cypher-whisperer";  # who can read /run/secrets/example_api_key
    #   #   mode = "0400";               # permissions (owner read-only)
    #   # };
    # };

    environment.systemPackages = with pkgs; [

      # ── SOPS ──────────────────────────────────────────────────────────────────
      # SOPS: Secrets OPerationS. CLI for encrypting/decrypting secret files.
      # Supports age, GPG, AWS KMS, GCP KMS, Azure Key Vault backends.
      # For personal/self-hosted use: age backend is the simplest.
      # Usage: sops secrets/my-secret.yaml   (edit in-place, encrypted on save)
      #        sops -d secrets/my-secret.yaml  (decrypt to stdout)
      sops

      # ── age ───────────────────────────────────────────────────────────────────
      # age: modern file encryption tool. Simpler than GPG, no key server needed.
      # Used as the encryption backend for sops above.
      # age-keygen generates key pairs; age encrypts/decrypts files directly.
      # Usage: age-keygen -o key.txt
      #        age -r <recipient-pubkey> -o encrypted.age plaintext.txt
      #        age -d -i key.txt encrypted.age
      age

      # ── gnupg ─────────────────────────────────────────────────────────────────
      # GnuPG: the GPG implementation. Required if you use the GPG backend for
      # SOPS (alternative to age). Also needed for signing git commits and
      # verifying signed packages/releases.
      # Recommendation: use age for SOPS, but keep gnupg for git signing and
      # package verification.
      gnupg

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

      mkcert # generate locally-trusted TLS certs for dev
    ];

  };
}
