# [2026-05-25] CypherOS Mail Module — Thunderbird + Proton Bridge

<!-- The journal is informal. This is the human layer on top of git history. Write like you're explaining the session to yourself six months from now. What happened, what you figured out, what you're still unsure about. Honest > polished. -->

**Date:** 2026-05-25
**Duration:** ~3 hours
**Repos touched:** `CypherOS`
**Modules touched:**

- `modules/apps/mail/options.nix` _(new)_
- `modules/apps/mail/default.nix` _(new)_
- `modules/apps/mail/thunderbird-hm.nix` _(new)_
- `modules/apps/mail/proton-bridge-hm.nix` _(new)_
- `modules/apps/mail/proton-bridge-system.nix` _(new)_
- `modules/profile/default.nix`
- `hosts/nixos/configuration.nix`

**Phase:** Phase 2 — Applications

---

## What I Worked On

Brought the `modules/apps/mail/` group into existence from scratch — Thunderbird as the email client, Proton Mail Bridge as the local IMAP/SMTP proxy, and the `catppuccin/nix` Thunderbird theme wired to the global flavor/accent SSOT.

Before writing a line of code, spent time working through a documentation architecture question: where do exploratory research notes live relative to per-file module docs? Settled on three distinct document types: research/design notes in Obsidian, per-file docs in the codebase using the established template, and operational runbooks in `docs/runbooks/` in the repo.

---

## What Got Done

- `modules/apps/mail/options.nix` — single options SSOT for the entire mail group: `cypher-os.apps.mail.{enable, thunderbird.*, protonBridge.*}`
- `modules/apps/mail/default.nix` — HM router importing `options.nix`, `thunderbird-hm.nix`, `proton-bridge-hm.nix`
- `modules/apps/mail/thunderbird-hm.nix` — full declarative Thunderbird config: privacy preferences, catppuccin theming, Proton Bridge auth preferences behind `mkIf cfg.protonSupport`, and an assertion gating `protonSupport` on `protonBridge.enable`
- `modules/apps/mail/proton-bridge-hm.nix` — Bridge package + persistent systemd user service with correct `After`/`Wants` ordering on `network-online.target` and `gnome-keyring-daemon.service`
- `modules/apps/mail/proton-bridge-system.nix` — system-level `gnome-keyring` enable and PAM login keyring unlock
- Module docs for `thunderbird-hm.nix`, `proton-bridge-hm.nix`, and `proton-bridge-system.nix` using the established template
- `docs/runbooks/proton-bridge-first-boot.md` — the one-time Bridge initialization ceremony documented step by step
- Wired everything into `modules/profile/default.nix` and `hosts/nixos/configuration.nix`
- Started debugging: first eval run hit an `attribute 'enable' missing` error on `config.cypher-os.apps.enable` in `proton-bridge-system.nix` — traced to a missing import of the parent `apps` options file

---

## Key Decisions Made

**Account configuration intentionally deferred.** Wiring `accounts.email` gains reproducibility but leaks identity into the Nix store and hits the secrets wall immediately. Current scope: declarative preferences and theming only. Revisit when secrets management (sops-nix/age) is in place.

**`catppuccin.*` new namespace used from the start.** The pre-2.0.0 migration moved all modules from `programs.<app>.catppuccin.*` to `catppuccin.<app>.*`. Old aliases exist but will be removed in 2.0.0. Building fresh means starting on the correct side of that line.

**No `thunderbird-system.nix`.** Thunderbird has no system-level concerns. The three-file split is used only when a module genuinely straddles both evaluation contexts — not as a convention to follow mechanically.

**Proton Bridge keychain note documented for future DE migrations.** GNOME Keyring is the supported Secret Service backend on GNOME/NixOS. When Hyprland and KDE Plasma lenses are added to CypherOS, the keyring situation needs a dedicated revisit — KWallet implements the same API but Bridge's compatibility is limited. This is noted in `proton-bridge-hm.md` and the runbook.

---

## Where I Got Stuck

**The `attribute 'enable' missing` eval error.** `proton-bridge-system.nix` imports `./options.nix` which only declares `cypher-os.apps.mail.*`. The parent `cypher-os.apps.enable` is declared in `modules/apps/options.nix` — one level up. Fixed by adding `../options.nix` to the `imports` list in all three new files: `proton-bridge-system.nix`, `proton-bridge-hm.nix`, and `thunderbird-hm.nix`. Caught this during the intentional eval workflow rather than during a full `nixos-rebuild`, which was the point. Build succeeded and Thunderbird is functional.

---

## What I Learned

**`nixos-rebuild` is a pipeline, not a command.** The stages — evaluate, instantiate, build, activate — are independently targetable. `nix eval` catches type errors and assertion failures in seconds. `nix build --dry-run` shows the full build scope without touching the store. `nix store diff-closures` shows what changed before activation. `nixos-rebuild test` activates without writing a boot entry. The REPL is the highest- leverage tool for walking the config tree interactively. The full workflow is now documented and the intention is to use it stage by stage rather than running `nixos-rebuild switch` speculatively.

**Documentation architecture has three distinct layers.** Research notes (Obsidian), per-file module docs (codebase, template-driven), and operational runbooks (`docs/runbooks/`). These are genuinely different document types for genuinely different audiences and moments. Forcing them into one place degrades all three.

---

## Open Questions

- Should `imapPort` and `smtpPort` in `options.nix` be kept as reserved stubs or removed until they can actually be wired into Bridge's runtime config? Currently they're declared but not consumed by anything.
- PAM: is `security.pam.services.login.enableGnomeKeyring` sufficient with GDM, or does `security.pam.services.gdm.enableGnomeKeyring` also need to be set? Untested.
- RFC deferred: adopt `accounts.email` as structural SSOT for eventual multi-client mail config (Thunderbird, `msmtp`, `aerc`), or keep Thunderbird config entirely self-contained? Decision gates on secrets management design.

---

## Next Session

1. Run the first-boot Bridge ceremony (`protonmail-bridge --cli`) and wire the Thunderbird account manually using `127.0.0.1:1143/1025` + Bridge app-password
2. Verify PAM keyring unlock is sufficient with GDM, or add `security.pam.services.gdm.enableGnomeKeyring = true` if Bridge fails to retrieve its token on a fresh boot
3. Decide: keep `imapPort`/`smtpPort` stubs in `options.nix` or remove until they can be properly wired

---

<!-- Commit range (fill in after session):
CypherOS: [short hash] → [short hash]
-->
