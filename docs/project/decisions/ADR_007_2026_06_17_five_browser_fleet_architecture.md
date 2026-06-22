# ADR_007_2026_06_15: Five-Browser Fleet Architecture

**Date:** 2026-06-17
**Status:** Accepted 
**Deciders:** CypherWhisperer

---

## Context

CypherOS previously had a two-browser setup: Firefox as a bare `home.packages` entry with no configuration, and Brave with a seed-based activation script. Neither was declaratively managed at the preference or extension level.

The prompt to expand the browser namespace surfaced a core tension: privacy, security, and anonymity are distinct threat-model dimensions, and no single browser addresses all three optimally without compromising on the others. Attempting to harden one browser to cover all use cases produces a browser that is either broken for daily use (too aggressive) or insufficiently hardened for sensitive sessions (too relaxed).

The five browsers available for consideration each occupy a different point in the design space:

- **Firefox** — fully configurable at the `about:config` level; NixOS/HM declarative support is deep (`programs.firefox`, NUR extensions, userChrome, Catppuccin); viable as a hardened daily driver with Arkenfox-influenced settings.
- **LibreWolf** — Firefox fork that ships Arkenfox-level defaults out of the box; less configuration work required; same HM module surface as Firefox.
- **Mullvad Browser** — built by the Tor Project in collaboration with Mullvad VPN; anti-fingerprinting via uniformity (every user looks identical); designed to pair with a trusted VPN rather than the Tor network; no declarative customisation by design.
- **Tor Browser** — maximum network anonymity via onion routing; correct tool for dissociating identity from traffic; impractical as a daily driver.
- **Brave** — best-in-class default privacy for a Chromium-based browser; strong built-in shields; required for MetaMask and Web3 workflows; limited declarative management ceiling due to Chromium's mutable Preferences model.

CypherOS already has Mullvad VPN configured via WireGuard. The fleet therefore has a natural VPN pairing for Mullvad Browser.

---

## Decision

CypherOS will maintain a declarative five-browser fleet — _Firefox, LibreWolf, Mullvad Browser, Tor Browser, and Brave_ — each assigned a distinct primary use case based on its threat-model strengths, rather than attempting to harden a single browser to cover all scenarios.

---

## Reasoning

Each browser is the correct tool for a specific class of session:

| Browser     | Primary role                                                       |
| ----------- | ------------------------------------------------------------------ |
| Firefox     | Daily driver — _dev work, web apps, authenticated sessions_        |
| LibreWolf   | Stricter daily driver alternative; fewer relaxations required      |
| Mullvad     | Sensitive sessions — _research, financial, fingerprint-critical_   |
| Tor Browser | Anonymity-required — _`.onion` access, high-stakes communications_ |
| Brave       | Web3; Chromium-specific tooling                                    |

A single hardened browser cannot simultaneously provide fingerprint uniformity (requires identical configuration across all users — i.e. no customisation), daily-driver usability (requires customisation and persistent sessions), and onion-routed anonymity (requires Tor network integration and specific circuit isolation behaviour).

The fleet model accepts this and assigns tools deliberately. The cost — five browsers installed — is low on NixOS where packages are store-resident and disk space is the only meaningful overhead. The gain is a browser for every threat level without compromising any of them.

LibreWolf serves as a practical alternative to Firefox for sessions where the user wants aggressive defaults without manual configuration. Firefox serves where extension ecosystem coverage and developer tooling matter more. Both are fully declarative.

Mullvad Browser and Tor Browser carry intentional configuration constraints (zero customisation) that are enforced by convention and documented in their respective modules. These constraints are features, not gaps.

---

## Alternatives Considered

### Single hardened Firefox

Harden one Firefox profile to cover all threat levels. Simpler module surface, one browser to maintain.

Rejected because the hardening settings required for anonymity-grade use (resistFingerprinting, no extensions, uniform window size, ephemeral sessions) directly conflict with daily driver usability (persistent history, custom extensions, comfortable window sizing). A single profile cannot hold both positions simultaneously without one undermining the other.

### Brave as the sole browser

Brave's defaults are strong and it requires less configuration work than Firefox. Use it for everything.

Rejected because: (1) Chromium-based — declarative management ceiling is low due to the mutable Preferences model; (2) no equivalent to Mullvad Browser's fingerprint uniformity model; (3) no onion routing for anonymity-required sessions; (4) trust history (2020 affiliate link controversy, 2021 Tor DNS leak) warrants not making it the sole browser; (5) feature bloat (Rewards, Wallet, AI) increases attack surface even when disabled.

### Firefox + Tor Browser only

Two browsers: Firefox hardened for daily use, Tor for anonymity. Simpler than five.

Rejected because this leaves no solution for the fingerprinting threat model. A hardened Firefox with custom extensions and settings is uniquely fingerprint-able regardless of how aggressively `privacy.resistFingerprinting` is set — the specific combination of extensions, fonts, and prefs creates a distinguishable profile. Mullvad Browser's uniformity model addresses a threat that Firefox cannot.

---

## Consequences

**Positive:**

- Every threat-model scenario has a purpose-built tool. No compromises between usability and privacy within any single browser.
- Mullvad Browser + WireGuard VPN provides a strong fingerprint + network anonymity combination for sensitive sessions without requiring Tor's usability tradeoffs.
- Tor Browser is available immediately when needed — no scrambling or ad-hoc setup at the moment of need.
- All five browsers are declaratively managed in the `cypher-os.apps.browser` namespace with individual kill-switches, making the fleet composable and auditable.

**Negative / Trade-offs:**

- Five browsers installed means five packages in the Nix store. Disk overhead is real but acceptable given NixOS's store deduplication.
- Requires discipline to use the right browser for the right session. The tooling does not enforce this — the user must internalise the threat-model mapping.
- Five modules to maintain when upstream changes (NixOS, Home Manager, nixpkgs, catppuccin/nix) require updates.
- Mullvad Browser and Tor Browser have no Home Manager module — they are bare `home.packages` entries. Any future declarative surface for them depends on upstream.

**Neutral / Operational:**

- Adding a sixth browser follows the established pattern: `options.nix` entry, `<browser>.nix` HM module, import in `default.nix`.
- Browsers with no aesthetics requirements (Mullvad, Tor) are intentionally minimal modules. This is by design and should not be treated as documentation debt.
- The `cypher-os.apps.browser.enable` kill-switch disables the entire fleet in one toggle if needed (e.g. a minimal headless build).