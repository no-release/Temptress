# TEMPTRESS Phase 10 — Boot into guild receptionist (no Start)

- `project.godot` `run/main_scene` → `ReceptionistBoot.tscn` (walking through the guild door)
- First visit: elaborate contract VN via `FirstMeetScenes.receptionist_pages` + sign → `MetaSave.receptionist_contract_signed` → GuildBoard
- Later boots: performance-aware greeting (`last_outcome` / `receptionist_affinity`) then hub buttons (board / home / title)
- Typewriter reuses Phase 8 FirstMeetVN pattern (click to complete / advance)
- Town no longer forces the contract intro; keeps shorter post-run greetings only
- MainMenu still reachable from Town / boot hub; Start routes back through the door
