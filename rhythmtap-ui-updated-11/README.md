# 🎵 Rhythm Tap - Godot 4 Rhythm Game

A fun, polished rhythm tapping game built in Godot 4.

## How to Play

- **SPACE** or **click the TAP button** to hit beats
- Watch the beat bar — blue circles roll in from the right toward the yellow hit line
- Tap exactly when a circle reaches the line for the best score!

## Hit Ratings

| Rating | Timing Window | Points |
|--------|--------------|--------|
| **PERFECT** | ±80ms | 300 × combo bonus |
| **GOOD** | ±150ms | 100 × combo bonus |
| **OK** | ±220ms | 50 |
| **MISS** | outside window | 0, combo reset |

## Controls

| Key | Action |
|-----|--------|
| SPACE | Tap beat |
| ↑ Arrow | Increase BPM |
| ↓ Arrow | Decrease BPM |
| Click | Tap beat (on button or anywhere) |

## BPM Options
80 / 100 / **120** (default) / 140 / 160

## Setup

1. Open Godot 4.x (4.2+)
2. Import this project folder
3. Press F5 or click Play

## Features

- Procedurally generated audio (no external sound files needed)
- Dynamic particle effects and beat flash
- Scrolling beat bar with lookahead
- Combo multiplier system
- Adjustable BPM
- Colorful visual feedback
