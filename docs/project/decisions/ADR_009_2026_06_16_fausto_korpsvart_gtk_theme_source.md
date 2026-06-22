# ADR_009_2026_06_16: Fausto-Korpsvart as the Catppuccin GTK Theme Source

**Date:** 2026-06-16  
**Status:** Accepted  
**Deciders:** CypherWhisperer

---

## Context

CypherOS requires a GTK theme that applies Catppuccin Mocha Mauve colouring consistently across GTK3, GTK4, and libadwaita applications on GNOME. The theming stack must satisfy three requirements:

1. **GTK3 coverage** — legacy GNOME apps, LibreOffice (via `SAL_USE_VCLPLUGIN=gtk3`), Nautilus widget chrome.
2. **GTK4 / libadwaita coverage** — GNOME Text Editor, Settings, and any app built on libadwaita. This is the hard requirement: libadwaita ignores the GTK theme name set in `org.gnome.desktop.interface gtk-theme` and reads CSS directly from `~/.config/gtk-4.0/gtk.css`. The theme package must ship libadwaita-targeted CSS that overrides the custom properties (`--accent-bg-color`, `--accent-fg-color`, `--accent-color`, etc.) libadwaita exposes for theming.
3. **Active maintenance** — the theme must track upstream GNOME and libadwaita releases. A theme that has not been updated for libadwaita's evolving CSS API will produce visual regressions as GNOME advances.

The previously used theme source (`pkgs.catppuccin-gtk` in nixpkgs, upstream: `catppuccin/gtk`) was archived by the Catppuccin organisation in 2024. The nixpkgs package remains available but receives no upstream updates. Testing confirmed it does not override libadwaita's CSS custom properties, meaning GTK4 and libadwaita apps receive only dark-mode defaults, not true Catppuccin colours.

---

## Decision

CypherOS will use **Fausto-Korpsvart's Catppuccin GTK Theme** (`github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme`) as the GTK theme source, packaged from source via a custom `pkgs.stdenvNoCC.mkDerivation` derivation that compiles the SCSS at build time using `sassc`.

---

## Reasoning

Fausto-Korpsvart's theme is the only actively maintained Catppuccin GTK port that explicitly targets libadwaita's CSS custom property API. Its `install.sh` compiles SCSS sources that set `--accent-bg-color`, `--accent-fg-color`, and the full libadwaita colour token set to Catppuccin palette values — the mechanism required to colour libadwaita apps beyond dark-mode defaults.

Packaging from source (rather than fetching a pre-built release tarball) was chosen for two reasons: the repository ships SCSS source as the canonical artifact (pre-built releases may lag behind source), and compiling at derivation build time means the output is fully reproducible given a pinned `rev` and `sassc` version. The build is captured in the Nix store and referenced by store path in downstream HM module options — no mutable state, no runtime side effects.

---

## Alternatives Considered

### `pkgs.catppuccin-gtk` (nixpkgs, upstream: `catppuccin/gtk`)

The archived upstream package. Available in nixpkgs but unmaintained. Does not target libadwaita CSS custom properties — GTK4/libadwaita apps receive GNOME's default colour scheme rather than Catppuccin colours. Rejected because it fails requirement 2 (libadwaita coverage) and requirement 3 (active maintenance).

### Pre-built release tarball from Fausto-Korpsvart releases

`fetchurl` against a versioned `.tar.gz` from the GitHub releases page would avoid the `sassc` build dependency and reduce derivation complexity. Rejected because releases may lag the source tree, and `fetchFromGitHub` against a pinned commit is equally reproducible with the added benefit of always reflecting the canonical SCSS source. Build time overhead is acceptable given theming is a one-time build artifact.

### `adw-gtk3` + native libadwaita dark mode

`adw-gtk3` backports the libadwaita look to GTK3 apps and pairs well with `color-scheme = "prefer-dark"` for a consistent dark GNOME experience. Rejected because it produces generic GNOME dark styling, not Catppuccin colours. Suitable as a fallback aesthetic but does not satisfy the Catppuccin Mocha Mauve requirement.

---

## Consequences

**Positive:**

- Full Catppuccin Mocha Mauve colouring across GTK2, GTK3, GTK4, and libadwaita applications — the only approach that satisfies all three requirements.
- Derivation output is immutable and store-resident; theme assets are referenced by store path, not `~/.themes` mutable state.
- `sassc` is the only build-time dependency — a lightweight addition.
- Theme updates are a `rev` + `hash` bump in `theming.nix` — fully controlled and auditable.

**Negative / Trade-offs:**

- Adds a custom derivation that must be maintained when the upstream install script changes its CLI interface or directory structure. This session required four build iterations to resolve sandbox incompatibilities (`install.sh` location, short vs long flag names, `BATCH_MODE` for non-interactive execution).
- `rev = "HEAD"` is currently used for iteration convenience. This is non-reproducible across time and must be pinned to a specific commit once the theme is confirmed visually stable. Until then, two builds at different dates may produce different output.
- The `--libadwaita` flag (which symlinks `gtk-4.0/` into `$HOME/.config/`) is intentionally omitted from the derivation — it is incompatible with the Nix sandbox. GTK4 asset delivery is handled manually via `xdg.configFile."gtk-4.0/assets"` and HM's automatic `gtk.css`/`gtk-dark.css` write from `gtk.gtk4.theme`.

**Neutral / Operational:**

- When updating the theme, run `git rev-parse HEAD` in the cloned repo to obtain the new rev, then update `rev` and `hash` in `theming.nix`. Use `--rebuild` on the first build after a rev change to bypass Nix's cached derivation result.
- The `BATCH_MODE=true` environment variable must remain set in `installPhase` to suppress the interactive "apply Vague?" prompt that fires after installation. This is the script author's official non-interactive escape hatch.