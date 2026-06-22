# [2026-06-16] Catppuccin Mocha Mauve — Full GNOME Theming Pass

<!-- The journal is informal. This is the human layer on top of git history. Write like you're explaining the session to yourself six months from now. What happened, what you figured out, what you're still unsure about. Honest > polished. -->

**Date:** 2026-06-16  
**Duration:** ~4 days (multi-session, 2026-06-16 → 2026-06-20)  
**Repos touched:** [`CypherWhisperer/CypherOS`]  
**Modules touched:**

- `modules/profile/default.nix`
- `modules/de/gnome/theming.nix`
- `modules/apps/terminal/kitty.nix`
- `modules/apps/terminal/ghostty.nix`
- `modules/apps/cli/zellij.nix` _(new)_
- `modules/apps/productivity/libreoffice.nix` _(new)_
- `modules/apps/productivity/obs-hm.nix` _(new)_
- `modules/apps/productivity/zathura-hm.nix` _(new)_
- `flake.nix`

**Phase:** 

---

## What I Worked On

The goal was to achieve consistent Catppuccin Mocha Mauve theming across the entire GNOME desktop and all actively used applications. A prior partial implementation had already landed Catppuccin on a handful of apps (Ghostty, VSCode, Thunderbird, Delta, tmux, Neovim) via `catppuccin/nix` with `autoEnable = true`. This session was about closing the remaining gaps — particularly GTK3/GTK4/libadwaita, LibreOffice, OBS, Zathura, and Kitty — and resolving several visible regressions introduced when the initial GTK theming was switched from enforced GNOME dark mode to the Catppuccin stack.

The secondary thread was learning and applying Nix derivation packaging for the first time in the context of a real build — specifically packaging the Fausto-Korpsvart Catppuccin GTK theme from source, which required running a bash-based installer inside the Nix sandbox.

---

## What Got Done

### GTK / libadwaita theming

- **Migrated from `pkgs.catppuccin-gtk` to Fausto-Korpsvart's Catppuccin GTK Theme** (`github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme`). The upstream `catppuccin/gtk` package is archived; the nixpkgs `catppuccin-gtk` derivation reflects this. Fausto-Korpsvart's port is actively maintained and — critically — targets libadwaita's CSS custom properties (`--accent-bg-color`, `--accent-fg-color`, etc.), which the archived upstream did not do. This is what makes GTK4/libadwaita apps actually render Catppuccin colours rather than just dark-mode defaults.
    
- **Packaged the theme from source** via `pkgs.stdenvNoCC.mkDerivation`. The theme ships as SCSS source with an `install.sh` orchestrator that calls `sassc` for compilation. Nix runs this in a sandbox, captures the compiled output (`share/themes/Catppuccin-Mauve-Dark/`) into the store, and the HM `gtk` module references it by store path.
    
- **Resolved the GTK4 warning** (`gtk.gtk4.theme` default change in HM 26.05) by explicitly setting `gtk.gtk4.theme` to match the GTK3 theme. HM now writes `gtk-4.0/gtk.css` and `gtk-4.0/gtk-dark.css` automatically from this package — eliminating the need for separate `home.file` declarations for those two files (which caused a managed-target conflict when both were declared).
    
- **Wired `xdg.configFile."gtk-4.0/assets"`** — the one GTK4 asset HM's gtk module does _not_ copy automatically. This is required for libadwaita button icons and other SVG-based assets to render correctly.
    
- **Set `color-scheme = "prefer-dark"` and `accent-color = "purple"` in dconf** — the former signals libadwaita and GTK4 apps to use their dark variant; the latter sets GNOME 47+'s native accent colour system to the closest built-in to Catppuccin mauve. Together these ensure apps that read `org.gnome.desktop.interface` directly (rather than the CSS) also get consistent colouring.
    
- **Set `org/freedesktop/appearance color-scheme = 1`** at the XDG portal level so flatpak and portal-aware apps also receive the dark signal.
    

### NUR overlay fix

- Fixed a latent `attribute 'nur' missing` evaluation error in `librewolf.nix`. Root cause: the NUR overlay was applied only to the top-level `let pkgs` binding in `flake.nix`, which is used only by `homeConfigurations`. The `nixosConfigurations` path constructs its own internal `pkgs` instance via `nixpkgs.lib.nixosSystem` — that instance never saw the overlay. Fixed by injecting the overlays via `nixpkgs.overlays` as a NixOS module, which applies them to the pkgs instance that both NixOS and the embedded HM share.

```nix
{ nixpkgs.overlays = [
    nix-vscode-extensions.overlays.default
    nur.overlays.default
  ];
  nixpkgs.config.allowUnfree = true;
}
```

Also added `inputs.nixpkgs.follows = "nixpkgs"` to the NUR flake input, which was missing.

### Application theming

- **LibreOffice** — was rendering a pure white UI after the switch away from enforced GNOME dark mode. Fixed by adding `SAL_USE_VCLPLUGIN = "gtk3"` to `home.sessionVariables`, forcing LibreOffice to use the GTK3 rendering backend rather than its own VCL widget system. Once on GTK3 it correctly inherits the system GTK theme. Also resolved indirectly by the GTK3 + libadwaita + `color-scheme = "prefer-dark"` stack landing correctly.
    
