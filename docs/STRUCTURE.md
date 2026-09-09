# Where files live

## Live game

All runtime code and imported assets:

`rhythmtap-ui-updated-11/`

Godot project root = that folder. `res://scripts/GameManager.gd` means
`rhythmtap-ui-updated-11/scripts/GameManager.gd` on disk.

### Scenes

| Scene | Purpose |
|---|---|
| `ReceptionistBoot.tscn` | App entry. Door + contract + hub. |
| `GuildBoard.tscn` | Ranked quest offers. |
| `Town.tscn` | Post-run hub: rank, gold, fines. |
| `Home.tscn` | Meta upgrades. |
| `MainMenu.tscn` | Title card. |
| `FirstMeetVN.tscn` | First-meet pages. |
| `Main.tscn` | Combat. |
| `TreasureScreen.tscn` | Loot / after-fight. |
| `TopHud.tscn` | Combat HUD. |
| `SideHpRail.tscn` | Side HP bars. |
| `DialogueBubble.tscn` | Combat subtitle widget. |
| `EnemyCard.tscn` | Board / UI enemy card. |

### Data scripts

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

## Staging (repo root)

These are **not** loaded by Godot:

```
_art_emotions2_extract/     VN emotion stills (dragoness, troll)
_art_emotions3_extract/     slime / succubus emotions
_art_emotions4_extract/     goblin / slime teasing
_art_hp_combat_extract/     combat poses + HP rail frames
_art_named_extract/         named combat + VN + town/home BGs
_art_troll_kitsune_extract/ kitsune emotions + troll combat
_audio_pack_extract/        music + sfx pack
_audio_scripts_extract/     audio helper scripts
*.tar                       packed copies of the above
```

Treat staging as an inbox. After a file is imported under `rhythmtap-ui-updated-11/`, the staging copy can go.
