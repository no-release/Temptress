# Phase 13 — Persistent unique guild board + boot without Town

## Player asks
1. No Town on boot / title first screen — Town only after guild entry (board Back, post-run).
2. Guild board offers persist across reboot (no reroll).
3. Accepting one quest regenerates the other leftover slots with fresh offers.
4. Buying `board_postings` immediately fills the new empty slot.
5. All simultaneous offers must be unique quest combos.

## Implemented
- `MainMenu.gd`: removed dynamic `- TOWN -` shortcut (boot remains `ReceptionistBoot` → guild flow).
- `BoardOfferPersist.gd`: serialize/deserialize `QuestDef` offers; `ensure_offers` / `accept_and_refresh` / `fill_new_slots`.
- `MetaSave.board_offers`: Array of offer dictionaries in `to_dict` / `from_dict`; `try_buy_upgrade("board_postings")` calls `fill_new_slots`.
- `GuildBoard.gd`: loads persisted offers; accept refreshes board then starts run.
- `QuestGenerator.generate_offers`: `exclude_keys` + always skip duplicate length/difficulty/biome keys.

## Offer serialization
Each offer is a Dictionary: `id`, `display_name`, `length`, `difficulty`, `biome`, `combat_room_count`, `gold_multiplier`, `xp_multiplier`, `forced_enemies`, `allow_rest`, `allow_shop`, `min_enemy_tier`, `max_enemy_tier`.
Uniqueness key: `"{length}_{difficulty}_{biome}"`. Stored under MetaSave JSON key `board_offers`.
