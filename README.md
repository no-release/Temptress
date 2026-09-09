# Temptress

Adult monster-girl rhythm RPG built in **Godot 4.6**.

You walk into a guild, pick a ranked quest, and fight in rhythm-tap combat. First meetings play as combat subtitles while the fight continues. Between runs you bank gold, buy home upgrades, and climb guild ranks E through S.

The Godot application name is still `RhythmTap` (`project.godot`). The game is Temptress.

> Content warning: erotic monster-girl writing, combat dirty talk, submit/drain themes.

## Open this, not the repo root

```
rhythmtap-ui-updated-11/project.godot
```

1. Install Godot 4.2+ (project targets **4.6**).
2. Import that folder.
3. Play. Title scene is `scenes/MainMenu.tscn`; the hall is `scenes/ReceptionistBoot.tscn`.

Window: 1280×720, canvas stretch.

## Repository layout

```
Temptress/
├─ README.md
├─ docs/                     PHASES.md, STRUCTURE.md
├─ .gitignore
├─ .gitattributes
└─ rhythmtap-ui-updated-11/   live Godot project  ← open this
    ├─ project.godot
    ├─ scenes/
    ├─ scripts/               combat, hubs, autoloads
    ├─ scripts/data/          catalogs, save, quest gen, copy
    ├─ audio/
    ├─ backgrounds/  bg_images/
    ├─ enemy_images/  ui_art/  vn_portraits/
    ├─ addons/godot_ai/
    └─ README_PHASE*.md
```

`res://` paths resolve inside `rhythmtap-ui-updated-11/` only. There is no `project.godot` at the git root.

## Scene graph

All 12 scenes under `scenes/` are referenced. None are orphaned.

```
MainMenu.tscn                  project main scene
  └─ Start → ReceptionistBoot.tscn

ReceptionistBoot.tscn          guild hall
  ├─ GuildBoard.tscn           accept quest → Main.tscn
  ├─ Home.tscn                 bounces back to hall
  └─ MainMenu.tscn             title

Main.tscn                      combat
  ├─ instances TopHud.tscn
  ├─ instances EnemyCard.tscn
  ├─ instances SideHpRail.tscn  (×2, player + enemy)
  ├─ instances DialogueBubble.tscn   combat subtitles (also first-meet)
  ├─ instances TreasureScreen.tscn
  └─ run over → hall (Town/Home bounce there too)
```

## Autoloads (`project.godot`)

| Autoload | Role |
|---|---|
| `SoundGen` | Procedural hit/hurt/UI SFX |
| `MetaSave` | Persistent gold, upgrades, rank, met enemies, board offers |
| `ActiveRun` | Current quest rooms + mid-run snapshot |
| `MusicDirector` | Situation BGM + track BPM |
| `FirstMeetBridge` | Legacy VN hand-off (combat path no longer leaves Main) |
| `FontKit` | Readable OFL fonts (Atkinson / Lora / Cinzel) |
| `Phase12CombatUI` / `Phase12CombatLogic` | Combat clarity helpers from phase 12 |
| `DevCheats` | Always-on DEV: forget girls (F9) |
| `_mcp_game_helper` | `addons/godot_ai` runtime helper |

## How a run works

1. Title → receptionist hall. First visit: sign the guild contract (`MetaSave.receptionist_contract_signed`).
2. Guild Board shows 2–4 offers matching your rank (`E` easiest → `S` hardest). Extra slots come from the `board_postings` upgrade.
3. Accept → `QuestGenerator` builds rooms from length / difficulty / biome / enemy tiers.
4. Combat rooms: tap SPACE or click when notes hit the line.
5. Unmet enemy stays in combat; first-meet copy plays on the battle subtitle plate. Met enemies skip to rematch lines from `MetaSave.enemy_last_result`.
6. Rest heals ~35%. Shop can spend quest gold for HP.
7. Clear banks gold and may rank up. Concede can drop rank (~35%) and apply hidden modifiers / level drain.

## Development history

Built as phases 0–13 (PRs #1–#14). Short index is in [`docs/PHASES.md`](docs/PHASES.md).
