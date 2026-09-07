# Phase 11 — Guild rank E–S + ranked board offers

## Player ask
1. **Guild Board:** stop free pick of LENGTH / DIFFICULTY / BIOME. Generate quest offers matching adventurer rank (E easier → S harder). Player chooses from **2** options (upgrade can raise choices).
2. **Town:** do **not** show pending next-run punishments (still apply secretly). Replace displayed Affinity with **guild rank E→S**.

## Implemented
- `MetaSave.guild_rank` (`E`…`S`) + `rank_index` / `try_rank_up` / `try_rank_down` / `board_offer_count`
  - clear → `try_rank_up()`; concede → ~35% `try_rank_down()`
  - `receptionist_affinity` kept for dialogue only (not shown on Town status)
- `QuestGenerator.generate_offers` + `rank_param_ranges` (rank → length/diff/tier pools)
- `GuildBoard` UI: N offer cards (select + Accept + Back); N = `2 + board_postings` (cap 4)
- `UpgradeCatalog.board_postings` — Extra Board Postings (+1 choice / rank, max_rank 2)
- `Town`: status `LV · gold · RANK X`; modifiers label hidden; pay guild fine stays for gold debt only
- `ReceptionistGreetings`: light rank line on boot returns

## Skip
Beat-taps / Tutorial-Album-Option (as requested).
