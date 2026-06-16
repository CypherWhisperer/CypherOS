# [2026_06_15] AFFiNE Self-Hosting — Initial Deployment

**Date:** 2026-06-15
**Duration:** ~4 hours
**Repos touched:** `cypher-affine` (new), `CypherOS` 
**Modules touched:** 
    `modules/apps/productivity/affine-system.nix`
    `modules/apps/productivity/affine-hm.nix`
    `modules/apps/productivity/options.nix`
    `modules/profile/system.nix` 
**Phase:** 

---

## What I Worked On

Researched, planned, and deployed a self-hosted AFFiNE instance on CypherOS. Set up the Docker Compose infrastructure stack, wired the NixOS system integration (DNS, CA trust), and connected the desktop app to the local server.

Also discovered and resolved a latent bug in `penpot-system.nix` that had been silently broken since Penpot was first deployed.

---

## What Got Done

- Scaffolded the `affine-cypher` infrastructure repository with `docker-compose.yml`, `.env`, `Caddyfile`
- Deployed AFFiNE v0.26.7 (`:stable`) via Docker Compose on `cypher-nixos`
- Migration job completed cleanly — 5 data migrations, all passing (204s total)
- Admin account created; instance accessible at `https://affine.local`
- Caddy local CA generated; root cert at the expected path under `PERSISTENT_DATA/`
- `affine-system.nix` written and imported into `hosts/nixos/configuration.nix`
- `affine-hm.nix` written; `pkgs.affine` (v0.26.6) installed via Home Manager
- `affine.enable` option declared in `options.nix`
- `cypher-os.apps.productivity.enable = lib.mkDefault true` added to `modules/profile/system.nix` — the fix that unblocked both AFFiNE and Penpot
- `/etc/hosts` now correctly shows `127.0.0.1 affine.local design.penpot.local` after rebuild
- Desktop app connected to `https://affine.local` via the workspace switcher "Add Server" flow
- Infrastructure repository documented: `README.md`, `CHANGELOG.md`, `docs/architecture.md`, `docs/overview.md`, `ADR-001`, `ADR-002`
- CypherOS module docs written: `affine-system.md`, `affine-hm.md`

---

## Key Decisions Made

- **Local-only deployment** — no Cloudflare Tunnel, no internet exposure. Use case is personal knowledge management; no external access required. Migration path to tunnel is low-friction if that changes.
  
- **`pkgs.affine` over AppImage** — AFFiNE is in nixpkgs (nixos-25.05+, v0.26.6, maintained by `@xiaoxiangmoe`). The AppImage approach I initially considered was unnecessary and worse in every respect — no hash management, proper nixpkgs caching, Wayland flags pre-configured.
  
- **Separate Caddy instances deferred** — AFFiNE and Penpot each run their own Caddy binding `:80/:443`. Port conflict is managed manually (bring one stack down before starting the other) until a dedicated CypherOS networking session addresses this with a shared Caddy instance.
  
- **`restart: no` policy** — changed on both AFFiNE and Penpot stacks to prevent Docker from auto-starting conflicting Caddy instances on daemon restart. Stacks are now start-on-demand only.
  
- **`PERSISTENT_DATA` convention** — renamed from `PERSISTENT_INSTANCE_DATA` (the Penpot precedent) before any data was written. Cleaner, less redundant. Applied consistently across the repo and `affine-system.nix`.

---

## Where I Got Stuck

**The `cypher-os.apps.productivity.enable` gap in the system context.**

This consumed the most time. `affine-system.nix` was correctly written, correctly imported, and the option was correctly declared in `options.nix`. But `nixos-rebuild switch` completed without errors and `/etc/hosts` showed nothing. No error, no warning — just silent failure.

The root cause: `productivity.enable = lib.mkDefault true` was only set in `modules/profile/default.nix`, which lives in the Home Manager evaluation context. `affine-system.nix` (and `penpot-system.nix`) are evaluated in the NixOS system context. In the system context, `productivity.enable` was never set — its value was `false` (the option default). The `lib.mkIf` guard evaluated to false on every rebuild. Everything looked correct at a glance; the bug was in understanding the evaluation context boundary.

