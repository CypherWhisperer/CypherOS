# Architecture Decision Records

ADRs document significant decisions made during the design and development of CypherOS — what was decided, why, what alternatives were considered, and what the consequences are.

Each ADR is a permanent record. Once accepted, an ADR is not deleted — it may be superseded by a later ADR, which references it.

---

## Index

| ADR                                                       | Date       | Status   | Decision                                                   |
| --------------------------------------------------------- | ---------- | -------- | ---------------------------------------------------------- |
| [ADR-001](./ADR_001_cypher-os_namespace_design.md)        | 2026-04-15 | Accepted | `cypher-os` Namespace Design                               |
| [ADR-002](./ADR_002_gnome_module_isolation.md)            | 2026-04-15 | Accepted | GNOME Module Isolation                                     |
| [ADR-003](./ADR_003_swap_activation.md)                   | 2026-04-15 | Accepted | Swap Activation                                            |
| [ADR-004](./ADR_004_zram_setup.md)                        | 2026-04-15 | Accepted | ZRAM Setup                                                 |
| [ADR-005](./ADR_005_module_architecture.md)               | 2026-04-16 | Accepted | Module Architecture — Three-File Split Convention          |
| [ADR-006](./ADR_006_global_theming_via_catppuccin_nix.md) | 2026-06-06 | Accepted | Centralized and Global Theme Management via catppuccin/nix |

---

## Statuses

|Status|Meaning|
|---|---|
|**Proposed**|Under consideration — not yet implemented|
|**Accepted**|Decision made and implemented|
|**Deprecated**|Was accepted; no longer applies to the current system|
|**Superseded**|Replaced by a later ADR (noted in the document)|

---

## Template

→ [`docs/templates/adr/ADR-000-template.md`](../../templates/adr/ADR_000_template.md)
