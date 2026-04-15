# modules/devops/containers.nix
#
# NixOS module for container tooling: Docker + Podman stacks, image
# inspection, security scanning, and signing.
#
# WHAT THIS FILE OWNS:
#   - Docker daemon (virtualisation.docker) — extracted from configuration.nix
#   - Podman daemon (virtualisation.podman) with Docker compatibility shim
#   - All container-adjacent CLI tools and GUIs
#   - The `docker` and `podman` extraGroups entries for cypher-whisperer
#
# WHAT THIS FILE DOES NOT OWN:
#   - Container images themselves — those are ephemeral, never declared in Nix
#   - Compose project files — those live in each project's repo
#   - The user account declaration — that stays in configuration.nix
#     (this module adds to extraGroups via users.users.<name>.extraGroups
#      using lib.mkAfter to avoid clobbering the base declaration)
#
# WHY DOCKER AND PODMAN TOGETHER:
#   They solve the same problem differently. Docker uses a root daemon;
#   Podman is daemonless and rootless by default. In practice:
#     - Docker: better Compose ecosystem, more tutorials, most CI/CD defaults
#     - Podman: better security posture, OCI-native, systemd integration
#   Having both at the learning stage lets you experience the tradeoffs
#   firsthand and choose per-project later. podman's dockerCompat shim
#   means `docker` commands transparently route to Podman when Docker
#   daemon isn't running — you can test both with the same muscle memory.
#
# ENABLE:
#   devops.containers.enable = true;  in your host configuration.nix
#
# FIRST-TIME SETUP (after nixos-rebuild switch):
#   Podman rootless — no extra steps needed; works out of the box.
#   Docker socket — if you want Docker daemon (not just Podman compat):
#     systemctl start docker   (or enable it via virtualisation.docker.rootless)
#
# VERIFYING THE SETUP:
#   docker run --rm hello-world
#   podman run --rm hello-world
#   docker compose version
#   podman-compose --version
#   dive --version
#   trivy --version

{ config, pkgs, lib, ... }:

