# TEMPTRESS Phase 0 — data model

Lives under `res://scripts/data/` inside `rhythmtap-ui-updated-11/` (Godot picks up `class_name`).

| File | Role |
|------|------|
| `QuestDef.gd` | Guild quest params (length, difficulty, biome, multipliers) |
| `ModifierDef.gd` | Fines / curses for the next run |
| `RunState.gd` | One active attempt + run-only treasure bag |
| `MetaSave.gd` | Persistent meta + save/load (`user://temptress_meta.save`) |
| `EnemyCatalog.gd` | Tier/biome index for generators (GameManager still owns combat stats) |

## Ownership rules
- **GameManager** — single encounter only; reads starting HP/ATK from MetaSave at run start.
- **RoomManager / future QuestRunner** — builds `rooms` from `QuestDef` + `EnemyCatalog`.
- **RunState** — treasure bag; wiped on concede; banked into MetaSave on clear.
- **MetaSave** — level, banked gold, upgrades, receptionist affinity, pending modifiers.

## Autoload (Phase 1)
Register `MetaSave.gd` as autoload `MetaSave`, or a thin wrapper that owns one instance and calls `load_from_disk()` in `_ready`.

## Out of scope here
No scene wiring, no guild UI, no changes to GameManager yet.
