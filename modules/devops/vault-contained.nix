# =============================================================================
# CypherOS — DevOps :: HashiCorp Vault (OCI Container)
# =============================================================================
# modules/cypher-os/devops/vault.nix
#
# ARCHITECTURE DECISION:
#   vault >= 1.15 uses the HashiCorp BSL license. Hydra (NixOS CI) does not
#   build BSL-licensed packages. The last Hydra binary was vault-1.14.8
#   (December 2023). Running vault via OCI container pulls the official
#   HashiCorp image which ships current releases with binaries built and
#   signed by HashiCorp.
#
# VAULT MODES:
#   dev     — in-memory storage, auto-unsealed, root token printed to stdout.
#             NEVER use for real secrets. Data lost on container restart.
#             Use for: learning the vault API, testing policies.
#
#   server  — persistent storage (file backend here), requires manual unseal
#             on each restart (or auto-unseal via cloud KMS / transit).
#             Use for: actual secrets management.
#
#   This config starts in SERVER mode with file storage. The tradeoff vs dev
#   mode: you must unseal vault after every restart. The unseal key and root
#   token are generated on first `vault operator init` — store them securely
#   (in Proton Pass, offline, etc). Never lose them.
#
# VAULT CONCEPTS (for internalization):
#   Seal/Unseal: Vault encrypts its storage with a master key split into
#     "key shares" (Shamir's Secret Sharing). On start, it's "sealed" and
#     cannot decrypt anything until enough key shares are provided to
#     reconstruct the master key. This is a security property — even if
#     someone steals the storage backend, they can't read it without the
#     unseal keys.
#
#   Token: How vault authenticates requests. The root token has full access.
#     In production, create limited tokens via `vault token create` or
#     use auth methods (AppRole, LDAP, etc).
#
#   Secret Engine: vault supports multiple backends — KV (key-value), PKI
#     (certificate authority), SSH (signed certificates), etc.
#     Enable them at mount paths: `vault secrets enable -path=secret kv-v2`
#
# FIRST-RUN PROCEDURE (run after `sudo nixos-rebuild switch`):
#   1. Check vault started:
#        journalctl -u docker-vault -f
#   2. Initialize vault (generates unseal keys + root token):
#        docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault \
#          vault operator init -key-shares=3 -key-threshold=2
#      Save ALL output — this is the ONLY time you'll see the unseal keys.
#   3. Unseal (repeat for 2 of the 3 keys):
#        docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault \
#          vault operator unseal <unseal-key-1>
#        docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault \
#          vault operator unseal <unseal-key-2>
#   4. Log in:
#        docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault \
#          vault login <root-token>
#   5. Enable a KV secrets engine:
#        docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault \
#          vault secrets enable -path=secret kv-v2
#
# AFTER EVERY SYSTEM RESTART:
#   Vault starts sealed. Run step 3 again (unseal with 2 of 3 keys).
#   This is intentional — it's the security guarantee of vault.
#   For automated unseal, see VAULT_SEAL_TYPE options below (commented).
# =============================================================================

{
  config,
  lib,
  ...
}:

{
  config =
    lib.mkIf (config.cypher-os.devops.secrets.enable && config.cypher-os.devops.secrets.vault.enable)
      {

        # =========================================================================
        # Vault HCL configuration
        # =========================================================================
        # Vault reads its configuration from /vault/config/*.hcl inside the
        # container. We write this file to the host and bind-mount it in.
        # Using environment.etc places it at /etc/vault/vault.hcl on the host.
        #
        # This is the declarative approach: vault's runtime config is expressed
        # in your NixOS config, version-controlled, and rebuilt on every switch.
        # =========================================================================
        environment.etc."vault/vault.hcl" = {
          # mode 0440: readable by root and the vault process, not world-readable
          mode = "0440";
          text = ''
            # ── Storage backend ───────────────────────────────────────────────────
            # "file" backend: vault stores encrypted secrets on disk at /vault/file
            # inside the container (bind-mounted to /var/lib/vault/data on host).
            # Simple, no external dependencies. Fine for a single-node personal setup.
            #
            # Production alternatives:
            #   storage "raft" { ... }   — integrated Raft consensus, multi-node HA
            #   storage "consul" { ... } — Consul backend (requires Consul cluster)
            storage "file" {
              path = "/vault/file"
            }

            # ── Listener ──────────────────────────────────────────────────────────
            # Vault listens on port 8200 inside the container.
            # tls_disable = true because TLS termination is handled by Caddy on
            # the host, not by vault itself. This is correct and standard for a
            # reverse-proxied vault.
            #
            # IMPORTANT: tls_disable is acceptable ONLY when vault is bound to
            # localhost and not directly exposed. Never disable TLS on a
            # network-exposed vault listener.
            listener "tcp" {
              address     = "0.0.0.0:8200"
              tls_disable = true
            }

            # ── API address ───────────────────────────────────────────────────────
            # Used by vault to build its own redirect URLs and HA advertisements.
            # Set to localhost since we're not exposing vault externally.
            api_addr = "http://127.0.0.1:8200"

            # ── UI ────────────────────────────────────────────────────────────────
            # Enable the vault web UI at http://localhost:8200/ui
            # Useful for exploring vault during learning. Can be disabled in
            # production where you interact only via CLI/API.
            ui = true

            # ── Auto-unseal (commented — manual unseal is fine for personal use) ──
            # On every restart, vault starts sealed and requires manual unseal.
            # For a dev machine this is acceptable — you unseal once after boot.
            # For production or always-on setups, consider auto-unseal:
            #
            # seal "awskms" {
            #   region     = "us-east-1"
            #   kms_key_id = "alias/vault-unseal"
            # }
            #
            # Or use vault's Transit auto-unseal (another vault instance unseals this one):
            # seal "transit" {
            #   address         = "https://vault-primary.example.com"
            #   token           = "<transit-token>"
            #   disable_renewal = "false"
            #   key_name        = "autounseal"
            #   mount_path      = "transit/"
            # }
          '';
        };

        # =========================================================================
        # Persistent data directories
        # =========================================================================
        systemd.tmpfiles.rules = [
          # Vault storage — where encrypted secrets are written to disk
          "d /var/lib/vault/data   0750 root root -"
          # Vault logs directory (optional, for persistent audit logs)
          "d /var/lib/vault/logs   0750 root root -"
          # Vault config (holds our vault.hcl from environment.etc above)
          # Already created by environment.etc, but ensure it exists pre-boot
          "d /etc/vault           0750 root root -"
        ];

        # =========================================================================
        # Vault OCI container
        # =========================================================================
        virtualisation.oci-containers.containers.vault = {

          # -----------------------------------------------------------------------
          # Image
          # -----------------------------------------------------------------------
          # Official HashiCorp image — published at docker.io/hashicorp/vault.
          # Pin to a minor version (e.g. "1.19") for stability.
          # To upgrade: change the tag, rebuild.
          # Release notes: https://developer.hashicorp.com/vault/docs/release-notes
          # -----------------------------------------------------------------------
          image = "hashicorp/vault:1.19";

          # -----------------------------------------------------------------------
          # Port binding
          # -----------------------------------------------------------------------
          # Vault API + UI both on 8200.
          # Bound to localhost only — use `vault` CLI on the host, or access the
          # UI at http://localhost:8200/ui.
          # For remote access, add a Caddy virtualHost (same pattern as n8n).
          # -----------------------------------------------------------------------
          ports = [ "127.0.0.1:8200:8200" ];

          # -----------------------------------------------------------------------
          # Volumes
          # -----------------------------------------------------------------------
          volumes = [
            # Storage: encrypted secrets on disk
            "/var/lib/vault/data:/vault/file"

            # Logs: persistent audit log (optional but recommended for production)
            "/var/lib/vault/logs:/vault/logs"

            # Config: our HCL file from environment.etc above
            # :ro = read-only inside the container — vault should not modify its config
            "/etc/vault:/vault/config:ro"
          ];

          # -----------------------------------------------------------------------
          # Environment variables
          # -----------------------------------------------------------------------
          environment = {
            # VAULT_ADDR: where the vault CLI inside the container finds the server.
            # Set for convenience so `docker exec vault vault status` works without
            # having to pass -address every time.
            VAULT_ADDR = "http://127.0.0.1:8200";

            # VAULT_API_ADDR: same as api_addr in vault.hcl but via env var.
            # Redundant here but explicit is better than implicit.
            VAULT_API_ADDR = "http://127.0.0.1:8200";

            # Skip TLS verification for the vault CLI inside the container.
            # Correct since we disabled TLS on the listener above.
            VAULT_SKIP_VERIFY = "true";
          };

          # -----------------------------------------------------------------------
          # Startup command
          # -----------------------------------------------------------------------
          # Run vault in server mode, not dev mode.
          # The container's entrypoint handles "server" as a subcommand.
          # Configuration is loaded from /vault/config/*.hcl (our bind mount above).
          # -----------------------------------------------------------------------
          cmd = [ "server" ];

          # -----------------------------------------------------------------------
          # Extra Docker options
          # -----------------------------------------------------------------------
          extraOptions = [
            # vault requires IPC_LOCK to prevent sensitive memory pages from being
            # swapped to disk. Without this capability, vault logs a warning and
            # SKIP_SETCAP must be set. On a personal machine, grant it.
            "--cap-add=IPC_LOCK"

            # --restart is intentionally absent here.
            # The NixOS oci-containers module uses --rm on `docker run` so systemd
            # owns the container lifecycle. Docker's --restart and --rm are mutually
            # exclusive. Restart behaviour is declared at the systemd unit level instead.
            #
            #"--restart=unless-stopped"

            # Memory ceiling — vault itself is lean, but give it room for caching
            "--memory=512m"
          ];

          autoStart = true;

        }; # end containers.vault

        # =========================================================================
        # vault CLI on the host (for interacting with the containerized vault)
        # =========================================================================
        # Install the vault CLI as a host binary so you can run `vault` commands
        # from your terminal without exec-ing into the container each time.
        #
        # This is the ONLY place we use pkgs.vault directly. We are NOT running
        # vault's server from the nixpkgs package (which is BSL and unbuilt by
        # Hydra) — we're running it in the container. We're only using the CLI
        # binary here. The CLI itself is a static Go binary; check if the nixpkgs
        # version builds cleanly on your machine, and if not, use the container
        # exec alias below instead.
        # =========================================================================

        # Option A: native CLI from nixpkgs (may require source build — it's Go,
        # ~10 min on your hardware, but clean).
        # environment.systemPackages = [ pkgs.vault ];

        # Option B: shell alias that runs vault CLI inside the container.
        # Zero build cost — uses the binary already in the container image.
        # Add this to your home-manager shell config instead of a system package:
        #
        # programs.bash.shellAliases = {
        #   vault = "docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault vault";
        # };
        #
        # Or in zsh:
        # programs.zsh.shellAliases = {
        #   vault = "docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault vault";
        # };
        #
        # With this alias: typing `vault status` on your host actually runs
        # `docker exec ... vault vault status` inside the container — transparent
        # to your workflow.

      }; # end config
}