- **OBS Studio** — moved from `environment.systemPackages` to `programs.obs-studio` in Home Manager. `catppuccin/nix`'s OBS theming module hooks into `programs.obs-studio` — it has no effect when OBS is installed at the system level. Created `modules/apps/productivity/obs-hm.nix` with plugins (`obs-vkcapture`, `obs-pipewire-audio-capture`, `wlrobs`).
    
- **Zathura** — same root cause as OBS. Was in `environment.systemPackages`; moved to `programs.zathura.enable = true`. Created `modules/apps/productivity/zathura-hm.nix` with vim-style keybindings, scroll/zoom tuning, and sensible defaults. `catppuccin.autoEnable = true` handles the colour injection.
    
- **Kitty** — had a stale Tokyo Night colour palette hardcoded in `settings`. Since `catppuccin/nix` manages all colour keys for Kitty when `programs.kitty` is enabled, the explicit `color0`–`color15`, `foreground`, `background`, `cursor`, tab colour and border colour entries were overriding the catppuccin injection. Stripped all colour keys, keeping only behavioural/UX settings. Also set `wayland_titlebar_color = "background"` so the AdwHeaderBar derives its colour from the terminal background (Mocha Base `#1E1E2E`) rather than libadwaita's system colour — fixes the mismatched title bar.
    
- **GNOME Text Editor** — themed correctly as a side effect of the libadwaita CSS stack landing. No app-specific change required.
    
- **Ghostty title bar** — set `window-theme = "ghostty"` in `programs.ghostty.settings`. Same class of fix as Kitty's `wayland_titlebar_color`.
    

### Remaining TO-GET items enabled via catppuccin/nix

With `autoEnable = true` already set globally and the relevant programs now managed through HM `programs.*` modules, the following received Catppuccin theming automatically: `zathura`, `obs`, `kitty`, `fzf`, `gitui`, `k9s`, `lazygit`, `nushell`, `zellij`. Fish and OhMyREPL were deferred.

### Qt / Kvantum

Added `qt.enable = true`, `qt.platformTheme.name = "kvantum"`, `qt.style.name = "kvantum"`, and `catppuccin.kvantum.enable = true`. This ensures Qt applications on GNOME render with the Catppuccin palette rather than the default Qt style, which looks visually inconsistent in a GTK environment.

---

## Key Decisions Made

**Fausto-Korpsvart over nixpkgs catppuccin-gtk** The nixpkgs package is a wrapper around the archived upstream. Fausto-Korpsvart's theme specifically targets libadwaita CSS custom properties — the decisive factor for GNOME 47+. Chose to package from source rather than use a pre-built release tarball for SCSS-level reproducibility and to maintain a single fetch point as upstream evolves.

**`BATCH_MODE=true` as the non-interactive escape hatch** The install script has an interactive prompt ("Do you want to apply Vague?") near the end of `run_installation()`. Nix sandboxes have no TTY, so `read -rsn3 key` fails with exit code 1. `BATCH_MODE=true` is the script author's intended non-interactive path — sets `MENU_RESULT=1` and skips all menus. Preferred this over piped stdin (`echo "n" | bash install.sh`) as it's semantically correct and uses the official escape hatch.

**`rev = "HEAD"` — acceptable for now, pin later** Using `rev = "HEAD"` means the fetch is not fully reproducible across time — two builds at different dates could pull different code. Acceptable during active theming iteration. Should be pinned to a specific commit once the theme is considered stable. Annotated with a `# TODO: pin to specific commit` comment.

**NUR overlay injection via `nixpkgs.overlays` NixOS module** This is the canonical approach for making overlays available to both NixOS system context and the embedded HM instance. The alternative (passing `pkgs` via `extraSpecialArgs`) can cause subtle conflicts with `home-manager.useGlobalPkgs = true`. The `nixpkgs.overlays` module approach is cleaner and is the pattern nixpkgs itself recommends.

---

## Where I Got Stuck

**Managed target file conflict on `gtk-4.0/gtk.css`** Initially followed advice to uncomment the `home.file."gtk-4.0/gtk.css"` declarations to ensure libadwaita received the CSS. This caused a `Conflicting managed target files: .config/gtk-4.0/gtk.css` assertion. Root cause: HM's `gtk` module automatically writes these files when `gtk.gtk4.theme` is set — declaring them again in `home.file` produced two managers for the same path. Resolution: remove the explicit `home.file` declarations; `gtk.gtk4.theme` is sufficient. Only `xdg.configFile."gtk-4.0/assets"` needs an explicit declaration because the gtk module doesn't copy that directory.

**Nix derivation build — iterative debugging through sandbox constraints** The Fausto-Korpsvart packaging took several build cycles to get right:

