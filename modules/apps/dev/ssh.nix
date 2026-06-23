# modules/apps/dev/ssh.nix
#
# Home Manager module for SSH client configuration.
#
# WHAT THIS FILE OWNS:
#   - ~/.ssh/config (via programs.ssh)
#   - Host blocks for GitHub and GitLab sharing one ed25519 key
#   - Sensible SSH client defaults
#
# WHAT THIS FILE DOES NOT OWN:
#   - The private key itself (~/.ssh/id_ed25519) — generated once manually,
#     never declared in Nix, never in the repo
#
#   - The public key (~/.ssh/id_ed25519.pub) — same
#   - Known hosts — populated automatically by SSH on first connection
#
# KEY GENERATION (one-time manual step per identity):
#
#   ssh-keygen -t ed25519 -C "cypherwhisperer@gmail.com"      -f ~/.ssh/id_ed25519_cypher
#   ssh-keygen -t ed25519 -C "pentaratechsolutions@gmail.com" -f ~/.ssh/id_ed25519_pentara
#
#   Add each public key to the corresponding GitHub account:
#     CypherWhisperer:       https://github.com/settings/keys
#     PentaraTechSolutions:  https://github.com/settings/keys  (logged in as that account)
#
#   Both services (GitLab and GitHub) can share the same public key — no separate keys needed.
#   Keychain (configured in zsh.nix) manages the agent after this.
#
#
# MULTI-ACCOUNT GIT WORKFLOW:
#   Clone using the alias host, not bare github.com:
#
#     git clone git@github.com-cypher:CypherWhisperer/project.git
#     git clone git@github.com-pentara:PentaraTechSolutions/project.git
#
#   For existing remotes:
#     git remote set-url origin git@github.com-cypher:CypherWhisperer/project.git
#
#   The alias host tells SSH which IdentityFile to use — both resolve to
#   github.com at the network level, but authenticate as different accounts.
#
# VERIFYING THE SETUP:
#   ssh -T git@github.com-cypher   → "Hi CypherWhisperer! You've successfully authenticated"
#   ssh -T git@github.com-pentara  → "Hi PentaraTechSolutions! You've successfully authenticated"
#   ssh -T git@gitlab.com          → "Welcome, CypherWhisperer!"
#
# ADDING MORE IDENTITIES:
#   1. Generate a new key:  ssh-keygen -t ed25519 -C "label" -f ~/.ssh/id_ed25519_<name>
#   2. Add a matchBlock below following the github-<name> pattern
#   3. Add the public key to the relevant service
#   4. home-manager switch

{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.apps.dev.enable && config.cypher-os.apps.dev.ssh.enable) {

    programs.ssh = {
      enable = true;

      # Disable the implicit default config block that HM previously generated.
      # All defaults are now explicit in the "*" catch-all matchBlock below,
      # giving full visibility and control over what goes into ~/.ssh/config.
      enableDefaultConfig = false;

      # ── Host Blocks ───────────────────────────────────────────────────────────
      matchBlocks = {

        # ── GitHub: CypherWhisperer (primary dev account) ───────────────────────
        "github.com-cypher" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519_cypher";
          # StrictHostKeyChecking = accept-new: accepts unknown host keys on first
          # connect but warns if a known key changes (MITM indicator).
          # Remove or change to "yes" once you've connected and the key is cached.
          extraOptions = {
            StrictHostKeyChecking = "accept-new";
          };
        };

        # ── GitHub: PentaraTechSolutions (org account) ──────────────────────────
        "github.com-pentara" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519_pentara";
          extraOptions = {
            StrictHostKeyChecking = "accept-new";
          };
        };

        # ── GitLab: CypherWhisperer ───────────────────────────────────────────
        "gitlab.com-cypher" = {
          hostname = "gitlab.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519_cypher";
          extraOptions = {
            StrictHostKeyChecking = "accept-new";
          };
        };

        # ── Catch-all Default ─────────────────────────────────────────────────
        # Applied to any host not matched by the blocks above.
        # Global defaults (previously top-level programs.ssh options) now live
        # here per the HM deprecation — matchBlocks."*" is the correct location.
        "*" = {
          # AddKeysToAgent: automatically add keys to the running ssh-agent when
          # first used. Keychain starts the agent; this feeds it without a manual
          # ssh-add call beyond what keychain already does.
          addKeysToAgent = "yes";

          # ServerAliveInterval / ServerAliveCountMax: send keepalive packets to
          # prevent idle connections from being dropped by firewalls or NAT routers.
          # 60s interval × 3 max = drops connection after 3 minutes of no response.
          serverAliveInterval = 60;
          serverAliveCountMax = 3;

          # Prefer stronger key exchange and host key algorithms
          kexAlgorithms = [
            "curve25519-sha256"
            "curve25519-sha256@libssh.org"
            "diffie-hellman-group16-sha512"
            "diffie-hellman-group18-sha512"
          ];

          # Don't forward X11 or agent by default (override per host if needed)
          forwardX11 = false;
          forwardAgent = false;

          # HostKeyAlgorithms has no native field — leave in extraOptions:
          extraOptions = {
            HostKeyAlgorithms = "ssh-ed25519,rsa-sha2-512,rsa-sha2-256";
          };
        };
      };
    };
  };
}