{
  # ── Module Option ────────────────────────────────────────────────────────────
  options.devops.containers.enable = lib.mkEnableOption
    "container tooling (Docker, Podman, image inspection, scanning)";

  config = lib.mkIf config.devops.containers.enable {
    # ─────────────────────────────────────────────────────────────────────────────
    # DOCKER
    # ─────────────────────────────────────────────────────────────────────────────
    # Docker daemon runs at the system level. The docker-client CLI is installed
    # by Home Manager. The daemon in configuration.nix or in a module imported there
    # extraGroups adds a user (e.g cypher-whisperer) to the docker group so they can run
    # docker commands without sudo.
    #
    # ── Docker Daemon ──────────────────────────────────────────────────────────
    # The daemon runs as root and exposes a
    # socket at /var/run/docker.sock. CLI tools (docker, docker-compose) talk
    # to this socket — the daemon must be here at system level.
    #
    # rootless: disabled here (default). Rootless Docker runs the daemon as the
    # user rather than root, which is more secure but has limitations (no
    # automatic port binding below 1024, some network modes unavailable).
    # Enable it later once you've evaluated whether its constraints suit your
    # workflow: virtualisation.docker.rootless.enable = true;
    virtualisation.docker = {
      enable = true;

      # enableOnBoot: start the Docker daemon at boot. Set to false if you
      # prefer to start it manually (saves resources on machines where you
      # don't always need it).
      enableOnBoot = true;

      # daemon.settings: docker daemon JSON config (equivalent to /etc/docker/daemon.json).
      # These are sane defaults — tune as needed.
      daemon.settings = {
        # log-driver: json-file is the default. Alternatives: journald (integrates
        # with `journalctl`), local (better compression). journald is recommended
        # for NixOS since you're already using systemd.
        "log-driver" = "journald";

        # Prune dangling images automatically. Not a daemon setting — do this
        # with a systemd timer or `docker system prune` manually.
      };
    };

    # ── Podman Daemon ──────────────────────────────────────────────────────────
    # Daemonless by default — each `podman` invocation forks its own process.
    # The virtualisation.podman module sets up the socket-activated service for
    # tools that expect a Docker-style socket (like some GUIs).
    virtualisation.podman = {
      enable = true;

      # dockerCompat: installs a `docker` symlink pointing at podman. This means
      # typing `docker` when the Docker daemon isn't running transparently uses
      # Podman. When Docker IS running, Docker wins (PATH ordering).
      # Set to false if you find the ambiguity confusing; you can always type
      # `podman` explicitly.
      dockerCompat = true;

      # defaultNetwork.settings.dns_enabled: enables DNS resolution between
      # containers in the default network. Without this, containers can't
      # resolve each other by name — you'd have to use IPs.
      defaultNetwork.settings.dns_enabled = true;

      # autoPrune: automatically remove unused containers, images, and volumes.
      # Keeps disk usage in check. Runs on a systemd timer.
      autoPrune = {
        enable = true;
        # dates: how often to prune. systemd calendar format.
        # "weekly" = every Sunday at midnight.
        dates = "weekly";
        # flags: passed to `podman system prune`. --all removes all unused
        # images (not just dangling ones). Remove --all if you want to keep
        # tagged images that aren't currently running.
        flags = [ "--all" ];
      };
    };

    # ── System Packages ────────────────────────────────────────────────────────
    environment.systemPackages = with pkgs; [

      docker-client # CLI only — the daemon itself is an OS-level concern
      # ── Docker Compose Stack ─────────────────────────────────────────────────
      # docker-compose: the v2 plugin / standalone binary. Manages multi-container
      # apps defined in docker-compose.yml. Works with both Docker and Podman.
      docker-compose

      # docker-compose-language-service: LSP server for docker-compose.yml files.
      # Gives completion, validation, and hover docs in Neovim/VSCode.
      # Requires your editor's LSP config to register it — no auto-start.
      docker-compose-language-service

      # lazydocker: TUI dashboard for Docker. Shows containers, images, volumes,
      # logs, stats in one terminal interface. Run with: lazydocker
      lazydocker

      # ── Podman Stack ─────────────────────────────────────────────────────────
      # podman-compose: Compose file support for Podman. Drop-in for docker-compose
      # when working rootlessly. Some edge-case Compose features differ.
      podman-compose

      # podman-tui: Terminal UI for Podman. Like lazydocker but Podman-native.
      # Shows pods, containers, images, volumes. Run with: podman-tui
      podman-tui

      # podman-desktop: Electron GUI for Podman (and Docker). Good for visual
      # inspection, pulling images, managing registries. Like Docker Desktop
      # but open source.
      podman-desktop

      # pods: GNOME-native GUI for Podman. Integrates with GNOME's look and feel
      # better than podman-desktop on this DE. Good for day-to-day container
      # management without leaving the GNOME workflow.
      pods

      # ── Image Tooling ─────────────────────────────────────────────────────────
      # skopeo: inspect and copy container images across registries WITHOUT
      # pulling them to disk. Useful for:
      #   - Checking image manifests before pulling
      #   - Copying images between registries (e.g. Docker Hub → private registry)
      #   - Inspecting image metadata offline
      # Usage: skopeo inspect docker://nginx:latest
      skopeo

      # buildah: build OCI-compliant images without a Docker daemon. The
      # Podman-native alternative to `docker build`. Supports Dockerfile syntax
      # and a native buildah scripting API. Better for rootless and CI environments.
      # Usage: buildah bud -t myimage .
      buildah

      # dive: inspect Docker/OCI image layers interactively. Shows exactly which
      # files each layer adds/modifies. Essential for understanding why an image
      # is large and how to optimize it. Great learning tool.
      # Usage: dive <image-name>
      dive

      # trivy: vulnerability scanner for container images, filesystems, and IaC.
      # Scans for known CVEs in OS packages and language dependencies.
      # Run before pushing any image to a registry.
      # Usage: trivy image nginx:latest
      trivy

      # cosign: sign and verify container images using Sigstore's keyless signing.
      # Becoming the standard for supply chain security. Good habit to build
      # early even if you're only signing your own images for now.
      # Usage: cosign sign <image-digest>
      cosign
    ];

  };
}
