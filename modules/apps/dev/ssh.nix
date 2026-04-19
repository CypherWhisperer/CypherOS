# modules/apps/ssh.nix
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
#   - The public key (~/.ssh/id_ed25519.pub) — same
#   - Known hosts — populated automatically by SSH on first connection
#
# KEY GENERATION (one-time manual step after first home-manager switch):
#
#   ssh-keygen -t ed25519 -C "cypherwhisperer@gmail.com" -f ~/.ssh/id_ed25519
#
#   Then add the public key to:
#     GitHub:  https://github.com/settings/keys
#     GitLab:  https://gitlab.com/-/profile/keys
#
#   Both services can share the same public key — no separate keys needed.
#   Keychain (configured in zsh.nix) manages the agent after this.
#
# VERIFYING THE SETUP:
#   ssh -T git@github.com   → "Hi CypherWhisperer! You've successfully authenticated"
#   ssh -T git@gitlab.com   → "Welcome, CypherWhisperer!"

{ config, pkgs, lib, ... }:

{
  options.cypher-os.apps.dev.ssh.enable = lib.mkEnableOption "Enable SSH client configuration";

  config = lib.mkIf config.cypher-os.apps.dev.ssh.enable ) {

    programs.ssh = {
      enable = true;

      # Disable the implicit default config block that HM previously generated.
      # All defaults are now explicit in the "*" catch-all matchBlock below,
      # giving full visibility and control over what goes into ~/.ssh/config.
      enableDefaultConfig = false;

      # ── Host Blocks ───────────────────────────────────────────────────────────
      matchBlocks = {

        "github.com" = {
          hostname     = "github.com";
          user         = "git";
          identityFile = "~/.ssh/id_ed25519";
          # StrictHostKeyChecking = accept-new: accepts unknown host keys on first
          # connect but warns if a known key changes (MITM indicator).
          # Remove or change to "yes" once you've connected and the key is cached.
          extraOptions = {
            StrictHostKeyChecking = "accept-new";
          };
        };

        "gitlab.com" = {
          hostname     = "gitlab.com";
          user         = "git";
          identityFile = "~/.ssh/id_ed25519";
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

          extraOptions = {
            # Prefer stronger key exchange and host key algorithms
            KexAlgorithms     = "curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512";
            HostKeyAlgorithms = "ssh-ed25519,rsa-sha2-512,rsa-sha2-256";

            # Don't forward X11 or agent by default (override per host if needed)
            ForwardX11    = "no";
            ForwardAgent  = "no";
          };
        };
      };
    };
  };
}
