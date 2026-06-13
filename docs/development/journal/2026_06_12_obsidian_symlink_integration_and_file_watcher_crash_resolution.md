# 2026_06_12 Obsidian Symlink Integration and File Watcher Crash Resolution

**Date:** 2026-06-12
**Duration:** ~30 minutes
**Repos touched:** [ CypherOS ]
**Modules touched:** [ `modules/apps/productivity/obsidian.nix` ]
**Phase:** 

---

## What I Worked On

Extending the Obsidian vault workflow to support editing repository documentation files directly in Obsidian, with changes propagating back to the source repository in real time.

The mechanism: symlinking repository roots into the vault and relying on `followSymlinks = true` _(already declared in `app` settings)_ to make the repo's directory tree visible to Obsidian.

The immediate goal was CypherOS documentation — _specifically the deeply nested per-module-group `docs/` directories that live alongside their source files rather than in the repo-level `docs/` tree._

---

## What Got Done

- Identified root cause of Obsidian EACCES crash triggered by symlinking CypherOS into the vault (see [INC_2026_06_12_001](../incidents/INC_2026_06_12_001_obsidian_EACCESS_crash_on_symlinked_git_repository.md))
- Added `userIgnoreFilters` to `programs.obsidian.defaultSettings.app` with a comprehensive list covering all current and anticipated development ecosystems
- Rebuilt CypherOS with the new config; Obsidian started cleanly
- Validated the workflow end-to-end: edits made in Obsidian to symlinked `.md` files propagated immediately to the CypherOS repository
- Decided on root-level repo symlinks _(rather than per-subdirectory)_ to preserve the self-contained module documentation convention
- Documented module docs aggregation strategy: `docs/modules/` in the vault mirrors the CypherOS module directory tree, sourced via root symlink

---

## Key Decisions Made

- **Root symlink over subdirectory symlinks.** 
    - CypherOS - _prior to this session_ - kept documentation co-located with source _(each module group has its own `docs/` directory)._
    - Symlinking per subdirectory would require maintaining one symlink per module group and updating that list as the repo grows. 
    - A single root symlink with `userIgnoreFilters` guarding non-documentation directories is cleaner and scales automatically.

- **`userIgnoreFilters` scoped broadly, not minimally.**
    - Rather than adding only `.git` to resolve the immediate crash, the filter list was expanded to cover all development ecosystems likely to be encountered across current and future work: _Node/TS, PHP/Composer, Python, Rust, Go, JVM, Nix/devenv, Docker, and IDEs._
    - Set-and-forget posture — _the list does not need to be revisited per-repository._

- **Vault workflow convention established.** 
    - The vault is the single Markdown editing environment. 
    - Code lives in its repository, documentation is edited via Obsidian through symlinks, and git workflows are executed independently in the respective repository.
    - The obsidian-git plugin in the vault manages only vault-native content, not symlinked repo documentation.

---

## Where I Got Stuck

- The immediate blocker was not the implementation but diagnosing *why* the crash occurred.
- The Obsidian error screen truncated the path, showing only `...CYPHER_OS/res` — _enough to confirm the crash was inside the symlinked repo but not enough to identify the exact file._
- The diagnosis required reasoning about what inside a git repository would produce an EACCES on a watch call: git's pack objects _(`.git/objects/pack/`)_ are intentionally stored read-only _(mode 444)_ by git's own garbage collection, and inotify watch setup requires read permission on the target.
- Once that was clear, the path to the fix was direct.

- A secondary uncertainty was whether `userIgnoreFilters` suppresses the *file watcher* (inotify) or only the search indexer. 
- If it only affected the indexer, the crash would persist. Research confirmed it suppresses both — _the filter is applied during vault traversal at startup, which is the same pass that drives watch registration._

---

## What I Learned

- Git's read-only pack object permissions _(444)_ are intentional and by design — _git does this during `gc` and `repack` to protect object integrity._
    - They are not a NixOS-specific quirk or a permissions misconfiguration. 
    - Any file watcher that follows symlinks into a git repository will encounter this.

- Obsidian's `userIgnoreFilters` operates at the directory traversal level during vault load, not as a post-index filter.
    - This means it prevents watch registration on excluded directories entirely, making it the correct fix for watcher-level crashes — _not just an indexer noise reduction tool._

- The `result` symlink produced by `nix build` points into `/nix/store`, which is a read-only filesystem. If Obsidian were to follow that symlink, it would hit the same class of EACCES failure as `.git`. Added defensively to `userIgnoreFilters`.

- `.devenv/` and `.direnv/` both contain Nix store symlinks and process state. Neither should ever be touched by Obsidian.

---

## Open Questions

- Whether `userIgnoreFilters` matching is exact _(directory name equality)_ or substring within the name component.
    - Needs empirical confirmation — relevant if a future project has a directory like `target-practice` that should *not* be excluded but matches the `"target"` filter entry.

- Whether other repositories to be integrated  introduce any directory names that collide with the current filter list.

---

## Next Session

- Integrate additional repository documentation into the vault using the same root-symlink pattern now that the approach is validated on CypherOS
- Confirm obsidian-git plugin is not attempting to track symlinked repo directories as part of the vault's own git history (potential conflict to audit)

---

<!--
Commit range (fill in after session):
CypherOS: [short hash] → [short hash]
-->