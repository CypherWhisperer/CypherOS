# modules/apps/browser/default.nix
#
# Browser namespace entry point for CypherOS.
#
# ── IMPORT ORDER ─────────────────────────────────────────────────────────────
#   options.nix must be imported first (or alongside) all implementation files
#   because it declares the option namespace that all modules guard against.
#
#   Home Manager resolves imports as a module system merge — order within
#   the list is not meaningful for evaluation, but listed logically here.
#
# ── NUR REQUIREMENT ──────────────────────────────────────────────────────────
#   Firefox and LibreWolf extension management requires the NUR overlay.
#   In flake.nix:
#     inputs.nur.url = "github:nix-community/NUR";
#   In your nixpkgs config:
#     nixpkgs.overlays = [ inputs.nur.overlays.default ];
#
# ── FLEET USAGE GUIDE ────────────────────────────────────────────────────────
#   Browser            | Use for
#   ─────────────────────────────────────────────────────────────────────────
#   Firefox            | Daily driver — dev work, web apps, authenticated sessions
#   LibreWolf          | Alternative daily driver — stricter defaults than Firefox
#   Mullvad Browser    | Sensitive sessions — research, financial, privacy-critical
#   Tor Browser        | Anonymity-required sessions — .onion, high-stakes comms
#   Brave              | Web3 / MetaMask workflows, Brave-specific features
#   ─────────────────────────────────────────────────────────────────────────

{ ... }:

{
  imports = [
    ./options.nix
    ./firefox.nix
    ./librewolf.nix
    ./mullvad.nix
    ./tor-hm.nix
    ./brave.nix
  ];
}
