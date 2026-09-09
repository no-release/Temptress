# Where files live

Repo root is docs + the Godot project. Open:

`rhythmtap-ui-updated-11/project.godot`

`res://scripts/GameManager.gd` on disk is
`rhythmtap-ui-updated-11/scripts/GameManager.gd`.

## Scenes — all used

Checked `project.godot`, every `.gd` `change_scene_to_file`, and PackedScene instances in `.tscn` files. Nothing in `scenes/` is orphaned.

| Scene | How it is reached |
|---|---|
| `MainMenu.tscn` | `run/main_scene`. Also from the hall. |
| `ReceptionistBoot.tscn` | Title Start, Town/Home bounce, GuildBoard back. |
| `GuildBoard.tscn` | Hall. Accept → Main. Back → hall. |
| `Home.tscn` | Bounces to the hall. |
| `Main.tscn` | GuildBoard accept. |
| `FirstMeetVN.tscn` | Safety-net only. Live path stays on Main combat subtitles. |
| `Town.tscn` | End of combat; bounces to the hall. |
| `TopHud.tscn` | Instanced in Main.tscn. |
| `EnemyCard.tscn` | Instanced in Main.tscn. |
| `SideHpRail.tscn` | Instanced twice in Main.tscn (player + enemy). |
| `DialogueBubble.tscn` | Instanced in Main.tscn (combat subtitle bar). |
| `TreasureScreen.tscn` | Instanced in Main.tscn. |

## Data scripts

| File | Purpose |
|---|---|
| `EnemyCatalog.gd` | Enemy ids, tiers, biomes. |
| `QuestDef.gd` / `QuestGenerator.gd` | Offer + room list generation. |
| `BoardOfferPersist.gd` | Serialize board offers into `MetaSave`. |
| `UpgradeCatalog.gd` | Home shop definitions. |
| `ModifierDef.gd` | Run modifiers. |
| `FirstMeetScenes.gd` | First-meet page copy. |
| `EncounterLines.gd` | In-fight lines (taunt, drain, rematch…). |
| `ReceptionistGreetings.gd` | Hub greetings by outcome / rank. |
| `SubtitleMarkup.gd` | `[moan]` / `[command]` / … → BBCode. |
| `MetaSave.gd` | Disk-backed meta progress. |
| `ActiveRun.gd` / `RunState.gd` | Current quest. |