The fix was one line in `modules/profile/system.nix`:

```nix
cypher-os.apps.productivity.enable = lib.mkDefault true;
```

This also silently fixed `penpot-system.nix`, which had the same problem — `design.penpot.local` was also missing from `/etc/hosts` until this point, meaning the Penpot system integration had been broken since it was first deployed without anyone noticing (Penpot was likely accessed via `localhost` rather than the `.local` domain).

**`update-ca-certificates` not found.**

Hit this trying to manually trust the Caddy CA before doing the Nix rebuild. `update-ca-certificates` is a Debian/Ubuntu tool. NixOS doesn't have it — the trust store is immutable outside of a rebuild. Pivoted immediately to the correct NixOS path: `security.pki.certificateFiles` + `nixos-rebuild switch`.

**Port conflict between AFFiNE and Penpot Caddy instances.**

Both stacks bind `:80` and `:443`. First `docker compose up -d` for AFFiNE failed because Penpot's Caddy was holding the ports (it had come back up automatically on Docker daemon restart due to `restart: unless-stopped`). Resolved by bringing Penpot down first. The structural fix (shared Caddy) is deferred to the networking session.

---

## What I Learned

**NixOS evaluation context is a hard boundary, not a soft one.**

Home Manager context and NixOS system context are completely separate evaluation passes. Options set in one are invisible to the other unless explicitly bridged. `profile/default.nix` (HM) and `profile/system.nix` (NixOS) exist precisely because of this — they're the same conceptual thing split across the boundary. Forgetting to set an option in the system-context profile file means every `lib.mkIf` guard reading that option in system modules silently evaluates to false. No error. No warning. Just nothing happens.

This is the same class of bug that caused split-brain evaluation context issues in earlier CypherOS sessions. The three-file split pattern (`options.nix`, `hm.nix`, `system.nix`) exists to manage this boundary — and the profile files are the place where both sides of the boundary get their defaults. Both sides need to be populated.

**`pkgs.affine` is properly packaged and Wayland-ready.**

The nixpkgs derivation builds AFFiNE from source (not an AppImage), wraps the Electron binary with `makeWrapper` including `--ozone-platform-hint=auto` and `--enable-features=WaylandWindowDecorations`, and is maintained by an active upstream contributor. No extra configuration needed for Wayland. Just `home.packages = with pkgs; [ affine ];` and it works.

**`restart: unless-stopped` has real operational consequences in a multi-stack setup.**

When Docker daemon restarts (after a system reboot, or after manually restarting the service), every container with `restart: unless-stopped` comes back up automatically. In a single-stack setup, this is the right behavior. In a multi-stack setup where two stacks compete for the same ports, it means whichever Caddy loses the port race silently fails. The `restart: no` policy is the correct interim mitigation until the port conflict is resolved structurally.

---

## Open Questions

- What is the correct nixpkgs version alignment check for `pkgs.affine` vs the server image? The nixpkgs package currently lags by one patch version (0.26.6 vs 0.26.7). Is patch-level mismatch safe? Minor-level mismatch (0.25.x vs 0.26.x) is the known risk threshold per upstream docs.
  
- The AFFiNE desktop app stores server connection state in user-local app data (not a declarative config file). Is there a way to pre-configure the server URL declaratively, or is the "Add Server" interactive flow the only path?
  
- When the CypherOS networking session happens: should the shared Caddy instance live in its own infrastructure repository, or as a NixOS module in CypherOS itself?

---

## Next Session

- Docker daemon auto-start issue on CypherOS — separate session, isolated problem
- CypherOS networking session: shared Caddy instance, `systemd-resolved` stub zones (ADR-004 implementation), port registry for all local services
- AFFiNE upgrade runbook (RBK-001) — _scaffold and document before the first upgrade event, not after_

---

<!-- Commit range (fill in after session):
cypher-affine: [initial commit hash] → [short hash] 
CypherOS: [short hash] → [short hash]
-->