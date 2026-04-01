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
  description = "cypher-system — CypherOS unified multi-OS configuration flake";

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
   # nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11"; # stable channel
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # unstable channel


    home-manager = {
      # url    = "github:nix-community/home-manager/release-24.11";
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
      inputs.nixpkgs.follows = "nixpkgs";   # deduplicate — use our nixpkgs, not theirs
    };
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
  outputs = { self, nixpkgs, home-manager, claude-desktop, ... }@inputs:
  let
    # system: the CPU architecture + OS pair Nix uses to select packages.
    # x86_64-linux covers standard 64-bit Intel/AMD Linux machines.
    # If you ever add an ARM machine, you'd add "aarch64-linux" entries.
    system = "x86_64-linux";

    # pkgs: the nixpkgs package set for our system, with unfree allowed.
    # Declaring it here means we reference it once rather than repeating
    # the same nixpkgs.legacyPackages.${system} call everywhere.

    # CLAUDE RELATED COMMENT BLOCK
    # pkgs is instantiated here for use in standalone homeConfigurations.
    # The NixOS nixosConfigurations path does NOT use this pkgs — NixOS builds
    # its own pkgs internally (with the overlays applied via nixpkgs.overlays
    # in configuration.nix). Using this pkgs in nixosConfigurations would
    # bypass the overlay, which is why homeConfigurations.pkgs and
    # nixosConfigurations.pkgs are intentionally separate.
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

  in {

    # ── NixOS System Configurations ─────────────────────────────────────────
    # nixosConfigurations defines bootable NixOS systems.
    # Each key is the hostname — referenced with --flake .#<hostname>.
    #
    # lib.nixosSystem builds a full NixOS system from the module list.
    # The home-manager NixOS module (homeManagerModules.home-manager) integrates
    # Home Manager directly into `nixos-rebuild switch` — one command applies
    # both the system config and the user config.
    nixosConfigurations = {

      nixos-gnome = nixpkgs.lib.nixosSystem {
        inherit system;

        # CLAUDE RELATED COMMENT BLOCK
        # specialArgs threads the `inputs` attrset into every NixOS
        # module in this configuration. This is the only way to make
        # `inputs.claude-desktop` available inside configuration.nix without
        # importing the flake directly there (which would break modularity).
        # The overlay registration in configuration.nix reads:
        #   nixpkgs.overlays = [ inputs.claude-desktop.overlays.default ];
        specialArgs = { inherit inputs; };

        modules = [
          # The system-level configuration for this host
          ./hosts/nixos-gnome/configuration.nix

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
            home-manager.useGlobalPkgs    = true;

            # useUserPackages: packages declared in home.packages are installed
            # into /etc/profiles/per-user/<user>/ rather than ~/.nix-profile.
            # This makes them available in GDM and system contexts.
            home-manager.useUserPackages  = true;

            # Thread inputs into Home Manager modules too, in case any HM module
            # ever needs to reference a flake input directly.
            home-manager.extraSpecialArgs = { inherit inputs; };

            # The actual Home Manager configuration for cypher-whisperer.
            # This imports gnome.nix which declares all user-space packages,
            # dconf settings, GTK theme, and the XDG launcher script.
            home-manager.users.cypher-whisperer = { config, pkgs, lib, ... }: {
              imports = [ ./modules/de/gnome.nix ];

              # Identity — must match users.users declaration in configuration.nix
              home.username    = "cypher-whisperer";
              home.homeDirectory = "/home/cypher-whisperer";
            };
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
    # The nixos-gnome entry here is a convenience — allows running HM standalone
    # on NixOS too if you prefer that workflow during development.
    homeConfigurations = {

      "cypher-whisperer@nixos-gnome" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./modules/de/gnome.nix
          {
            home.username      = "cypher-whisperer";
            home.homeDirectory = "/home/cypher-whisperer";
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
