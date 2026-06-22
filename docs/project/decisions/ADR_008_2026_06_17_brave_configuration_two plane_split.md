# ADR_008_2026_06_17: Brave Configuration Two-Plane Split (HM Seed + NixOS Managed Policy)

**Date:** 2026-06-17
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

Brave is a Chromium-based browser. Chromium writes back to its `Preferences` JSON file on every launch — updating timestamps, extension state, window geometry, session data, and internal metrics. This is not configurable behaviour; it is fundamental to how Chromium manages profile state.

Home Manager's standard declarative mechanism for program configuration is `home.file`, which creates symlinks from `~/.config/...` into the Nix store. Nix store paths are read-only by design. A symlink from `~/.config/BraveSoftware/.../Preferences` into the store would cause Brave to either silently discard all runtime writes or crash on launch when it attempts to write back to a read-only path.

This makes `home.file` unusable for Brave's `Preferences` file. There is no `programs.brave` Home Manager module (unlike `programs.firefox`) and there is unlikely to ever be one in the same form, because the declarative model assumes the application does not mutate its own config files at runtime — an assumption Chromium violates by design.

There are two mechanisms that _do_ work:

1. **Seeded activation (HM `home.activation`):** Copy seed files from the Nix store into `~/.config/BraveSoftware/...` on first install, guarded by a file-existence check. Brave can then mutate them freely. The seed represents a known-good starting state. Re-seeding requires manual deletion of the target files.
    
2. **Managed policies (`/etc/brave/policies/managed/*.json`):** Chromium reads JSON policy files from this directory at every launch, before evaluating `Preferences`. Policy values take precedence over `Preferences` and cannot be overridden by the user or by Brave's runtime writes. This is a NixOS system-level concern (`environment.etc`) and must be deployed via `nixos-rebuild switch`.
    

These two mechanisms have complementary scope: the seed handles state that policies cannot reach (extension installation, bookmarks, NTP background, UI geometry); policies handle settings that must be durable and tamper-resistant (privacy enforcement, telemetry kill-switches, extension allowlist).

---

## Decision

Brave configuration in CypherOS is split across two evaluation planes:

- **`modules/apps/browser/brave.nix` (Home Manager):** Owns package installation, the launch wrapper, the seeded `Preferences` and `Bookmarks` files via `home.activation`, and the XDG desktop entry override.
- **`modules/apps/browser/brave-system.nix` (NixOS system):** Owns managed policies deployed to `/etc/brave/policies/managed/cypher-os.json` via `environment.etc`.

---

## Reasoning

The split follows the natural ownership boundary imposed by the two mechanisms:

- Seed files are user-space files in `$HOME` — Home Manager's domain.
- `/etc/` is system territory — NixOS's domain.

Attempting to deploy `/etc/brave/policies/managed/` from a Home Manager module is technically possible via `home.activation` with `sudo`, but this is fragile, requires `sudo` availability in activation scripts, and blurs the NixOS/HM boundary in a way that breaks CypherOS's established evaluation model (the split-brain problem documented in ADR_005).

Managed policies provide guarantees the seed cannot: they survive profile resets, they cannot be overridden by Brave's runtime writes, and they apply to all profiles simultaneously. For security-relevant settings (telemetry, extension allowlist, WebRTC, HTTPS enforcement), managed policy is the correct mechanism precisely because it is durable.

The seed mechanism is correct for everything policies cannot reach: extension IDs (Brave's MV2 backend does not expose a policy-accessible force-install URL as of 2026-06), bookmarks, NTP configuration, and UI state. The seed activation script includes JSON validation (`jq empty`) before copying to prevent silent profile corruption from a malformed seed file.

This pattern mirrors the existing split in CypherOS for Proton Bridge (`proton-bridge-hm.nix` / `proton-bridge-system.nix`) and is consistent with ADR_005's module architecture.

---

## Alternatives Considered

### Single HM module managing everything via `home.activation`

Use `home.activation` for both the seed files and the policy files (the latter via a privileged copy into `/etc/`).

Rejected because: (1) `home.activation` running `sudo` commands is fragile and depends on passwordless sudo being configured, which is a separate security concern; (2) it violates the NixOS/HM boundary — `/etc/` is system territory and should be owned by NixOS evaluation; (3) changes to policy would require `home-manager switch` rather than `nixos-rebuild switch`, which is the wrong tool for system-level changes.

### `jq`-based merge script instead of full seed

Rather than seeding the entire `Preferences` file, use a `jq` merge script in `home.activation` that extracts only the keys we care about (extension IDs, theme, shield settings) and deep-merges them into Brave's live `Preferences` on every switch.

Not rejected — this is the correct long-term direction for cleaner diffs and noise-free snapshots. Deferred because it adds meaningful complexity (the merge script must handle Brave's nested JSON schema correctly, and must be tested against Brave version upgrades). The current seed approach is sufficient until the Preferences diff noise becomes a maintenance burden.

### Brave via Flatpak or AppImage

Install Brave outside of nixpkgs to get a self-updating binary and avoid the managed policy complexity.

Rejected because: (1) Flatpak and AppImage are outside the Nix store and invisible to CypherOS's declarative model; (2) managed policies work identically for the nixpkgs package; (3) self-updating binaries outside Nix create an unaudited update path.

---

## Consequences

**Positive:**

- Security-critical settings (telemetry, extension allowlist, WebRTC, HTTPS enforcement) are enforced at the managed policy level and cannot be overridden by Brave at runtime or by user action in `brave://settings`.
- `brave://policy` provides a live audit view of all enforced policies with `Source: Machine` and `Status: OK` per key — verifiable after every `nixos-rebuild switch`.
- The seed mechanism handles everything policies cannot reach without requiring privileged activation scripts.
- Pattern is consistent with existing CypherOS HM/system split conventions (ADR_005).

**Negative / Trade-offs:**

- Two files to maintain instead of one. Changes to Brave configuration must be mentally mapped to the correct plane (HM vs NixOS) before editing.
- `nixos-rebuild switch` required for policy changes; `home-manager switch` required for seed/wrapper changes. A change spanning both planes requires both commands.
- The seed approach means Brave's runtime state diverges from the seed over time. Snapshots (`cp Preferences <repo>/configs/browser/brave/Preferences`) must be performed manually to keep the seed current. This is operational discipline, not automation.
- Brave Shields level cannot be enforced via managed policy as of 2026-06 (no published policy key). Shields configuration remains in the seed only and is therefore mutable at runtime. Track upstream for when this changes.
- uBlock Origin force-install via `ExtensionInstallForcelist` is blocked on Brave publishing a documented MV2 update URL. Extension installation remains seed-dependent.

**Neutral / Operational:**

- Verifying the full configuration requires checking two sources: `brave://policy` for managed policy enforcement, and `brave://extensions` + `brave://settings` for seed-derived state.
- Adding a new managed policy key: edit `brave-system.nix` → `nixos-rebuild switch` → verify at `brave://policy`.
- Updating the seed: make changes in Brave → `cp Preferences <repo>/...` → `git add -p` → `git commit`.