1. `bash: install.sh: No such file or directory` — install.sh is in `themes/`, not the repo root. Fix: `cd themes` before invoking it.
2. `Unrecognised option: --accent` — the script only has short flags `-a` and `-m`; `--accent` and `--mode` are not valid long options despite the help text showing both.
3. `Unrecognised option: --a` — a copy-paste error introduced `--a` instead of `-a`. Also complicated by Nix serving cached failed derivation logs; used `--rebuild` to force re-execution.
4. `read -rsn3 key` exit code 1 — the interactive "apply Vague?" prompt at the end of `run_installation()` fails without a TTY. Fixed with `export BATCH_MODE=true`.

Each cycle required `nix log <drv-path>` to surface the actual error, since the top-level build output only shows the last 25 lines.

**NUR overlay scope** The `nur.overlays.default` was applied to the top-level `let pkgs` in `flake.nix` but not to the pkgs instance constructed internally by `nixosSystem`. Took a while to identify that the two pkgs instances are separate and that `nixpkgs.overlays` is the correct injection point for the NixOS context.

---

## What I Learned

**Nix packaging fundamentals — derivations from bash installers** First real hands-on with `mkDerivation`. The mental model: determine what the installer produces, what it needs to produce it, how it runs, then sandbox the execution and capture the output. `stdenvNoCC` is appropriate when there's no C compilation — the builder provides basic shell utilities but no compiler toolchain. `nativeBuildInputs` covers build-time tools (`sassc`); the sandbox has no network access, no TTY, and a fake `$HOME`.

Packaging bash-based installers specifically requires identifying and neutralising:

- Interactive prompts (find `BATCH_MODE`-style escape hatches or pipe stdin)
- Side effects targeting `$HOME` (symlinks, `gsettings` calls) — either neutralise or let them write to the `mktemp -d` fake home and ignore the output
- TTY assumptions (`read`, progress bars, colour codes) — most fail gracefully or can be bypassed via env vars

**The `nixpkgs.overlays` vs `let pkgs` distinction** `nixpkgs.lib.nixosSystem` constructs its own pkgs internally. A `let pkgs = import nixpkgs { overlays = [...] }` binding in `flake.nix` is only used by `homeConfigurations` (the standalone HM path). Any overlay that needs to be visible inside NixOS modules or the embedded HM instance must be injected via the `nixpkgs.overlays` NixOS module option.

**`--rebuild` for derivation iteration** When iterating on an `installPhase` without changing the source hash (`rev = "HEAD"`), Nix considers the derivation unchanged and serves the cached result. `nix build --rebuild` forces re-execution regardless of cache state. Essential when debugging build scripts.

**libadwaita's two-layer theming model** libadwaita ignores the GTK theme name set in `org.gnome.desktop.interface gtk-theme`. It reads CSS from `~/.config/gtk-4.0/gtk.css` directly. The `gtk.gtk4.theme` HM option causes HM to write that file from the specified package — this is the correct hook. Additionally, GNOME 47+ introduced `org.gnome.desktop.interface accent-color` as a native accent system that some apps read directly rather than from CSS. Both layers need to be set for full coverage.

**catppuccin/nix requires `programs.*` module ownership** `catppuccin/nix` hooks into HM's `programs.*` modules to inject theme configuration. If an application is installed via `environment.systemPackages` instead of a HM `programs.*` module, the catppuccin hook has no effect. The pattern: always prefer `programs.<app>.enable = true` in HM for any app you want catppuccin/nix to manage.

---

## Open Questions

- Should `rev = "HEAD"` in the Fausto-Korpsvart derivation be pinned to a specific commit now that theming is stable? The current approach is non-reproducible across time. Revisit after confirming the visual result is satisfactory post-reboot.
  
- The GNOME Shell theme (`org/gnome/shell/extensions/user-theme`) is set to `fkThemeName` via dconf, but the User Themes GNOME extension must be enabled for this to apply. Is this extension declared somewhere in the GNOME module, or is it implicit? Verify.
  
- Fish shell and OhMyREPL were not themed this session. Fish has a breaking change in catppuccin/nix 26.05 (static themes). Revisit when fish is actively configured.
  
- macOS-style window buttons (`--tweaks macos` + `fkThemeName = "Catppuccin-Mauve-Dark-Macos"`) — evaluate aesthetically after confirming the base theme looks correct post-reboot. Two-line change if desired.
  
- Kvantum theming — confirm Qt apps actually render with Catppuccin after rebuild. The `catppuccin.kvantum.enable` + `qt.platformTheme.name = "kvantum"` stack is declared but untested.

---

## Next Session

- Reboot and visually audit the full theme across: GNOME Shell, Nautilus, LibreOffice, GNOME Text Editor, OBS, Zathura, Kitty, Settings, and any Qt apps present.
- Pin `rev = "HEAD"` to a specific commit in the Fausto-Korpsvart derivation if the visual result is satisfactory.
- Begin documentation: ADR for Fausto-Korpsvart packaging decision; update module README for `modules/de/gnome/`.
- Consider the macOS window buttons decision.
- Generate the Nix packaging deep-dive course prompt (drafted this session, pending go-ahead).

---

<!-- Commit range (fill in after session): CypherOS: [short hash] → [short hash] -->