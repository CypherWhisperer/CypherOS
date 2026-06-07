# 2026-06-05 — DevLog Bootstrap & nix-direnv Version Lag Discovery

<!--
The journal is informal. This is the human layer on top of git history.
Write like you're explaining the session to yourself six months from now.
What happened, what you figured out, what you're still unsure about.
Honest > polished.
-->

**Date:** 2026-06-05
**Duration:** ~4 hours
**Repos touched:** `devlog`, `CypherOS`
**Modules touched:** `modules/apps/dev/devenv.nix`
**Phase:** Phase 1 — Dev Tooling Stability

---

## What I Worked On

Bootstrapped the DevLog project — a multi-user PHP developer journal application that serves as the university internet programming capstone — and worked through three successive `direnv`/flake evaluation failures that blocked the environment from activating automatically. The session ended with the flake proven correct via `nix develop --impure`, `composer install` succeeding, and a clear diagnosis that the remaining `direnv` automation failure is a CypherOS-side version lag, not a DevLog problem.

---

## What Got Done

- Scaffolded the full DevLog repository: `flake.nix` + `devenv.nix` (LAMP stack — Caddy + PHP-FPM 8.3 + MariaDB + Adminer), PSR-4 PHP skeleton (`src/`, `views/`, `public/`), `database/schema.sql`, `composer.json`, `.env.example`, `.gitignore`, full `docs/` tree
- Established `public/` as the Caddy document root (front controller pattern — all requests enter `public/index.php`; `vendor/`, `src/`, `.env` structurally outside the web root)
- Wrote `flake.nix` as an explicit owner of inputs rather than delegating to `devenv.yaml` — `devenv.nix` stays as a portable module, flake is the outer wrapper
- Switched nixpkgs input from `nixos-unstable` to `github:cachix/devenv-nixpkgs/rolling` per devenv's own recommendation — avoids evaluation mismatches between devenv's internal modules and the nixpkgs version in use
- Diagnosed and worked through three successive flake/direnv failures (detailed below)
- Confirmed the flake is correct: `nix develop --impure` produced the DevLog banner, `composer install` locked and installed all 7 dependencies (`vlucas/phpdotenv`, `cebe/markdown`, and their transitive deps)
- Identified the root cause of the remaining `direnv` automation failure as a CypherOS `nix-direnv` version lag — not a DevLog issue
- Identified the CypherOS fix: `nix flake update && sudo nixos-rebuild switch` in CypherOS to pull `nix-direnv` ≥ 3.0.7

---

## Key Decisions Made

**DevLog gets its own repository, not a subdirectory of nixamp.** nixamp is for throwaway course exercises. DevLog is a structured application with its own git history, documentation, and dependency tree. Conflating them would mix commit histories and require conditional logic in a shared `devenv.nix`. Clean separation now; shared template extraction planned as a future ROADMAP item.

**Explicit `flake.nix` over `devenv.yaml`.** `devenv.yaml` wraps an internal flake devenv manages on your behalf. Writing `flake.nix` gives ownership of input pins, produces a `flake.lock` that is auditable, and positions the environment for future extraction into a reusable LAMP template. The `devenv.nix` module is unchanged — the flake is purely the outer wrapper. `.envrc` uses `use flake`.

**`devenv-nixpkgs/rolling` as the nixpkgs input for devenv projects.** devenv ships its own tested nixpkgs track. Using `nixos-unstable` with `follows` can cause subtle mismatches where devenv's internal PHP/MariaDB/Caddy module APIs expect a package version that doesn't exist in the pinned nixpkgs commit. `devenv-nixpkgs/rolling` is the path of least resistance and what devenv's own documentation shows.

**`nix develop --impure` as the unblocking fallback while CypherOS is updated.** Not a permanent solution — just a way to work in the devenv shell without the `direnv` automation while the host tooling version lag is resolved.

---

## Where I Got Stuck

Three successive failures, each with a different root cause. Worth documenting precisely because the error messages were misleading.

