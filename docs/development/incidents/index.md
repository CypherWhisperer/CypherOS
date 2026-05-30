# Incidents

Records of significant failures, unexpected behavior, or production-impacting events during development and operation of CypherOS. Each incident is documented with timeline, root cause analysis, resolution, and lessons.

---

## Index

| Incident                                      | Date       | Severity | Summary                                                      |
| --------------------------------------------- | ---------- | -------- | ------------------------------------------------------------ |
| [INC-2026-04-15-001](./INC_2026_04_15_001.md) | 2026-04-15 | High     | OOM build crash — `nixos-rebuild switch` on `nixos-unstable` |

---

## Severity Levels

|Level|Meaning|
|---|---|
|**Critical**|System unbootable or data loss|
|**High**|Development environment unusable; significant work blocked|
|**Medium**|Degraded functionality; workaround available|
|**Low**|Minor inconvenience; no work blocked|

---

## Template

→ [`docs/templates/incident/INC-YYYY-MM-DD-000-template.md`](../../templates/incident/INC_YYYY_MM_DD_000_template.md)
