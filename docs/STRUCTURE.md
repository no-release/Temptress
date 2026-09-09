# Where files live

Repo root is docs + the Godot project. Open:

`rhythmtap-ui-updated-11/project.godot`

`res://scripts/GameManager.gd` on disk is
`rhythmtap-ui-updated-11/scripts/GameManager.gd`.

## Scenes — all used

Checked `project.godot`, every `.gd` `change_scene_to_file`, and PackedScene instances in `.tscn` files. Nothing in `scenes/` is orphaned.

| Scene | How it is reached |
|---|---|
| `ReceptionistBoot.tscn` | `run/main_scene`. Also from Town and MainMenu. |
| `GuildBoard.tscn` | ReceptionistBoot hub + Town. Accept → Main. Back → Town. |
| `Home.tscn` | ReceptionistBoot hub + Town. Back → Town. |
| `MainMenu.tscn` | ReceptionistBoot hub + Town. Start → ReceptionistBoot. |
| `Main.tscn` | GuildBoard accept, and return from FirstMeetVN. |
| `FirstMeetVN.tscn` | Main, first time an enemy is unmet. Returns to Main. |
| `Town.tscn` | End of combat (clear/concede) and Home back. |
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
| `FirstMeetScenes.gd` | VN page copy. |
| `EncounterLines.gd` | In-fight lines (taunt, drain, rematch…). |
| `ReceptionistGreetings.gd` | Hub greetings by outcome / rank. |
| `SubtitleMarkup.gd` | `[moan]` / `[command]` / … → BBCode. |
| `MetaSave.gd` | Disk-backed meta progress. |
| `ActiveRun.gd` / `RunState.gd` | Current quest. |