### Failure 1 — `devenv was not able to determine the current directory`

**Symptom:**
```
error: Failed assertions:
- devenv was not able to determine the current directory.
  See https://devenv.sh/guides/using-with-flakes/ how to use it with flakes.
```

**Initial diagnosis (wrong):** Assumed `devenv.lib.mkShell` needed `self` passed to resolve the project root. This is true for newer devenv versions.

**Fix attempted:** Added `self` to both the `outputs` function arguments and the `inherit` line in `mkShell`:
```nix
outputs = { self, nixpkgs, devenv, ... } @ inputs:
  devenv.lib.mkShell { inherit inputs pkgs self; ... };
```

**Result:** Broke with a new error.

---

### Failure 2 — `function 'mkEval' called with unexpected argument 'self'`

**Symptom:**
```
error: function 'mkEval' called with unexpected argument 'self'
at «github:cachix/devenv/f693b472...»/flake.nix:192:11:
```

**Diagnosis (correct):** The `self` argument to `mkShell` was added in a *newer* devenv version than what was pinned in `flake.lock` (`f693b472`). The pinned version's `mkEval` function signature does not include `self` and rejected it as unexpected. My fix was correct for current devenv but wrong for the version actually in use.

**Fix:** Removed `self`, switched nixpkgs input to `devenv-nixpkgs/rolling`, removed `nixpkgs.follows` (devenv manages its own nixpkgs alignment on the rolling track), added `nixConfig` block with devenv's cachix substituter, ran `nix flake update` to pull current devenv and regenerate `flake.lock`.

```nix
inputs = {
  nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
  devenv.url = "github:cachix/devenv";
  # no follows — devenv-nixpkgs/rolling is already aligned
};

nixConfig = {
  extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
  extra-substituters = "https://devenv.cachix.org";
};

outputs = { self, nixpkgs, devenv, ... } @ inputs:
  devenv.lib.mkShell { inherit inputs pkgs; modules = [ ./devenv.nix ]; };
```

**Result:** `nix flake update` and `direnv allow` ran without error. But `composer` still wasn't available in new terminals.

---

### Failure 3 — `--no-warn-dirty: command not found` (the real root cause)

**Symptom:** Every `cd` into the project directory triggered:
```
/home/cypher-whisperer/.config/direnv/lib/hm-nix-direnv.sh:41: --no-warn-dirty: command not found
direnv: nix-direnv: Evaluating current devShell failed. Falling back to previous environment!
```
`DEVENV_ROOT` was empty. `composer` not in PATH. The direnv shell never actually built.

**Diagnosis:** `nix-direnv` 3.0.7 (released May 2025) removed `--no-warn-dirty` from its internal `nix` calls, as the flag had been dropped from Nix itself. The `nix-direnv` version HM was providing from CypherOS's nixpkgs pin was older than 3.0.7 and still emitted the flag. Current Nix doesn't recognise it, the command fails, nix-direnv falls back to a stale or nonexistent environment, and the devenv shell never activates via direnv.

**Key insight:** This is not a DevLog problem. The `flake.nix` is correct. The direnv integration layer — `~/.config/direnv/lib/hm-nix-direnv.sh` — is generated by Home Manager from CypherOS's nixpkgs pin, entirely outside the project. The flake's reproducibility guarantee covers what it builds; it does not and cannot control the version of the host tooling that invokes it.

**Confirmed the flake is correct:** `nix develop --impure` bypasses `nix-direnv` entirely, evaluates the flake directly, and drops into the devenv shell. Banner displayed, `composer install` succeeded.

**Fix (in CypherOS, not DevLog):**
```bash
# In CypherOS flake directory:
nix flake update
sudo nixos-rebuild switch --flake .
# HM will regenerate hm-nix-direnv.sh from nix-direnv >= 3.0.7
# --no-warn-dirty is gone, direnv automation will work correctly
```

---

## What I Learned

