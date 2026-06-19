# flake.nix
#
# Entry point for the cypher-system configuration flake.
#
# A Nix flake is a self-contained, reproducible unit of Nix code with:
#   - inputs:  the external dependencies (nixpkgs version, home-manager version)
#   - outputs: what this flake produces (NixOS systems, Home Manager configs)
#
# The flake.lock file (auto-generated, committed to git) pins the exact
# revision of every input. This is what makes the config reproducible —
# running `nixos-rebuild switch` six months from now uses the same nixpkgs
# unless you explicitly run `nix flake update`.
#
# To add a new OS host: add a nixosConfigurations entry.
# To add a new HM-only host: add a homeConfigurations entry.

{
  description = "CypherOS unified multi-OS configuration flake";

  # ─────────────────────────────────────────────────────────────────────────────
  # INPUTS
  # ─────────────────────────────────────────────────────────────────────────────
  # inputs are the external flakes this flake depends on.
  # nixpkgs: the Nix package collection. nixos-24.11 is the stable channel.
  #   Switch to "nixos-unstable" for rolling/latest packages if preferred.
  # home-manager: follows nixpkgs exactly (same revision) to avoid version skew.
  #   "follows" is a flake mechanism that says "use the same nixpkgs input
  #   as the parent flake, don't fetch your own copy."
  inputs = {
    # ─────────────────────────────────────────────────────────────────────────────
    # STABLE CHANNEL
    # ─────────────────────────────────────────────────────────────────────────────
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # ─────────────────────────────────────────────────────────────────────────────
    # UNSTABLE CHANNEL
    # ─────────────────────────────────────────────────────────────────────────────
    # Instead of: nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # You pin to a specific commit where Hydra completed cleanly.
    #
    # To find a good commit:
    #   1. Go to https://hydra.nixos.org/jobset/nixos/unstable/evals
    #   2. Find the latest evaluation where the "tested" column shows ✔
    #      (meaning ALL required test jobs passed)
    #   3. Click it → note the nixpkgs commit hash
    #   4. Paste it here
    #
    # Update periodically (weekly or when you need a new package version):
    #   nix flake update
    # But only update when you've verified Hydra has finished that commit.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      #url = "github:nix-community/home-manager/release-24.11";
      #url = "https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz";
      url = "github:nix-community/home-manager/master"; # for the unstable channel
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Desktop Linux port.
    # inputs.nixpkgs.follows deduplicates — HM, claude-desktop, and our system
    # all evaluate against the same nixpkgs revision. Without this, Nix would
    # fetch and evaluate a second (possibly different) nixpkgs for claude-desktop.
    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs"; # deduplicate — use our nixpkgs, not theirs
    };

    # nix-community/nix-vscode-extensions
    # Provides a declarative attrset of virtually every extension on the VS Code
    # Marketplace and Open VSX registry, with pre-computed hashes.
    # This is the escape hatch for extensions not packaged in nixpkgs — no manual
    # sha256 hunting, no hash-mismatch failures at build time.
    # Update all extension hashes in one shot with: nix flake update nix-vscode-extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      # Deduplicate — use our nixpkgs revision, not the one nix-vscode-extensions
      # would pull independently. Same reason as claude-desktop above.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin/nix — provides a Home Manager module for declarative Catppuccin
    # theming across many applications, including a VSCode extension that
    # pre-compiles the theme at build time (bypassing the read-only store problem
    # that breaks the nixpkgs catppuccin-vsc extension).
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs"; # deduplicate — same reason as all others
    };

    nur = {
      url = "github:nix-community/NUR";
    }
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # OUTPUTS
  # ─────────────────────────────────────────────────────────────────────────────
  # outputs is a function that receives the resolved inputs and returns
  # an attribute set of everything this flake produces.

  # CLAUDE RELATED COMMENT BLOCK
  # The @ binding captures ALL inputs into a single attribute set called `inputs`.
  # We need the `inputs` name so we can pass it through specialArgs into
  # NixOS modules (configuration.nix uses `inputs.claude-desktop.overlays.default`).
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      claude-desktop,
      nix-vscode-extensions,
      catppuccin,
      devenv,
      nur,
      ...
    }@inputs:
    let
      # system: the CPU architecture + OS pair Nix uses to select packages.
      # x86_64-linux covers standard 64-bit Intel/AMD Linux machines.
      # If you ever add an ARM machine, you'd add "aarch64-linux" entries.
      system = "x86_64-linux";

      # CLAUDE RELATED COMMENT BLOCK
      # pkgs is instantiated here for use in standalone homeConfigurations.
      # The NixOS nixosConfigurations path does NOT use this pkgs — NixOS builds
      # its own pkgs internally (with the overlays applied via nixpkgs.overlays
      # in configuration.nix). Using this pkgs in nixosConfigurations would
      # bypass the overlay, which is why homeConfigurations.pkgs and
      # nixosConfigurations.pkgs are intentionally separate.

      # pkgs: the nixpkgs package set for the system, with unfree allowed.
      # Declaring it here means we reference it once rather than repeating
      # the same nixpkgs.legacyPackages.${system} call everywhere.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          # Injects pkgs.nix-vscode-extensions into the package set.
          # After this, any module receiving pkgs can access:
          #   pkgs.nix-vscode-extensions.vscode-marketplace.<publisher>.<name>
          #   pkgs.nix-vscode-extensions.open-vsx.<publisher>.<name>
          # Publisher and extension names must be fully lowercase in Nix attribute
          # paths, even if the marketplace shows mixed case.
          nix-vscode-extensions.overlays.default
          nur.overlays.default
        ];
      };

    in
    {

      # ── NixOS System Configurations ─────────────────────────────────────────
      # nixosConfigurations defines bootable NixOS systems.
      # Each key is the hostname — referenced with --flake .#<hostname>.
      #
      # lib.nixosSystem builds a full NixOS system from the module list.
      # The home-manager NixOS module (homeManagerModules.home-manager) integrates
      # Home Manager directly into `nixos-rebuild switch` — one command applies
      # both the system config and the user config.
      nixosConfigurations = {

        cypher-nixos = nixpkgs.lib.nixosSystem {
          inherit system;

          # CLAUDE RELATED COMMENT BLOCK
          # specialArgs threads the `inputs` attrset into every NixOS
          # module in this configuration. This is the only way to make
          # `inputs.claude-desktop` available inside configuration.nix without
          # importing the flake directly there (which would break modularity).
          # The overlay registration in configuration.nix reads:
          #   nixpkgs.overlays = [ inputs.claude-desktop.overlays.default ];
          specialArgs = { inherit inputs self; };
          # self makes the current flake available in all NixOS modules, including
          # Home Manager modules nested within it.

          modules = [
            # The system-level configuration for this host
            ./hosts/nixos/configuration.nix

            # Integrate Home Manager into NixOS — this makes `nixos-rebuild switch`
            # also apply the Home Manager config. No separate `home-manager switch`
            # command needed when using this integration.
            home-manager.nixosModules.home-manager
            {
              # CLAUDE RELATED COMMENT BLOCK
              # useGlobalPkgs: Home Manager uses the same nixpkgs instance as the
              # system — critically, this means the claude-desktop overlay that was
              # applied via nixpkgs.overlays in configuration.nix is also visible
              # inside Home Manager modules (pkgs.claude-desktop exists in claude.nix).
              # Without this, HM would build its own pkgs without the overlay.

              # useGlobalPkgs: Home Manager uses the same nixpkgs instance as the
              # system. Prevents downloading a second copy of nixpkgs.
              home-manager.useGlobalPkgs = true;

              # useUserPackages: packages declared in home.packages are installed
              # into /etc/profiles/per-user/<user>/ rather than ~/.nix-profile.
              # This makes them available in GDM and system contexts.
              home-manager.useUserPackages = true;

              # Thread inputs into Home Manager modules too, in case any HM module
              # ever needs to reference a flake input directly.
              home-manager.extraSpecialArgs = { inherit inputs self; };

              # The actual Home Manager configuration for cypher-whisperer.
              # This imports gnome.nix which declares all user-space packages,
              # dconf settings, GTK theme, and the XDG launcher script.
              home-manager.users.cypher-whisperer =
                {
                  config,
                  pkgs,
                  lib,
                  ...
                }:
                {
                  imports = [
                    ./modules/home/default.nix
                    inputs.catppuccin.homeModules.catppuccin
                  ];

                  # Identity — must match users.users declaration in configuration.nix
                  home.username = "cypher-whisperer";
                  home.homeDirectory = "/home/cypher-whisperer";

                  # Activate the desktop profile. This cascades all app/DE/DM defaults.
                  # Override any individual option below this line to deviate from the profile.
                  cypher-os.profile.desktop.enable = true;

                  # Example overrides (uncomment to use):
                  # cypher-os.de.gnome.enable    = false;
                  # cypher-os.de.hyprland.enable = true;
                  # cypher-os.apps.gaming.enable = false;
                };

              # This tells HM to rename any conflicting existing files to .hm-bak
              # instead of refusing to proceed.
              home-manager.backupFileExtension = "hm-bak";
            }
          ];
        };

      }; # end nixosConfigurations

      # ── Standalone Home Manager Configurations ────────────────────────────────
      # homeConfigurations are for non-NixOS hosts (Arch, Debian, Fedora).
      # Applied with: home-manager switch --flake .#cypher-whisperer@<host>
      #
      # On these hosts, the OS manages the system level. Home Manager manages
      # only the user environment (packages, dotfiles, dconf settings).
      #
      # The cypher-nixos entry here is a convenience — allows running HM standalone
      # on NixOS too if you prefer that workflow during development.
      homeConfigurations = {
        "cypher-whisperer@cypher-nixos" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          # The standalone Home Manager configurations also need self
          # NOTE: it is `extraSpecialArgs` here, not `specialArgs`.
          extraSpecialArgs = { inherit inputs self; };
          modules = [
            ./modules/home/default.nix

            # inputs.catppuccin.homeModules.catppuccin must be imported here explicitly,
            # mirroring the import in the NixOS-integrated path (flake.nix nixosConfigurations
            # block, under home-manager.users.cypher-whisperer.imports).
            #
            # Why this is necessary:
            # The catppuccin flake input is declared at the top of this flake and passed
            # through outputs, but declaring an input does not automatically make its HM
            # modules available — each Home Manager evaluation context (NixOS-integrated vs
            # standalone homeConfigurations) is an independent module system instantiation.
            # A module imported in one context is invisible to the other unless explicitly
            # re-imported. The NixOS path had it; the standalone path did not.
            #
            # Effect of its absence:
            # Any module in the CypherOS HM tree that references `catppuccin.*` options
            # (currently vscode.nix) causes a hard evaluation failure in the standalone
            # context — "The option `catppuccin' does not exist" — because the option
            # declarations that catppuccin's HM module provides were never loaded.
            # Critically, this failure is silent during normal `nixos-rebuild switch`
            # because that path uses nixosConfigurations, not homeConfigurations. The
            # standalone path was broken without any visible symptom until directly evaluated.
            #
            # Effect of its addition:
            # The standalone homeConfigurations entry now evaluates cleanly and produces
            # a configuration identical to the NixOS-integrated path. Both contexts are
            # now in sync — any catppuccin.* option set in any HM module resolves correctly
            # regardless of which evaluation path is used.
            #
            # Future implications:
            # This is a pattern to internalize: every flake input that contributes HM
            # modules (catppuccin, nix-vscode-extensions via overlays, any future HM
            # module flake) must be explicitly imported in EVERY Home Manager evaluation
            # context that uses options it declares. When adding new HM module flakes in
            # the future, the checklist is:
            #   1. Add to flake inputs (with inputs.nixpkgs.follows = "nixpkgs")
            #   2. Import the HM module in nixosConfigurations home-manager.users.*.imports
            #   3. Import the HM module in homeConfigurations modules — this line
            # Skipping step 3 produces the same silent breakage discovered here.
            #
            # This was a finding as a result of diagnosing devenv+direnv setup for the
            # XAMPP NixOS alternative setup. The following commands are what triggered the
            # error leading to the resolution:
            # `nix eval .#homeConfigurations."cypher-whisperer@cypher-nixos".config.programs.direnv.enable 2>&1`
            # `nix eval .#homeConfigurations."cypher-whisperer@cypher-nixos".config.programs.direnv.nix-direnv.enable 2>&1`
            inputs.catppuccin.homeModules.catppuccin
            {
              home.username = "cypher-whisperer";
              home.homeDirectory = "/home/cypher-whisperer";

              cypher-os.profile.desktop.enable = true;
            }
          ];
        };

        # Future hosts — uncomment and add host-specific home.nix as you build them:
        # "cypher-whisperer@arch" = home-manager.lib.homeManagerConfiguration {
        #   inherit pkgs;
        #   modules = [
        #     ./modules/de/gnome.nix   # or hyprland.nix, or both
        #     ./hosts/arch/home.nix
        #     { home.username = "cypher-whisperer"; home.homeDirectory = "/home/cypher-whisperer"; }
        #   ];
        # };

      }; # end homeConfigurations

    }; # end outputs
}
