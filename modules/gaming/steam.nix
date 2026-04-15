# modules/gaming/steam.nix
#
# NixOS system-level module for Steam and gaming infrastructure.
#
# WHAT THIS FILE OWNS:
#   - programs.steam (system-level Steam enablement + kernel/driver wiring)
#   - hardware.steam-hardware (controller udev rules)
#   - programs.gamemode (CPU/GPU performance governor for gaming sessions)
#   - steam-run (FHS chroot for native Linux games expecting a standard FS)
#   - Proton GE (community Proton builds with broader game compatibility)
#   - protonup-qt (GUI for managing Proton/Wine versions outside Nix)
#
# WHAT THIS FILE DOES NOT OWN:
#   - ~/.local/share/Steam/ — managed by Steam itself at runtime; not declared here
#   - SteamLibrary path — registered inside Steam UI on first run, not in Nix
#     (Steam writes library paths to config/libraryfolders.vdf at runtime)
#   - Game installations — imperative, managed by Steam
#   - Steam credentials / Steam Guard tokens — never in Nix, never in the repo
#
# CROSS-OS LIBRARY SHARING (CypherOS context):
#   The SteamLibrary lives on a dedicated BTRFS subvolume (@steam-library or
#   similar) mounted consistently across all lenses (e.g. /path/to/shared/SteamLibrary).
#   After first launch, add it via Steam > Settings > Storage.
#   Steam will write a libraryfolders.vdf entry and detect it automatically
#   on subsequent launches — no Nix declaration needed for this.
#
# STEAM GUARD NOTE:
#   Sharing config/ across OS lenses may trigger re-authentication when Steam
#   detects a new machine context. This is intentional Valve security behavior.
#   Only share userdata/ and steamapps/ across lenses; let config/ regenerate.
#
# FIRST-RUN CHECKLIST:
#   1. Launch Steam — it will self-update and populate ~/.local/share/Steam/
#   2. Log in (Steam Guard will challenge you once per new machine context)
#   3. Settings > Storage > Add Library Folder → /data/SteamLibrary (or your path)
#   4. For Proton GE: launch ProtonUp-Qt and install desired GE versions

{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
  
    # ── Gaming ───────────────────────────────────────────────────────────────
    steam # unfree; includes steam-run and pressure-vessel
    wine
    winetricks

  ];

  # ── Core Steam enablement ──────────────────────────────────────────────────
  #
  # programs.steam is a NixOS module (not HM) — it handles:
  #   - The Steam package itself
  #   - 32-bit library support (hardware.opengl.driSupport32Bit et al.)
  #   - hardware.steam-hardware for controller udev rules (Valve Index,
  #     Steam Controller, DualShock, etc.)
  #   - allowNonFree is handled separately in nixpkgs.config
  programs.steam = {
    enable = true;

    # Opens UDP 27036 for Steam Remote Play streaming to other devices on LAN.
    # Disable if you don't use this feature.
    remotePlay.openFirewall = true;

    # Opens TCP/UDP 27040 for Steam local network game transfers (fast local
    # game installs from another PC on the same network).
    localNetworkGameTransfers.openFirewall = true;

    # Declaratively pin the set of extra Proton compatibility layers available
    # to Steam. proton-ge-bin is the community "GloriousEggroll" build which
    # adds patches for games that upstream Proton doesn't cover yet (anti-cheat
    # exceptions, Windows media codec support, etc.).
    #
    # Note: proton-ge-bin comes from nixpkgs; for the absolute latest GE builds
    # before they land in nixpkgs, use protonup-qt imperatively (see below).
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];

    # Uncomment to add extra libraries into Steam's FHS environment if a game
    # refuses to launch due to missing .so files. Common candidates:
    #   pkgs.libgdiplus   — .NET/Mono games
    #   pkgs.mono         — same
    #   pkgs.SDL2         — older SDL2 games
    # extraLibraries = p: with p; [ ];
  };

  # ── GameMode ──────────────────────────────────────────────────────────────
  #
  # Feral's GameMode daemon: games that support it (or that you launch via
  # gamemoderun) request a temporary performance profile — CPU governor →
  # performance, GPU overclocking hints, scheduler tuning. Reverts on exit.
  # Steam launch option to enable per-game: gamemoderun %command%
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    # ── steam-run ─────────────────────────────────────────────────────────────
    #
    # FHS-compatible chroot environment for running native Linux game binaries
    # that expect a standard filesystem layout (glibc at /lib, etc.). NixOS's
    # Nix store layout breaks these assumptions; steam-run wraps them correctly.
    #
    # Usage: steam-run ./NFS_MW_binary   or   steam-run %command% in Steam
    # NFS MW specifically may need this if its binary isn't a Steam-managed title.
    steam-run

    # ProtonUp-Qt: GUI to install/remove Proton GE, Wine GE, and other
    # compatibility tool versions into ~/.steam/root/compatibilitytools.d/.
    # Use this for GE versions not yet in nixpkgs, or for Wine-based launchers.
    protonup-qt

    # MangoHud: Vulkan/OpenGL overlay showing FPS, frame times, GPU/CPU temps
    # and load. Enable per-game in Steam: MANGOHUD=1 %command%
    mangohud
  ];

  # ── Kernel-level gaming optimizations ─────────────────────────────────────
  #
  # vm.max_map_count: Steam (and some games like CS2, Elden Ring) require a
  # higher max memory map count than the kernel default of 65530.
  # 2147483642 is the value Valve recommends; Steam itself will warn if it's too low.
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
  };
}
