# TEMPTRESS Phase 9 — Hit feedback (stagger, shake, HP ghost)

- Enemy hit: Background sprite staggers left/right + procedural hit SFX (`SoundGen.play_hit`)
- Player hit: minor CanvasLayer screenshake + softer hurt SFX (`SoundGen.play_hurt`)
- Player HP ghost: red `HPBarGhost` behind fill tracks previous width and drains down to current HP
- Hooks existing GameManager signals (`player_stats_changed`, `enemy_state_changed` "hurt") — no combat logic changes
- No Camera2D added; shake uses `UI` CanvasLayer `offset`