**The `self` argument in `devenv.lib.mkShell` is version-gated.** It was added to help devenv resolve the project root in newer releases. Older devenv versions (pre the version that added it) will reject `self` as an unexpected argument. When hitting `devenv was not able to determine the current directory`, the correct first step is to check the devenv version before assuming the API signature, not to blindly add `self`.

**`devenv.yaml` vs `flake.nix` is an ownership question, not a capability question.** Both produce the same devShell. The difference is whether you own the input pins or devenv does. For a single project, the functional difference is small. For composability and future template extraction, owning the flake is strictly better. The `devenv.nix` module is portable either way — the flake is just the wrapper.

**`devenv-nixpkgs/rolling` exists for a reason.** devenv validates its PHP, MariaDB, and Caddy module integrations against this track. Using `nixos-unstable` with `follows` can introduce subtle API mismatches. For devenv projects, use `devenv-nixpkgs/rolling` as the nixpkgs input.

**The `nixpkgs.follows` pattern and when NOT to use it.** In CypherOS, `follows` is used to ensure all flake inputs evaluate against the same nixpkgs, avoiding binary cache misses and version mismatches. For devenv specifically, `devenv-nixpkgs/rolling` is already a curated track — devenv manages its own alignment. Forcing `follows` to point it at `nixos-unstable` can break that alignment. The general principle holds; the specific application depends on whether the input has its own curated track.

**The direnv integration layer is outside the flake's reproducibility guarantee.** A flake guarantees what it builds given a `flake.lock`. It does not control the version of `nix-direnv` on the host that invokes it. This is an accepted, documented assumption — `nix-direnv` has its own minimum Nix version requirement. In a personal NixOS setup (all machines running CypherOS), this is manageable. The failure mode is a version lag in CypherOS's nixpkgs pin, not a flaw in the project's design.

**`nix develop --impure` is a reliable fallback and a diagnostic tool.** When `direnv` is misbehaving, `nix develop --impure` bypasses the entire integration layer and evaluates the flake directly. If it works, the flake is correct and the problem is in the host tooling. If it also fails, the problem is in the flake itself.

**Incident vs journal distinction.** This session surfaced a version lag that blocked development tooling automation. Nothing was running, nothing broke, no data was at risk — it was a setup issue encountered during initial configuration. That's a journal entry, not an incident. The incident bar is: something that was supposed to be working stopped working, required emergency response, or put something at risk.

---

## Open Questions

- After `nixos-rebuild switch` updates `nix-direnv` to ≥ 3.0.7 in CypherOS, does `direnv allow` need to be re-run in DevLog, or does the cached `.direnv/` profile survive the HM activation? Likely needs a fresh `rm -rf .direnv/ && direnv allow` since the `hm-nix-direnv.sh` path changes.
- The `nix develop --impure` warning `Git tree is dirty` appears because uncommitted files exist. This is cosmetic and expected during active development, but worth understanding: `--impure` is required here because devenv uses `config.devenv.root` which references the local filesystem path, making the evaluation impure by definition. Is there a way to make this pure, or is `--impure` always required for devenv flakes?
- CypherOS's `nix-direnv` version lag suggests the nixpkgs pin may be behind in other ways too. Worth checking whether a `nix flake update` on CypherOS is overdue and what else has drifted.

---

## Next Session

- Run `nix flake update && sudo nixos-rebuild switch` in CypherOS to fix `nix-direnv` version lag
- Verify `direnv` auto-activation works after the rebuild: `rm -rf .direnv/ && cd .. && cd DEVLOG` — should see DevLog banner without `nix develop --impure`
- With services running (`devenv up`) and shell active: run `dl-migrate` and `dl-status`
- Open `http://localhost:8080` — smoke test that PHP executes and the front controller responds
- If smoke test passes, move to Milestone 2: Auth (register, login, session hardening)

---

<!--
Commit range (fill in after session):
CypherOS: [short hash] → [short hash]
devlog: [initial commit] → [short hash]
-->
