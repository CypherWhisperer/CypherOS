# [2026_06_21] Browser Fleet — Declarative Privacy-Hardened Browser Namespace

<!-- The journal is informal. This is the human layer on top of git history. Write like you're explaining the session to yourself six months from now. What happened, what you figured out, what you're still unsure about. Honest > polished. -->

**Date:** 2026-06-21
**Duration:** ~6 hours
**Repos touched:** [ `cypher-os` ] 
**Modules touched:**

- `modules/apps/browser/options.nix`
- `modules/apps/browser/default.nix`
- `modules/apps/browser/firefox.nix` _(new)_
- `modules/apps/browser/librewolf.nix` _(new)_
- `modules/apps/browser/mullvad.nix` _(new)_
- `modules/apps/browser/tor-hm.nix` _(new)_
- `modules/apps/browser/tor-system.nix` _(new)_
- `modules/apps/browser/brave-hm.nix` _(revised)_
- `modules/apps/browser/brave-system.nix` _(new)_

**Phase:** 

---

## What I Worked On

Expanded the CypherOS browser namespace from a two-browser stub _(Firefox as a bare `home.packages` entry, Brave with a seed-based activation)_ into a full declarative five-browser fleet with per-browser privacy posture, Catppuccin theming, vertical tabs, declarative extension management, and a NixOS system-level managed policy layer for Brave.

The session was also partly a learning exercise — _the goal wasn't just to ship working configs but to understand _why_ each setting exists, what tradeoff it encodes, and where the ceiling of declarative control actually sits for each browser._

---

## What Got Done

- **`options.nix`** — Expanded the `cypher-os.apps.browser` namespace with kill-switches for all five browsers: `firefox`, `librewolf`, `mullvad`, `tor`, `brave`.
    
