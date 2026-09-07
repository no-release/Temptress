# TEMPTRESS Phase 1 — Guild quest → run

## What changed
- **Guild Board** (`scenes/GuildBoard.tscn`): pick length / difficulty / biome, Accept Quest
- **Start** on main menu goes to the guild board
- **QuestGenerator** builds the room list from `QuestDef` + `EnemyCatalog`
- **ActiveRun** + **MetaSave** autoloads carry run state and persistent stats
- **RoomManager** uses ActiveRun’s rooms when present
- **GameManager.begin_encounter** syncs the fight to the quest’s enemy
- Rest/shop rooms auto-skip (tiny heal on rest) so runs don’t softlock
- Clearing the last room banks quest gold into MetaSave

## How to try (GitHub Desktop)
1. Fetch origin, switch to branch `phase1-guild-quest`
2. Open `rhythmtap-ui-updated-11/project.godot` in Godot
3. Play → Start Quest → pick options → Accept

## Merge
Open the PR and click **Merge pull request**, then switch back to `main` and pull.
