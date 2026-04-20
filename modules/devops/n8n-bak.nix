# =============================================================================
# CypherOS — DevOps :: n8n Workflow Automation
# =============================================================================
# modules/cypher-os/devops/n8n.nix
#
# n8n is a self-hostable, fair-code licensed workflow automation platform.
# Think of it as a visual programming environment for connecting APIs,
# services, and databases together — similar to Zapier or Make, but running
# entirely on your own infrastructure with full data ownership.
#
# Official docs : https://docs.n8n.io/hosting/
# Env var ref   : https://docs.n8n.io/hosting/configuration/environment-variables/
#
# IMPORTANT — settings vs environment:
#   An older version of the NixOS module used `services.n8n.settings`.
#   That option has been REMOVED. All configuration now goes through
#   `services.n8n.environment` as plain environment variable strings.
#   Variables ending in `_FILE` are handled specially — see the secrets
#   section below.
# =============================================================================

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.n8n.enable) {

    # =========================================================================
    # Core service declaration
    # =========================================================================
    # `services.n8n` is the upstream NixOS module (nixos/modules/services/misc/n8n.nix).
    # It creates a hardened systemd unit running as a DynamicUser (ephemeral
    # system user with no fixed UID, cannot write outside StateDirectory).
    # Data lives in /var/lib/n8n by default.
    # =========================================================================
    services.n8n = {

      enable = true;

      # -----------------------------------------------------------------------
      # Package
      # -----------------------------------------------------------------------
      # The default is `pkgs.n8n` from nixpkgs — the same one that was causing
      # your OOM crash when listed in home.packages (because it built from
      # source in the sandbox). The service module ships a pre-built binary,
      # so that crash no longer applies here.
      #
      # Override only if you need a specific version pinned via an overlay, e.g.:
      #   package = pkgs.n8n_0_235;
      # -----------------------------------------------------------------------
      package = pkgs.n8n;

      # -----------------------------------------------------------------------
      # Firewall
      # -----------------------------------------------------------------------
      # `false` = n8n is only reachable on localhost (127.0.0.1:5678).
      # This is the right default when you plan to put a reverse proxy
      # (Caddy, nginx, Traefik) in front of n8n, which you should do for
      # any production or LAN-exposed setup.
      #
      # Set to `true` only for quick local-network testing when you want to
      # hit n8n directly from another machine without a proxy.
      # -----------------------------------------------------------------------
      openFirewall = false;

      # -----------------------------------------------------------------------
      # Custom community nodes
      # -----------------------------------------------------------------------
      # n8n has an ecosystem of community-built node packages. On NixOS these
      # must be declared here (not installed at runtime via the UI) because the
      # Nix store is immutable. Each entry must be a Nix package that ships
      # its node modules under `lib/node_modules/<pname>/`.
      #
      # Example (once such packages exist in nixpkgs or your own overlay):
      #   customNodes = with pkgs; [
      #     n8n-nodes-carbonejs   # Carbon.js node
      #     n8n-nodes-imap        # IMAP email node
      #   ];
      #
      # Note: Community node packaging in nixpkgs is still maturing (tracked in
      # https://github.com/NixOS/nixpkgs/issues/435198). For now, leave empty.
      # -----------------------------------------------------------------------
      customNodes = [ ];

      # -----------------------------------------------------------------------
      # Environment variables
      # -----------------------------------------------------------------------
      # This attrset maps directly to systemd environment variables passed to
      # the n8n process. All n8n configuration happens here.
      #
      # SECRETS PATTERN — variables ending in `_FILE`:
      #   Any key that ends with `_FILE` is treated specially by the module:
      #   the value is the path to a file containing the secret, and the module
      #   loads it via systemd LoadCredential so the plaintext never appears in
      #   /proc/<pid>/environ. Use agenix or sops-nix to manage those files.
      #   Example:
      #     N8N_ENCRYPTION_KEY_FILE = "/run/secrets/n8n-encryption-key";
      # -----------------------------------------------------------------------
      environment = {

        # =====================================================================
        # NETWORKING
        # =====================================================================

        # The port n8n's HTTP server binds to.
        # If you change this, also update your reverse proxy upstream and
        # openFirewall (if used). Default: 5678.
        N8N_PORT = "5678";

        # The listen address. "127.0.0.1" = localhost only (recommended behind
        # a reverse proxy). "0.0.0.0" = all interfaces (only if openFirewall
        # and direct access are intentional).
        N8N_LISTEN_ADDRESS = "127.0.0.1";

        # The public-facing URL n8n uses to build webhook URLs. Without this,
        # webhook URLs will contain the internal 127.0.0.1 address which is
        # useless for external triggers. Set this to whatever URL your reverse
        # proxy exposes to the internet (or your LAN).
        # Example: "https://n8n.pentara.tech/"
        WEBHOOK_URL = "http://localhost:5678/";

        # Protocol for the n8n editor URL. "http" is fine behind a TLS-
        # terminating reverse proxy; change to "https" only if n8n itself is
        # terminating TLS (unusual).
        N8N_PROTOCOL = "http";

        # =====================================================================
        # TIMEZONE
        # =====================================================================
        # Used by the Schedule/Cron trigger node to interpret times correctly.
        # The module defaults this to `config.time.timeZone` (your NixOS system
        # timezone), so you usually don't need to set it explicitly. Override
        # if n8n should run in a different timezone than your system.
        # GENERIC_TIMEZONE = "Africa/Nairobi";

        # =====================================================================
        # DATABASE
        # =====================================================================
        # n8n defaults to SQLite at /var/lib/n8n/database.sqlite — perfectly
        # fine for personal use and small teams. Upgrade to PostgreSQL when:
        #   - You need concurrent workflow executions at scale
        #   - You want proper backups with pg_dump
        #   - You're running n8n in a team/production context
        #
        # To switch to PostgreSQL, uncomment and fill in the block below, then
        # also declare a `services.postgresql` service in your NixOS config.
        # -----------------------------------------------------------------------
        # DB_TYPE = "postgresdb";
        # DB_POSTGRESDB_HOST = "localhost";
        # DB_POSTGRESDB_PORT = "5432";
        # DB_POSTGRESDB_DATABASE = "n8n";
        # DB_POSTGRESDB_USER = "n8n";
        # DB_POSTGRESDB_PASSWORD_FILE = "/run/secrets/n8n-db-password";
        #   ↑ Use _FILE suffix so the password is loaded via systemd credential,
        #     never stored in the Nix store or /proc/<pid>/environ.

        # =====================================================================
        # SECURITY & ENCRYPTION
        # =====================================================================

        # The encryption key protects stored credentials (API keys, passwords,
        # OAuth tokens) at rest in the database. If you lose this key, all
        # stored credentials become unreadable and must be re-entered.
        #
        # CRITICAL: Set this to a file containing a strong random key BEFORE
        # first launch. Generate one with:
        #   openssl rand -hex 32 > /path/to/n8n-encryption-key
        #   chmod 600 /path/to/n8n-encryption-key
        #
        # Then manage the file with agenix or sops-nix and point here:
        # N8N_ENCRYPTION_KEY_FILE = "/run/secrets/n8n-encryption-key";
        #
        # If you don't set this, n8n generates a random key on first start and
        # stores it in /var/lib/n8n/.n8n/config. That's okay for local dev but
        # risky in production (the key is stored alongside the database).

        # =====================================================================
        # TELEMETRY & NOTIFICATIONS
        # =====================================================================

        # Disable anonymous usage telemetry sent to n8n GmbH. Respects your
        # privacy. The only downside: "Ask AI" in the Code node requires this
        # to be enabled (it's routed through n8n's own backend).
        N8N_DIAGNOSTICS_ENABLED = "false";

        # Disable n8n phoning home to check for new versions. Manage upgrades
        # yourself through nixpkgs updates instead.
        N8N_VERSION_NOTIFICATIONS_ENABLED = "false";

        # Disable the "Templates" feature that fetches workflow templates from
        # n8n's cloud. Keeps the instance fully self-contained.
        # N8N_TEMPLATES_ENABLED = "false";

        # =====================================================================
        # USER MANAGEMENT & AUTHENTICATION
        # =====================================================================
        # By default, n8n's first-run wizard creates an owner account.
        # For a single-user instance that's sufficient. For team setups:

        # Basic auth (simple, not recommended for production):
        # N8N_BASIC_AUTH_ACTIVE = "true";
        # N8N_BASIC_AUTH_USER = "admin";
        # N8N_BASIC_AUTH_PASSWORD_FILE = "/run/secrets/n8n-basic-auth-password";

        # JWT auth (better for API access):
        # N8N_JWT_AUTH_ACTIVE = "true";
        # N8N_JWT_AUTH_HEADER = "Authorization";
        # N8N_JWT_AUTH_HEADER_VALUE_PREFIX = "Bearer ";
        # N8N_JWT_SECRET_FILE = "/run/secrets/n8n-jwt-secret";

        # SAML / LDAP / OIDC are enterprise features requiring an n8n license.

        # =====================================================================
        # EMAIL (SMTP)
        # =====================================================================
        # n8n sends emails for: password reset, user invitations, workflow
        # error notifications. Without SMTP, these features silently fail.
        # Configure with your SMTP provider (Resend, Postmark, Gmail, etc.)

        # N8N_EMAIL_MODE = "smtp";
        # N8N_SMTP_HOST = "smtp.resend.com";        # Your SMTP host
        # N8N_SMTP_PORT = "587";                    # 587 = STARTTLS, 465 = SSL
        # N8N_SMTP_USER = "resend";                 # SMTP username
        # N8N_SMTP_PASS_FILE = "/run/secrets/n8n-smtp-pass";
        # N8N_SMTP_SENDER = "n8n@pentara.tech";     # From address
        # N8N_SMTP_SSL = "false";                   # true if port 465

        # =====================================================================
        # EXECUTION & PERFORMANCE
        # =====================================================================

        # How many workflow executions to save in the database.
        # Higher = more history but larger DB. Default: 200.
        # EXECUTIONS_DATA_MAX_AGE = "720";       # hours to keep (30 days)
        # EXECUTIONS_DATA_PRUNE = "true";        # enable auto-pruning

        # Max concurrent workflow executions. Default: not limited.
        # On a small VM/single-core box, cap this to avoid overload.
        # EXECUTIONS_PROCESS = "main";           # "main" or "own" process
        # N8N_DEFAULT_CONCURRENCY = "10";

        # =====================================================================
        # LOGGING
        # =====================================================================
        # Log level: error | warn | info | verbose | debug
        # Start with "info". Switch to "debug" when troubleshooting a workflow.
        N8N_LOG_LEVEL = "info";

        # Log output: "console" logs to journald (visible via `journalctl -u n8n`).
        # "file" writes to a file; add N8N_LOG_FILE_LOCATION if using "file".
        N8N_LOG_OUTPUT = "console";

        # =====================================================================
        # EDITOR & UI
        # =====================================================================

        # The hostname the editor uses to construct its own URLs internally.
        # Usually not needed when WEBHOOK_URL is set correctly.
        # N8N_HOST = "localhost";

        # Disable the "Community nodes" install tab in the UI (since on NixOS
        # you manage them declaratively via `customNodes` above anyway).
        # N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "false";

      }; # end environment

      # -----------------------------------------------------------------------
      # Task Runners (sandboxed Code node execution)
      # -----------------------------------------------------------------------
      # n8n's Code node (JavaScript/Python) can execute in two modes:
      #
      #   internal (default): code runs directly in the n8n process. Simple
      #     but risky — a malicious or buggy script can affect the whole service.
      #
      #   external (task runners): code runs in isolated child processes managed
      #     by the n8n-task-runner-launcher. Better security isolation.
      #     Requires setting N8N_RUNNERS_AUTH_TOKEN_FILE.
      #
      # For a personal/dev setup, the default (internal, runners disabled) is
      # fine. Enable task runners when you're running untrusted workflows or
      # want stronger isolation guarantees.
      # -----------------------------------------------------------------------
      taskRunners = {

        # Set to `true` to enable external task runner sandboxing.
        # When enabled you MUST also set:
        #   services.n8n.environment.N8N_RUNNERS_AUTH_TOKEN_FILE
        enable = false;

        # When taskRunners.enable = true, you can tune individual runners here.
        # The module pre-configures javascript and python runners with sensible
        # defaults. Override only what you need:
        #
        # runners = {
        #   javascript = {
        #     enable = true;
        #     # command and healthCheckPort have working defaults — omit unless
        #     # you need a custom binary path.
        #     healthCheckPort = 5681;
        #   };
        #   python = {
        #     # Disable Python runner if you don't use Python in Code nodes.
        #     enable = false;
        #   };
        # };

        # Environment variables passed to ALL task runner processes.
        # environment = {
        #   N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT = "15";   # seconds of idle before runner exits
        #   N8N_RUNNERS_MAX_CONCURRENCY = "5";          # max parallel tasks per runner
        # };

      }; # end taskRunners

    }; # end services.n8n

    # =========================================================================
    # Reverse proxy (Caddy)
    # =========================================================================
    # This is commented out but structured for when you're ready to expose n8n
    # over HTTPS. Caddy is the recommended choice for a Pentara/CypherOS stack
    # because it handles TLS certificates automatically via ACME/Let's Encrypt.
    #
    # Uncomment and adapt when you have a domain pointing to this machine.
    # Also set WEBHOOK_URL above to "https://n8n.yourdomain.com/".
    # -------------------------------------------------------------------------
    # services.caddy = {
    #   enable = true;
    #   virtualHosts."n8n.yourdomain.com" = {
    #     extraConfig = ''
    #       reverse_proxy localhost:5678
    #     '';
    #   };
    # };

    # =========================================================================
    # PostgreSQL (optional — for production database backend)
    # =========================================================================
    # If you switch DB_TYPE to "postgresdb" above, you need a local PostgreSQL
    # instance. Uncomment this block and run:
    #   sudo -u postgres createuser --pwprompt n8n
    #   sudo -u postgres createdb --owner=n8n n8n
    # -------------------------------------------------------------------------
    # services.postgresql = {
    #   enable = true;
    #   ensureDatabases = [ "n8n" ];
    #   ensureUsers = [{
    #     name = "n8n";
    #     ensureDBOwnership = true;
    #   }];
    # };

    # =========================================================================
    # Backup considerations (informational — not configuration)
    # =========================================================================
    # What to back up for a full n8n restore:
    #
    #   SQLite:     /var/lib/n8n/database.sqlite
    #               /var/lib/n8n/.n8n/config  ← contains encryption key if not
    #                                           managed externally
    #   PostgreSQL: pg_dump n8n > n8n_backup.sql
    #   Secrets:    whatever manages your _FILE secrets (agenix repo, sops age key)
    #   Export:     n8n also has a built-in "Export all workflows" in the UI.
    #               Do this periodically — it produces a portable JSON you can
    #               import into any n8n instance.
    # =========================================================================

  }; # end config
}
