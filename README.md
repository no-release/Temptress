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
├─ README.md                          this file
├─ docs/                               repo-level notes
├─ .gitignore
├─ .gitattributes
├─ _art_* / _audio_*                   STAGING dumps (not the live project)
├─ _*.py                               leftover one-off patch scripts (being removed)
└─ rhythmtap-ui-updated-11/            LIVE Godot project  ← open this
    ├─ project.godot
    ├─ scenes/
    ├─ scripts/          combat, hubs, autoloads
    ├─ scripts/data/     catalogs, save, quest gen, copy
    ├─ audio/            combat BGM + SFX used at runtime
    ├─ backgrounds/  bg_images/
    ├─ enemy_images/ ui_art/  vn_portraits/
    ├─ addons/godot_ai/
    └─ README_PHASE*.md  per-phase notes (also summarized in docs/)
```

Two layers exist on purpose right now:

| Path | What it is |
|---|---|
| `rhythmtap-ui-updated-11/` | The only folder Godot should open. `res://` paths resolve here. |
| `_art_*_extract/`, `_audio_*_extract/`, `*.tar` | Incoming art/audio staging. Duplicates of (or sources for) files later imported into the Godot project. |
| `_patch_*.py`, `_read_*.py` | Scratch scripts used to tweak UI colors/rails. Not part of the game runtime. |

Do not point Godot at the git root. There is no `project.godot` there.

## Godot project map

### Boot and hubs

```
ReceptionistBoot.tscn  →  first boot / contract / greetings
        └─ GuildBoard.tscn   pick a generated quest offer
        └─ Town.tscn         rank, gold, fine payoff, hub buttons
        └─ Home.tscn         spend banked gold on upgrades
        └─ MainMenu.tscn     title; Start goes back through the door
        └─ FirstMeetVN.tscn  full-screen typewriter intro (once per enemy)
        └─ Main.tscn         combat room
        └─ TreasureScreen.tscn
```

### Autoloads (`project.godot`)

| Autoload | Role |
|---|---|
| `SoundGen` | Procedural hit/hurt/UI SFX |
| `MetaSave` | Persistent gold, upgrades, rank, met enemies, board offers |
| `ActiveRun` | Current quest rooms + mid-run snapshot |
| `MusicDirector` | Situation BGM + track BPM |
| `FirstMeetBridge` | Hand-off between VN and combat without restarting the run |
| `Phase12CombatUI` / `Phase12CombatLogic` | Combat clarity helpers from phase 12 |
| `_mcp_game_helper` | `addons/godot_ai` runtime helper |

### Scripts worth knowing

```
scripts/
  GameManager.gd          encounter loop, hits, HP, concede / clear
  Main.gd / MainBase.gd   combat scene wiring
  BeatBar.gd              scrolling notes + pattern accents
  RoomManager.gd          walk the generated room list
  GuildBoard.gd           ranked offers UI
  Town.gd  Home.gd  MainMenu.gd
  ReceptionistBoot.gd     door / contract / greetings
  FirstMeetVN.gd          typewriter VN
  CombatSubtitle.gd       bottom subtitle bar (was DialogueBubble)
  SideHpRail.gd
  SoundGen.gd  MusicDirector.gd
  data/
    MetaSave.gd  ActiveRun.gd  RunState.gd
    EnemyCatalog.gd  QuestDef.gd  QuestGenerator.gd
    BoardOfferPersist.gd  UpgradeCatalog.gd  ModifierDef.gd
    FirstMeetScenes.gd  EncounterLines.gd
    ReceptionistGreetings.gd  SubtitleMarkup.gd
```

### Runtime assets (inside the Godot project)

```
audio/            combat_theme and related music/sfx
backgrounds/      combat / room backdrops
bg_images/        extra backgrounds
enemy_images/     fight portraits / poses
vn_portraits/     first-meet + receptionist art
ui_art/           HUD chrome
```

Staging copies of the same kind of files also live at repo root under `_art_*_extract` and `_audio_pack_extract`. Prefer the Godot-project copies at runtime.

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

Built as phases 0–13 (PRs #1–#14). Short index is in [`docs/PHASES.md`](docs/PHASES.md). The original per-phase files remain under `rhythmtap-ui-updated-11/README_PHASE*.md`.

## Housekeeping notes

This branch starts cleaning the workbench around the Godot project:

- Root `*.tar` archives duplicate already-extracted folders.
- `_patch_*.py` / `_read_*.py` were one-off editor helpers, not runtime code.
- `_art_*_extract` and `_audio_*_extract` stay for now so art is not deleted until it is confirmed imported under `rhythmtap-ui-updated-11/`.

If you add new art, import it into the Godot project folders above. Do not keep a second live copy at repo root.
