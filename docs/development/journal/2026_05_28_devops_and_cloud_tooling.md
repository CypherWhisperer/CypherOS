# [2026-05-28] DevOps + Cloud Computing Setup — Phase 2 Expansion

**Date:** 2026-05-28
**Duration:** ~2 hours
**Repos touched:** [ `cypher-system` ]
**Modules touched:**
- `modules/devops/options.nix`
- `modules/devops/system.nix`
- `modules/devops/containers.nix`
- `modules/devops/kubernetes.nix`
- `modules/devops/iac.nix`
- `modules/devops/databases.nix`
- `modules/devops/secrets.nix`
- `modules/devops/cloud.nix` _(new)_
- `modules/devops/observability.nix` _(new)_
- `modules/devops/networking.nix` _(new)_
- `modules/devops/cicd.nix` _(new)_

**Phase:** Phase 2 — Infrastructure

---

## What I Worked On

Progressive expansion of the `cypher-os.devops.*` module subtree to support cloud computing and DevOps learning workflows. The session was primarily architectural — reviewing the current setup against a structured learning progression (_Linux → Containers → IaC → Cloud → Kubernetes → CI/CD → Observability_), identifying gaps, and filling them with new submodules.

---

## What Got Done

- **`options.nix`** — extended with four new top-level namespaces: `cloud.*`, `observability.*`, `networking.*`, `cicd.*`, each with per-component sub-flags
- **`system.nix`** — wired all new submodule files into the import list
- **`containers.nix`** — documented the `dockerCompat = false` decision explicitly; trimmed verbose inline comments in favour of the three-header convention
- **`kubernetes.nix`** — added `k9s` (the most-used daily k8s TUI tool, previously missing); applied three-header convention to deferred tools
- **`iac.nix`** — removed duplicate `tflint` entry; applied three-header convention
- **`databases.nix`** — added `pgvector` (PostgreSQL vector extension for AI/ML workloads) and `clickhouse` (columnar OLAP DB; CLI only, server via Docker); corrected DEFERRED/EXCLUDED comment for MongoDB
- **`secrets.nix`** — removed misclassified `mkcert` (moved to `networking.nix`); retained `bws` with updated rationale
- **`cloud.nix`** _(new)_ — AWS (awscli2, eksctl, aws-vault), Azure (azure-cli), GCP (google-cloud-sdk) with independent per-provider enable flags; `awslogs` excluded (unmaintained, incompatible with awscli2 — replaced by `aws logs tail`)
- **`observability.nix`** _(new)_ — full PLG stack: Prometheus + node exporter + Grafana + Loki + Promtail; automatic Grafana datasource provisioning; Grafana on port 3001 to avoid collision with dev servers
- **`networking.nix`** _(new)_ — Caddy (`auto_https off` for local dev) + Traefik (Docker provider, insecure dashboard) + `mkcert`; Traefik docker group membership
- **`cicd.nix`** _(new)_ — `gh`, `act`, `actionlint`; self-hosted runner DEFERRED pending sops-nix activation
- **Documentation** — source file docs written for `cloud.nix`, `observability.nix`, `networking.nix`, `cicd.nix`
- **Templates** — updated source-file-doc template (added `options.nix` coverage + Comment Convention section); updated journal template (added **Modules touched**); adapted runbook template for CypherOS (Host, Module, Trigger fields; removed haddassah-core references)

---

## Key Decisions Made

- **`awslogs` excluded** in favour of `aws logs tail --follow` built into `awscli2`. The upstream tool is unmaintained and botocore-incompatible with v2.
- **`mkcert` reclassified** from `secrets.nix` to `networking.nix`. TLS certificates for local dev are transport layer infrastructure, not application secrets.
- **Three-header inline comment convention adopted** (`DEFERRED` / `EXCLUDED` / `PENDING`) across all devops submodules. One-line reasons in source; full rationale in documentation files.
- **`dockerCompat = false`** explicitly set and documented in `containers.nix`. Having both Docker and Podman active with a compat shim creates ambiguity; the explicit `false` makes the decision visible.
- **Grafana port 3001** to avoid collision with Next.js and other dev servers on 3000.
- **Promtail conditioned on `loki.enable`**, not a separate flag — no useful state exists for Loki-on + Promtail-off in a local dev context.

---

## Where I Got Stuck

- `awslogs` appeared in research notes as a recommended CloudWatch log streaming tool. Investigation revealed it is unmaintained upstream and incompatible with `awscli2`'s botocore. Resolved by documenting `aws logs tail` as the built-in replacement.
- `google-cloud-sdk` on NixOS has a known component management limitation (`gcloud components install` is disabled by the package manager). Documented in source and module docs rather than working around it.

---

## What I Learned

- The observability stack (Prometheus + Grafana + Loki) has mature NixOS module support. Automatic Grafana datasource provisioning via `services.grafana.provision.datasources` eliminates the need for manual UI configuration after every rebuild.
- Loki's BoltDB-shipper backend (used here) is deprecated upstream in favour of TSDB. Acceptable for a local learning lab; worth revisiting before any production-adjacent use.
- `act` (nektos) is in nixpkgs under the attribute name `act`. Its primary limitation on NixOS is the absence of systemd inside Docker containers — workflows that manage systemd units will fail locally even if they pass on GitHub.

---

## Open Questions

- Should Traefik be the default ingress for k3s (replacing the bundled Traefik that k3s ships)? The `--disable traefik` flag is already in the kubernetes.nix comment but not yet enabled. Worth aligning once the k3d/kind learning phase begins.
- Is there a reason to enable `cloud.*` sub-flags in the profile defaults, or should cloud CLIs remain opt-in per-host? Currently all `cloud.*` flags default to false.
- The `services.promtail` NixOS module status should be verified — as of 25.05 it may have been renamed or restructured.

---

## Next Session

- Activate sops-nix in `flake.nix` (currently blocked by the commented-out `sops` block in `secrets.nix`)
- Wire `cloud.aws.enable = lib.mkDefault true` into the profile if AWS learning begins
- Confirm `services.promtail` module name against the pinned nixpkgs revision before first rebuild
- First rebuild with the new modules; verify no evaluation errors

---

<!--
Commit range (fill in after session):
cypher-system: [short hash] → [short hash]
-->
