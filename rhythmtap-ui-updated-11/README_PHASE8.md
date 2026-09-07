# TEMPTRESS Phase 8 — Full-screen VN first-meet + typewriter

- First unmet enemy: leave Main → full-screen `FirstMeetVN` scene → mark met → return to Main combat
- Letter-by-letter typewriter; click text box to skip typing or advance pages
- Still once per enemy via `MetaSave.has_met_enemy` / `mark_enemy_met`
- Copy from `FirstMeetScenes.enemy_pages(enemy_id)`
- Autoload `FirstMeetBridge` handoff + mid-run combat snapshot (HP/gold) so quest does not restart
- Combat BGM still starts via `MusicDirector.play("combat")` when the fight begins after the VN
