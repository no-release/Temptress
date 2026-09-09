# Temptress

Adult monster-girl rhythm RPG built in **Godot 4.6**.

You walk into a guild, pick a ranked quest, and fight in rhythm-tap combat. First meetings play as a full-screen visual novel. Between runs you bank gold, buy home upgrades, and climb guild ranks E through S.

The Godot application name is still `RhythmTap` (`project.godot`). The game is Temptress.

> Content warning: erotic monster-girl writing, combat dirty talk, submit/drain themes.

## Open this, not the repo root

```
rhythmtap-ui-updated-11/project.godot
```

1. Install Godot 4.2+ (project targets **4.6**).
2. Import that folder.
3. Play. Main scene is `scenes/ReceptionistBoot.tscn`.

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
ReceptionistBoot.tscn          project main scene
  ├─ GuildBoard.tscn           accept quest → Main.tscn
  ├─ Home.tscn                 back → Town.tscn
  ├─ MainMenu.tscn             Start → ReceptionistBoot.tscn
  └─ (hub also lists those three)

Main.tscn                      combat
  ├─ instances TopHud.tscn
  ├─ instances EnemyCard.tscn
  ├─ instances SideHpRail.tscn  (×2, player + enemy)
  ├─ instances DialogueBubble.tscn   combat subtitles
  ├─ instances TreasureScreen.tscn
  ├─ unmet enemy → FirstMeetVN.tscn → back to Main.tscn
  └─ run over → Town.tscn

Town.tscn                      post-run hub → Board / Home / MainMenu / Boot
```

## Autoloads (`project.godot`)

| Autoload | Role |
|---|---|
| `SoundGen` | Procedural hit/hurt/UI SFX |
| `MetaSave` | Persistent gold, upgrades, rank, met enemies, board offers |
| `ActiveRun` | Current quest rooms + mid-run snapshot |
| `MusicDirector` | Situation BGM + track BPM |
| `FirstMeetBridge` | Hand-off between VN and combat without restarting the run |
| `Phase12CombatUI` / `Phase12CombatLogic` | Combat clarity helpers from phase 12 |
| `_mcp_game_helper` | `addons/godot_ai` runtime helper |

## Scripts worth knowing

```
scripts/
  GameManager.gd          encounter loop, hits, HP, concede / clear
  Main.gd                 combat scene wiring
  BeatBar.gd              scrolling notes + pattern accents
  RoomManager.gd          walk the generated room list
  GuildBoard.gd           ranked offers UI
  Town.gd  Home.gd  MainMenu.gd
  ReceptionistBoot.gd     door / contract / greetings
  FirstMeetVN.gd          typewriter VN
  CombatSubtitle.gd       bottom subtitle bar (DialogueBubble scene)
  SideHpRail.gd
  SoundGen.gd  MusicDirector.gd
  data/
    MetaSave.gd  ActiveRun.gd  RunState.gd
    EnemyCatalog.gd  QuestDef.gd  QuestGenerator.gd
    BoardOfferPersist.gd  UpgradeCatalog.gd  ModifierDef.gd
    FirstMeetScenes.gd  EncounterLines.gd
    ReceptionistGreetings.gd  SubtitleMarkup.gd
```

## How a run works

1. Boot into the receptionist. First visit: sign the guild contract (`MetaSave.receptionist_contract_signed`).
2. Guild Board shows 2–4 offers matching your rank (`E` easiest → `S` hardest). Extra slots come from the `board_postings` upgrade.
3. Accept → `QuestGenerator` builds rooms from length / difficulty / biome / enemy tiers.
4. Combat rooms: tap SPACE or click when notes hit the line.
5. Unmet enemy → `FirstMeetVN`, then fight. Met enemies skip straight to combat, with rematch lines from `MetaSave.enemy_last_result`.
6. Rest heals ~35%. Shop can spend quest gold for HP.
7. Clear banks gold and may rank up. Concede can drop rank (~35%) and apply hidden modifiers / level drain.

### Hit windows

| Rating | Window | Score |
|---|---|---|
| PERFECT | ±80 ms | 300 × combo |
| GOOD | ±150 ms | 100 × combo |
| OK | ±220 ms | 50 |
| MISS | outside | 0, combo reset |

BPM comes from the combat track when `MusicDirector` has one; otherwise presets 80 / 100 / 120 / 140 / 160.

## Enemies

From `scripts/data/EnemyCatalog.gd`:

| Id | Display | Tier | Biomes |
|---|---|---|---|
| `slime_girl` | Slime Girl | 1 | dungeon, swamp |
| `goblin_girl` | Goblin Girl | 1 | dungeon, forest |
| `succubus` | Succubus | 2 | dungeon, palace |
| `kitsune` | Kitsune | 2 | forest, palace |
| `troll_girl` | Troll Girl | 3 | dungeon, volcanic |
| `dragoness` | Dragoness | 3 | volcanic, palace |

## Persistence

`MetaSave` stores banked gold, upgrade ranks, guild rank, affinity (dialogue only), last outcome, `met_enemies`, per-enemy last result, receptionist contract flag, and `board_offers`.

Home upgrades (see `UpgradeCatalog.gd`): Vitality, Strikes, Starting Purse, Iron Will, Extra Board Postings.

## Combat subtitles

Bottom bar via `DialogueBubble.tscn` + `CombatSubtitle.gd`. Markup reference: `rhythmtap-ui-updated-11/README_SUBTITLES.md`.

## Development history

Built as phases 0–13 (PRs #1–#14). Short index is in [`docs/PHASES.md`](docs/PHASES.md). Per-phase files remain under `rhythmtap-ui-updated-11/README_PHASE*.md`.
