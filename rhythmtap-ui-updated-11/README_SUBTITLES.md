# Combat subtitles

Combat speech is no longer a dialogue bubble. It is a **bottom-centered subtitle bar** with a half-transparent plate (`~62%` dark fill, thin pink edge) so copy stays readable over the fight.

`scenes/DialogueBubble.tscn` is now the subtitle widget (`CombatSubtitle.gd`). Call:

```
$UI/DialogueBubble.show_line(text, situation)
```

`situation` is optional (`taunt`, `player_near_death`, `losing`, `drain`, …). If the line has no markup, a default voice wrap is applied from that situation.

## Markup

Custom tags expand to color + italic/bold + Godot FX (`wave`, `shake`, `pulse`, `fade`, `tornado`).

| Tag | Feel |
|-----|------|
| `[whisper]` | small, dim, fade |
| `[shout]` | big, red, shake |
| `[moan]` | pink italic wave |
| `[tease]` | pink wave |
| `[command]` | gold bold outline |
| `[drain]` | violet fade |
| `[hot]` / `[cold]` | heat pulse / ice fade |
| `[sweet]` `[heart]` `[lick]` `[drip]` | affection / wet |
| `[threat]` `[harsh]` `[growl]` | pressure |
| `[giggle]` `[laugh]` `[purr]` `[hiss]` | character ticks |
| `[pant]` `[prey]` `[queen]` | submit / dominate |
| `[echo]` `[glitch]` `[focus]` | special |
| `[soft]` `[mute]` `[big]` `[tiny]` `[slow]` `[fast]` | size / speed |
| `[name=Succubus]` | speaker chip above the line |

Native BBCode still works: `[b] [i] [u] [color=#ff88aa] [font_size=22] [wave] [shake] [rainbow] [pulse] [fade] [tornado] [outline_size]`.

Typewriter speed follows `[slow] [whisper] [pant] [fast] [shout] [glitch]` when those tags are present.

### Example

```
[name=Succubus][command]On your knees.[/command] [moan]Tap if you still can~[/moan]
```
