# Phase 12 — Survival clarity, patterns/BPM, rematch greetings

## Player asks (from combat screenshot)
1. Hide scuffed top-right Book/Potion/Gear placeholders (`TopHud` Icons).
2. Level drain on concede needs flavor (enemy line + banner).
3. Make 0 HP survival outlast-path obvious (hint + keep loser button).
4. Enemy-tier beat patterns; combat BPM from song (`MusicDirector` TRACK_BPM).
5. Rematch greetings from last win/lose vs that enemy (`MetaSave.enemy_last_result`).

## Implemented
- `TopHud.tscn`: `Icons` `visible = false` (+ Main hide fallback)
- `GameManager` / `EncounterLines`: `level_drain` lines + `LEVEL DRAINED — LV a → LV b` on concede; sync `player_level` from MetaSave
- `Main`: survival banner *"HOLD THE RHYTHM — outlast her to recover. Give in and she'll drain your level."*
- `MusicDirector.TRACK_BPM` (`combat` = **128** default); `get_track_bpm` / `get_current_bpm`
- Combat `current_bpm = song_bpm * pattern_intensity + BPM_PRESSURE`; pattern style/accents by `EnemyCatalog` tier; BeatBar draws accented markers
- `MetaSave.enemy_last_result` (`won`/`lost`); set on defeat / concede; rematch bubble at `begin_encounter` / `continue_after_treasure` (skips empty result so first-meet VN return stays clean)

## Assumptions
- Combat theme BPM default **128** (MP3 has no metadata). Override in `MusicDirector.TRACK_BPM`.
- Tap accuracy still stubbed; patterns are visual/schedule only.

## Skip
Full Tutorial / Album / Option wiring (icons hidden until ready).
