# INC-2026-06-06-001: `python3.13-pipx-1.8.0` Build Failure Blocks System Rebuild

**ID:** INC_2026_06_06_001
**Date:** 2026-06-06
**Severity:** Medium — system rebuild fully blocked; running system unaffected
**Status:** Resolved
**Reported by:** CypherWhisperer

**Consequences:**
→ `pipx` commented out of `modules/apps/dev/hm.nix` pending upstream fix

---

## Summary

After a routine `nix flake update`, the system rebuild failed completely due to `python3.13-pipx-1.8.0` failing its own test suite during the Nix build. The failure cascaded through the entire Home Manager and NixOS closure, blocking the rebuild. The running system was never at risk — only the new generation could not be built.

---

## Timeline

| Time       | Event                                                                                 |
| ---------- | ------------------------------------------------------------------------------------- |
| 2026-06-06 | `nix flake update` run; nixpkgs pinned to `331800de` (2026-05-31)                     |
| 2026-06-06 | `nixos-rebuild boot --flake .#cypher-nixos` issued                                    |
| 2026-06-06 | Build fails; `python3.13-pipx-1.8.0.drv` reported as the root failure                |
| 2026-06-06 | Log analysis identifies 7 failing tests in `test_package_specifier.py`                |
| 2026-06-06 | Root cause confirmed: whitespace normalization regression in pipx 1.8.0 test suite    |
| 2026-06-06 | Overlay approach attempted (`doCheck = false`) but placed in wrong evaluation context |
| 2026-06-06 | Decision made to comment out `pipx`; system rebuilds successfully                    |

---

## Impact

- **Components affected:** `modules/apps/dev/hm.nix` — `pipx` removed from dev tooling
- **Data affected:** None
- **Time lost:** ~1.5 hours (diagnosis + failed overlay attempt + resolution)
- **Work affected:** `pipx` unavailable as a system package until re-enabled post upstream fix. Not actively needed for any current project.

---

## Root Cause

`pipx-1.8.0` introduced a change to package specifier whitespace formatting — output now emits PEP 508-compliant spacing (`package @ url`) where tests expected the old no-space format (`package@ url`). The test suite was not updated to match the new output, causing 7 assertions to fail in `test_package_specifier.py`. Nix runs the test suite as part of the build, so the derivation fails.

The nixpkgs rev `331800de` (2026-05-31) contains `pipx-1.8.0` with the broken tests. The fix — adding the affected tests to `disabledTests` — is already merged in nixpkgs `master` but had not yet propagated to `nixos-unstable` at the time of the incident.

The failure cascades because `pipx` is an explicit package in the Home Manager closure. Its derivation failure blocks `home-manager-path`, which blocks `home-manager-generation`, which blocks the entire NixOS system closure.

---

## Resolution

`pipx` commented out of `modules/apps/dev/hm.nix` with an explanatory comment:

```nix
# pipx  # TEMP: disabled 2026-06-06 — pipx 1.8.0 test suite broken at nixpkgs rev
#        331800de. Fix already merged in nixpkgs master (disabledTests).
#        Re-enable after next `nix flake update` advances nixos-unstable past the fix.
```

System rebuilt successfully after removal.

### Changes Made

| Type   | Reference                           | Description                                     |
| ------ | ----------------------------------- | ----------------------------------------------- |
| Config | `modules/apps/dev/hm.nix`           | `pipx` commented out with dated explanation     |
| Config | `flake.nix`                         | Overlay attempt removed (was in wrong location) |

---

## Contributing Factors

- `nixos-unstable` channel lag — fixes merged to `master` do not immediately reach the unstable channel. A package can be broken on unstable while the fix already exists upstream.
- `pipx` was an explicit package declaration with no version pin, so a channel update silently picked up 1.8.0.
- The attempted overlay fix was placed in the top-level `let pkgs = ...` binding in `flake.nix`, which only affects standalone `homeConfigurations`. The `nixosSystem` path instantiates its own `pkgs` internally — overlays must go into `nixpkgs.overlays` within the NixOS module system to reach that path. This evaluation context split is a recurring footgun.

---

## Prevention

- **For this specific issue:** Re-enable `pipx` after the next `nix flake update` once nixos-unstable advances past the fix commit. No permanent mitigation needed.
- **General pattern — flake update regressions:** Before a `nix flake update`, consider checking `nixpkgs` changelog or commit log for packages in your explicit closure that may have had recent version bumps. Not always practical, but worthwhile before large rebuilds.
- **Overlay placement:** Document the two-pkgs-instantiation model in project conventions. The top-level `let pkgs` in `flake.nix` is for standalone HM only. NixOS-integrated overlays go in `nixpkgs.overlays` (NixOS module system). This distinction cost ~30 minutes here.

---

## Lessons Learned

`nixos-unstable` is a point-in-time snapshot, not a rolling guarantee of working packages. Any `nix flake update` can introduce a broken package that blocks the entire closure. The correct response hierarchy is:

1. Check if the fix is already upstream and a subsequent `flake update` will resolve it — if so, the cheapest fix is to temporarily remove or stub the package.
2. Apply a targeted overlay (`doCheck = false`, `disabledTests`, or version pin) if the package is actively needed.
3. Pin nixpkgs to a known-good rev as a last resort.

In this case option 1 was correct. The package was not actively in use, the fix was already merged upstream, and the workaround cost was zero.

---

<!-- METADATA
Opened: 2026-06-06
Resolved: 2026-06-06
Related journal entry: [2026_06_06_nixos_rebuild_and_catppuccin_migration](../journal/2026_06_06_nixos_rebuild_and_catppuccin_migration.md)
-->
