# Development Journal

Per-session records of what was built, what was learned, and what decisions were made during development. Each entry is a narrative account of a working session — not just a list of changes (_that's what `CHANGELOG.md` is for_), but the reasoning, the wrong turns, and the understanding arrived at.

---

## Entries

| Date       | Entry                                                                                                                | Summary                                                                                                                                                                                                                     |
| ---------- | -------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-04-15 | [NixOS Migration Session](./2026_04_15_nixos_migration.md)                                                           | Build crash mitigation, ZRAM, options pattern crash course, `gnome.nix` isolation, module architecture three-file split convention                                                                                          |
| 2026-05-16 | [IoT-Arduino Tooling Session](./2026_05_16_arduino_tooling.md)                                                       | IoT Development tooling                                                                                                                                                                                                     |
| 2026-05-25 | [Thunderbird and Proton Bridge setup session](./2026_05_25_thunderbird_setup.md)                                     | Thunderbird Mail Client Setup with proton bridge setup for ProtonMail accounts                                                                                                                                              |
| 2026-05-28 | [DevOps and Cloud Tooling session](./2026_05_28_devops_and_cloud_tooling.md)                                         | DevOps tool box extended to include Cloud computing workflow tools                                                                                                                                                          |
| 2026-06-05 | [DevLog Bootrapping + nix-direnv version lag](./2026_06_06_devlog_bootstrap_and_nix-direnv_version_lag_discovery.md) | Bootstrapping DevLog LAMP (Linux Apache MySQL PHP) project and discovery of `nix-direnv` version lag, during the project's flake built failures.                                                                            |
| 2026-06-06 | [NixOS Rebuild And Catppuccin Migration](./2026_06_06_nixos_rebuild_and_catppuccin_migration.md)                     | Resolving NixOS build failure dure to `python3.13-pipx-1.8.0` failing its own test suite during the Nix build and Migrating Theme management from app-centric management to global management convention via catppuccin/nix |

---

## Template

→ [`docs/templates/journal/YYYY-MM-DD-entry.md`](../../templates/journal/YYYY_MM_DD_entry.md)