- **`firefox.nix`** — Built from scratch. Full `programs.firefox` Home Manager module with:
    
    - Arkenfox-influenced `about:config` hardening _(manually curated, section-numbered for traceability against Arkenfox's wiki — §0100 through §2800)_
      
    - DNS-over-HTTPS via Quad9 _(`network.trr.mode = 2`, fallback mode)_
      
    - WebRTC disabled at the pref level _(`media.peerconnection.enabled = false`)_
    - HTTPS-only mode enforced
    - ETP set to strict with all sub-categories enabled
      
    - Native vertical tabs via `sidebar.revamp = true` + `sidebar.verticalTabs = true` + `sidebar.visibility = "hide-sidebar"` _(collapsed, expands on hover)_
      
    - `userChrome` via `programs.firefox.profiles.default.userChrome` to hide the legacy horizontal tab bar — _requires `toolkit.legacyUserProfileCustomizations.stylesheets = true`_
      
    - Declarative extensions via `pkgs.nur.repos.rycee.firefox-addons`: uBlock Origin, Privacy Badger, Decentraleyes, ClearURLs, Tree Style Tab, Dark Reader, React DevTools, Simple Tab Groups, Tab Session Manager
      
    - uBlock Origin filter lists configured via `extensions.settings`
      
    - Catppuccin Mocha/Mauve theme via `catppuccin.firefox.profiles.default`
      
    - `extensions.force = true` to satisfy the HM assertion guard
      
- **`librewolf.nix`**:
    - Full `programs.librewolf` module. Philosophy inverted vs Firefox: LibreWolf ships Arkenfox-level defaults, so the settings block is mostly _relaxations_ with documented tradeoffs (WebGL re-enabled, history preserved, cookie lifetime normalised). 
    - Same vertical tabs + userChrome + extension stack as Firefox. Catppuccin via `catppuccin.librewolf.profiles.default`.
    
- **`mullvad.nix`**:
    - Intentionally four lines. Zero customisation is the design: Mullvad Browser's anti-fingerprinting depends on every user looking identical.
    - No theme, no extensions, no settings overrides.
    - Paired with planned WireGuard/Mullvad VPN config in CypherOS for network-layer anonymity.
    
- **`tor-hm.nix`**:
    - Package install + thorough operational security documentation: window size discipline, no logins, no extra extensions, no torrenting, timing correlation awareness.
      
- **`tor-system.nix`**:
    - System-level `services.tor` daemon config for when OnionShare / torsocks use cases arise.
    
- **`brave-h,.nix`** — Revised. Key improvements over the original:
    
    - JSON validation (`jq empty`) before seed copy — prevents silent profile corruption from a malformed Preferences file
    - `writeShellScriptBin` wrapper to bake launch flags into every invocation regardless of how Brave is launched (terminal, GNOME grid, rofi)
    - `xdg.desktopEntries.brave-browser` override so the GNOME application grid uses the wrapper
    - Documented the managed policy path as the correct long-term direction
      
- **`brave-system.nix`** — New NixOS system module. Deploys `/etc/brave/policies/managed/cypher-os.json` via `environment.etc`. Policy sections:
    
    - §1 Feature kill-switches: Leo/AI, Rewards, Wallet, VPN, News, Talk, Speedreader, Wayback Machine, Playlist, IPFS, bundled Tor — all disabled
      
    - §2 Telemetry: P3A, stats ping, Web Discovery, Chrome UMA — all killed
      
    - §3 Privacy: password manager, autofill, sync, sign-in, third-party cookies, translation, Global Privacy Control enabled
      
    - §4 DoH: Quad9, `automatic` mode
      
    - §5 Security: HTTPS-only forced, QUIC disabled, WebRTC IP handling set to `disable_non_proxied_udp`, background mode killed
      
    - §6 Shields: policy keys for Shields level enforcement not yet published by Brave — deferred; enforcement remains in seeded Preferences
      
    - §7 Extension allowlist: `ExtensionSettings` with `"*": blocked` and explicit `allowed` entries for uBlock, MetaMask, Proton Pass, ColorZilla, React DevTools, Dark Reader, Catppuccin theme
      
- **`default.nix`** — Updated with import guidance: browser HM modules import via this file; `brave-system.nix` explicitly excluded with a note that it belongs in the NixOS system context (`modules/profile/system.nix`).
    
- **Build:** Successful `nixos-rebuild switch` and `home-manager switch` after resolving the `extensions.settings` assertion error (see _Where I Got Stuck_).
    

---

## Key Decisions Made

**Five-browser fleet, not one browser.** Each browser occupies a distinct threat-model niche. The fleet is:

| Browser     | Role                                                             |
| ----------- | ---------------------------------------------------------------- |
| Firefox     | Daily driver — _dev, web apps, authenticated sessions_           |
| LibreWolf   | Stricter daily driver alternative                                |
| Mullvad     | Sensitive sessions — _research, financial, fingerprint-critical_ |
| Tor Browser | Anonymity-required — _`.onion`, high-stakes comms_               |
| Brave       | Web3 and other                                                   |

**Mullvad Browser: zero customisation as a hard rule.** Anti-fingerprinting depends on uniformity. Any theme, extension, or setting change breaks the model. This is a deliberate, documented constraint, not a gap.

**Workona excluded on privacy grounds.** Workona syncs tab state to their servers. Replaced with `simple-tab-groups` (open-source, local-only). Documented in the extension comments for future reference.

**`WebRtcIPHandling` via managed policy instead of `--disable-features=WebRTC` flag.** The managed policy key restricts which IPs WebRTC can expose without touching Chromium's feature module. The flag was too blunt and broke YouTube's media pipeline (see _Where I Got Stuck_).

**Brave wrapper reverted to `pkgs.brave` pending further investigation.** The `writeShellScriptBin` wrapper approach is architecturally correct but the specific flag combination caused a YouTube regression that wasn't worth continuing to chase in this session. Documented as a future workstream.

**`extensions.force = true` as the acknowledged ownership signal.** Home Manager requires explicit acknowledgment that `extensions.settings` takes full declarative ownership of extension preferences for a profile. Setting `force = true` at the profile level is correct posture for CypherOS — you declare it, you own it entirely.

---

## Where I Got Stuck

**`extensions.settings` assertion error on first build.** Home Manager threw a hard assertion:

```
Using 'programs.firefox.profiles.default.extensions.settings' will override all
previous extensions settings. Enable either
'programs.firefox.profiles.default.extensions.force' or the corresponding
'programs.firefox.profiles.default.extensions.settings.<extensionId>.force'
to acknowledge this.
```

Fix: add `extensions.force = true` at the profile level (not per-extension). Same fix required for LibreWolf. Straightforward once the error message was read carefully.

**Vertical tabs not kicking in on first switch.** The `sidebar.revamp` and `sidebar.verticalTabs` prefs were written to `user.js` correctly but Firefox and LibreWolf already had existing profiles with `prefs.js` on disk. `prefs.js` wins over `user.js` when the pref is already set. Fix: delete `prefs.js` and let Firefox regenerate it from `user.js` on next launch.

```bash
rm ~/.config/mozilla/firefox/<profile>/prefs.js
rm ~/.librewolf/<profile>/prefs.js
```

The hover-expand behaviour (`sidebar.visibility = "hide-sidebar"`) also needed to be added explicitly — it was not implied by enabling vertical tabs.

**YouTube ads on Brave after module revision.** After switching from bare `pkgs.brave` to the `writeShellScriptBin` wrapper, YouTube began showing ads. Brave's built-in Shields were confirmed on and set to Aggressive. 

Root cause: UNKNOWN; _assumptions `--disable-features=WebRTC` in the wrapper flags._ This flag operates at Chromium's feature module level, not at the WebRTC network behaviour level. YouTube's player uses WebRTC APIs internally for adaptive bitrate streaming — _disabling the module caused the player to fall back to a degraded path where Shields no longer intercepted ad requests correctly._ Confirmed by: phone running stock Brave binary (no wrapper, no flags) showed no YouTube ads; desktop with wrapper showed ads.

Attempted fixes:

1. Removed `--disable-features=WebRTC` specifically → still broken (other flags may have also been interfering, or the player was in a broken cache state)
2. Reverted to `pkgs.brave` entirely → ads gone, confirmed working

Settled resolution: revert to `pkgs.brave` for now. `WebRtcIPHandling` managed policy covers the IP leak concern. The wrapper approach is architecturally sound but needs more careful flag auditing before reintroduction.

**YouTube ads on Firefox and LibreWolf.** uBlock Origin filter lists had not yet downloaded on the fresh profile — lists are configured declaratively but the cache downloads at first launch. Fix: open uBlock dashboard → Filter Lists → Update Now. Added `adguard-annoyances`, `adguard-social`, and `ublock-annoyances` to the `selectedFilterLists` to cover YouTube-specific ad injection patterns.

---

## What I Learned

**Brave's declarative management ceiling is real and architecturally motivated.** Chromium writes back to `Preferences` on every launch. There is no `programs.brave` Home Manager module and there never will be in the same form as `programs.firefox`, because the config model is fundamentally incompatible. The two correct levers are: managed policies (system-level, durable) and the seeded Preferences (one-shot, mutable). Understanding this boundary makes the architecture obvious rather than hacky.

**LibreWolf settings are relaxations, not hardening.** Coming in expecting to harden LibreWolf the same way as Firefox is the wrong mental model. LibreWolf already starts at the hardened position. The configuration work is deciding what to give back for usability. This inversion is worth internalising.

**`--disable-features=` is a sledgehammer, not a scalpel.** Chromium feature flags toggled via `--disable-features=` operate at the module level. Disabling `WebRTC` at that level removes the entire subsystem, not just the network behaviour you're trying to restrict. The right tool for WebRTC IP leak prevention is either `media.peerconnection.ice.default_address_only` (Firefox prefs) or `WebRtcIPHandling` (Chromium managed policy). Lesson: always understand what layer a flag operates at before including it.

**The § symbol.** The section sign. Used in legal and technical documents to reference numbered sections. Medieval manuscript origin, same family as ¶ (pilcrow). Now used in CypherOS module comments to section-number configuration blocks for traceability.

**Mullvad Browser's anti-fingerprinting model.** The protection comes from _uniformity_, not from hiding. Every Mullvad Browser user looks identical to a tracker. The moment you customise — a theme, an extension, a changed pref — you become distinguishable. This is the same model Tor Browser uses. Configuring it is philosophically missing the point.

**uBlock Origin and Brave's MV2 situation (June 2026).** Google removed MV2 extensions from the Chrome Web Store. Brave hosts uBlock Origin on its own MV2 backend (`brave://settings/extensions/v2`) but has not published a policy-accessible update URL for `ExtensionInstallForcelist`. Force-install via policy is currently blocked on Brave publishing that URL. The declarative workaround is embedding the extension ID in the seeded Preferences file.

**Server-Side Ad Injection (SSAI) on YouTube.** Google began testing SSAI in mid-2024 — stitching ads directly into the video stream so they share the same CDN address as content. At the network level, ad and content segments are indistinguishable. No browser extension can strip them at that point. As of June 2026, SSAI is not yet widely deployed on YouTube — most ad blocking still works via scriptlet injection. But it is the stated long-term direction and represents a genuine ceiling for client-side ad blocking.

---

## Open Questions

- **Brave wrapper flags + YouTube regression** — which specific flag(s) break the media pipeline? Is it `--disable-features=WebRTC` alone or do others contribute? Worth testing flags in isolation on a throwaway profile. Could also investigate whether the concerns the flags address (breakpad crash reporting, component update pings) are fully covered by managed policy so the wrapper can be retired entirely.
    
- **Brave Shields level via managed policy** — no official policy key exists as of 2026-06. Monitor: `https://github.com/brave/brave-browser/issues/22029`. When a key lands, add it to `brave-system.nix` §6.
    
- **uBlock Origin force-install via Brave managed policy** — blocked on Brave publishing a documented MV2 update URL for `ExtensionInstallForcelist`. Monitor Brave's GitHub and release notes.
    
- **Full `arkenfox-nixos` module integration for Firefox** — the current settings block is manually curated from Arkenfox's recommendations. The proper path is `github:dwarfmaster/arkenfox-nixos` as a flake input with per-section review. Deferred until there's time to review each section deliberately.
    
- **LibreWolf `extensions.settings` symlink bug (HM 25.05)** — known issue where LibreWolf doesn't follow symlink-to-symlink chains for the extensions directory. If extensions fail to load after a switch, track: `https://github.com/nix-community/home-manager/issues/7948`.
    
- **System-level `services.tor` daemon** — deferred until a concrete use case arises (OnionShare, torsocks, Ricochet-Refresh). Config block already written as a comment in `tor.nix`, ready to lift into `system.nix`.
    
- **SSAI (YouTube Server-Side Ad Insertion)** — not a problem yet at scale, but worth watching. If it becomes the norm, the correct response shifts from browser extension to alternative frontend (FreeTube, Invidious, Piped) rather than continued extension arms race.
    

---

## Next Session

Documentation pass for the browser fleet — ADRs, module reference docs, and runbook entries covering:

- The two-plane architecture (HM browser modules + NixOS `brave-system.nix`)
- The five-browser fleet usage guide
- Brave managed policy verification procedure (`brave://policy`)
- Open questions from this session formatted as tracked items

---

<!-- Commit range (fill in after session):
cypher-os: [short hash] → [short hash] 
-->