# Temptress (Godot project)

This folder is the **live Godot 4.6 project**. Open `project.godot` here.

Repo-level map, hubs, autoloads, and enemy list: [../../README.md](../../README.md)

## Play

- Godot 4.2+ (project features: 4.6)
- F5 / Play
- Entry scene: `scenes/MainMenu.tscn`
- Combat input: **SPACE** or click when a note hits the line

## Hit ratings

| Rating | Timing window | Points |
|--------|--------------|--------|
| PERFECT | ±80ms | 300 × combo |
| GOOD | ±150ms | 100 × combo |
| OK | ±220ms | 50 |
| MISS | outside window | 0, combo reset |

## In this folder

| Path | What |
|---|---|
| `scenes/` | Boot, town, board, home, combat, VN fallback |
| `scripts/` | Gameplay + hubs |
| `scripts/data/` | Catalogs, save, generated quests, copy |
| `audio/` `backgrounds/` `enemy_images/` `vn_portraits/` `ui_art/` | Runtime assets |
| `README_PHASE*.md` | Historical phase notes |
| `README_SUBTITLES.md` | Combat subtitle markup |
| `addons/godot_ai/` | Editor AI helper plugin |

Do not treat the git repo root as a Godot project.
