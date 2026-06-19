# modules/apps/browser/librewolf.nix
#
# Declarative LibreWolf module for CypherOS.
#
# ── WHAT THIS FILE OWNS ──────────────────────────────────────────────────────
#   - LibreWolf installation via programs.librewolf (Home Manager module)
#   - Profile "default" with privacy settings, extensions, and chrome CSS
#   - Catppuccin theming via catppuccin/nix (catppuccin.librewolf.*)
#   - Vertical tabs (same strategy as Firefox)
#
# ── LIBREWOLF vs FIREFOX HARDENING ───────────────────────────────────────────
#   LibreWolf ships Arkenfox-influenced defaults OUT OF THE BOX:
#     - All telemetry disabled by default
#     - privacy.resistFingerprinting = true by default
#     - WebGL disabled by default
#     - Clear-on-shutdown enabled by default
#     - No pocket, no sponsored tiles, no Mozilla accounts
#
#   The settings block here is therefore mostly RELAXATIONS of LibreWolf's
#   aggressive defaults to make it usable as a daily driver. You are
#   explicitly trading off some privacy for usability. Each relaxation is
#   commented with the reason.
#
# ── CATPPUCCIN ───────────────────────────────────────────────────────────────
#   catppuccin/nix supports LibreWolf natively via catppuccin.librewolf.*.
#   Same propagation mechanism as Firefox: theme injected via Firefox Color.
#   Ref: https://nix.catppuccin.com/options/25.05/home/catppuccin.librewolf/
#
# ── EXTENSIONS IN LIBREWOLF ──────────────────────────────────────────────────
#   programs.librewolf.profiles.<n>.extensions uses the same NUR rycee
#   firefox-addons source as Firefox. LibreWolf shares the Gecko extension API.
#
#   KNOWN ISSUE (HM 25.05): LibreWolf does not follow symlink-to-symlink chains
#   for extensions directory. If extensions fail to load after switch, verify:
#     ls -la ~/.librewolf/<profile>/extensions/
#   If symlinks point to the Nix store correctly but extensions still don't load,
#   this is the known bug: github.com/nix-community/home-manager/issues/7948
#   Workaround: install affected extensions manually until upstream fix lands.
#
# ── VERIFYING SETUP ──────────────────────────────────────────────────────────
#   After `home-manager switch`:
#     ls -la ~/.librewolf/<profile>/chrome/userChrome.css
#     librewolf about:config → toolkit.legacyUserProfileCustomizations.stylesheets

{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.apps.browser.enable && config.cypher-os.apps.browser.librewolf.enable) {

    programs.librewolf = {
      enable = true;

      # ── Global settings (apply to all profiles) ────────────────────────────
      # These relax LibreWolf's most aggressive defaults.
      # Everything not listed here retains LibreWolf's hardened defaults.
      settings = {
        # WebGL: LibreWolf disables by default. Re-enable for web apps that
        # require it (Figma, Penpot browser, some map renderers).
        # TRADEOFF: WebGL exposes GPU fingerprinting surface.
        "webgl.disabled" = false;

        # resistFingerprinting: LibreWolf enables by default. Keeping it ON.
        # NOTE: This sets the OS reported to Windows to reduce fingerprint variance.
        # Disable only if OS spoofing causes breakage you cannot tolerate.
        "privacy.resistFingerprinting" = true;

        # History: LibreWolf clears on shutdown by default. Relax for usability.
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "privacy.sanitize.sanitizeOnShutdown" = false;

        # Cookies: LibreWolf sets lifetimePolicy = 2 (expire on session end).
        # Set to 0 = accept cookies normally (honor server expiry).
        "network.cookie.lifetimePolicy" = 0;

        # HTTPS-only mode: keep on (LibreWolf default is off; enforce it)
        "dom.security.https_only_mode" = true;

        # DNS-over-HTTPS (same Quad9 config as Firefox)
        "network.trr.mode" = 2;
        "network.trr.uri"  = "https://dns.quad9.net/dns-query";
        "network.trr.bootstrapAddress" = "9.9.9.9";

        # Proton Pass: LibreWolf's default disables form autofill. Keep disabled
        # since Proton Pass extension handles password autofill.
        "signon.autofillForms"           = false;
        "signon.formlessCapture.enabled" = false;

        # Vertical tabs (same as Firefox module)
        "sidebar.revamp"       = true;
        "sidebar.verticalTabs" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # UX quality-of-life
        "browser.compactmode.show"              = true;
        "browser.uidensity"                     = 1;
        "browser.tabs.closeWindowWithLastTab"   = false;
        "browser.aboutConfig.showWarning"       = false;
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.link.open_newwindow"           = 3;
      };

      profiles.default = {
        id        = 0;
        name      = "default";
        isDefault = true;

        # ── userChrome.css ────────────────────────────────────────────────────
        userChrome = ''
          @-moz-document url(chrome://browser/content/browser.xhtml) {
            /* Hide legacy horizontal tab bar — vertical sidebar replaces it */
            #TabsToolbar {
              visibility: collapse !important;
            }

            /* Hide Tree Style Tab sidebar header chrome */
            #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"]
            #sidebar-header {
              visibility: collapse !important;
            }

            /* Compact nav bar */
            #nav-bar {
              padding-top: 2px !important;
              padding-bottom: 2px !important;
            }
          }
        '';

        # ── Extensions ────────────────────────────────────────────────────────
        # See NOTE in header re: HM 25.05 symlink bug for LibreWolf.
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          privacy-badger
          decentraleyes
          clearurls
          tree-style-tab
          dark-reader
          react-devtools
          simple-tab-groups
          tab-session-manager
        ];

        extensions.settings = {
          "uBlock0@raymondhill.net".settings = {
            selectedFilterLists = [
              "ublock-filters"
              "ublock-badware"
              "ublock-privacy"
              "ublock-unbreak"
              "ublock-quick-fixes"
              "easylist"
              "easyprivacy"
              "adguard-generic"
              "urlhaus-1"
            ];
          };
        };
      };
    };

    # ── Catppuccin LibreWolf Integration ─────────────────────────────────────
    catppuccin.librewolf.profiles.default = {
      enable = true;
      flavor = "mocha";
      accent = "mauve";
    };
  };
}
