# modules/devops/containers.nix
#
# Docker and Podman solve the same problem differently.
# Docker uses a root daemon;, Podman is daemonless and rootless by default.
# In practice:
#  - Docker: better Compose ecosystem, more tutorials, most CI/CD defaults
#  - Podman: better security posture, OCI-native, systemd integration
# With both, you can experience the tradeoffs and choose per-project.
# podman's dockerCompat shim means `docker` commands transparently route to
# Podman when Docker daemon isn't running; you can test both with the same muscle memory.

{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.containers.enable) {
    # ─────────────────────────────────────────────────────────────────────────────
    # DOCKER
    # ─────────────────────────────────────────────────────────────────────────────
    # rootless: disabled here (default). Consult documentation for more info.
    # To Enable: virtualisation.docker.rootless.enable = true;
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true; # start the Docker daemon at boot.

      # daemon.settings: docker daemon JSON config (equivalent to /etc/docker/daemon.json).
      # Sane defaults — tune as needed.
      daemon.settings = {
        # journald integrates with `journalctl -u docker`; preferred over json-file on NixOS.
        "log-driver" = "journald";

        # Prune dangling images automatically. Not a daemon setting — do this
        # with a systemd timer or `docker system prune` manually.
      };
    };

    # add user (e.g cypher-whisperer) to run commands without sudo.
    users.users.cypher-whisperer.extraGroups = [
      "docker"
      "podman"
    ];

    # ─────────────────────────────────────────────────────────────────────────────
    # PODMAN
    # ─────────────────────────────────────────────────────────────────────────────
    virtualisation.podman = {
      enable = true;

      # dockerCompat: installs a `docker` → podman symlink so `docker` commands work
      # when the Docker daemon is not running. Disabled here because Docker is enabled
      # above; having both active creates ambiguity — the Docker socket wins by PATH
      # ordering, but the symlink still adds noise. Enable this and disable
      # virtualisation.docker if you decide to go Podman-only.
      dockerCompat = false;

      defaultNetwork.settings.dns_enabled = true;

      autoPrune = {
        enable = true;
        dates = "weekly"; # how often to prune. systemd calendar format: every Sunday at midnight.
        flags = [ "--all" ];
      };
    };

    environment.systemPackages = with pkgs; [

      # ── Docker ────────────────────────────────────────────────────────────────
      docker-client # CLI only — the daemon itself is an OS-level concern
      docker-compose # Manages multi-container apps defined in docker-compose.yml.(Docker + Podman)
      docker-compose-language-service # LSP server for docker-compose.yml files
      lazydocker # TUI dashboard for Docker containers

      # ── Podman ────────────────────────────────────────────────────────────────
      podman-compose # Drop-in for docker-compose when working rootlessly.
      podman-tui # TUI equivalent of lazydocker for Podman
      podman-desktop # Electron GUI; open-source Docker Desktop alternative
      pods # GNOME-native Podman GUI; integrates better with this DE

      # ── Image tooling ─────────────────────────────────────────────────────────
      skopeo # inspect/copy images across registries without pulling to disk
      buildah # build OCI images without a daemon; Podman-native `docker build` replacement
      dive # interactive layer explorer; essential for understanding image bloat
      trivy # CVE scanner for images, filesystems, and IaC
      cosign # Sigstore keyless image signing; supply-chain hygiene

      # ── DEFERRED ──────────────────────────────────────────────────────────────
      # wagoodman/whaler  # not in nixpkgs; similar to dive — revisit if packaged
    ];

  };
}
