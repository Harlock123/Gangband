# AGENTS.md

Notes for anyone, human or AI agent, changing this code. `README.md` covers the controls, the mechanics, the tuning
values and ideas for extending the game; this file covers how the project fits together.

## What this is

GangBand, a small turn-based roguelike in the style of Angband, made with Godot 4.3 (Forward Plus renderer) in
GDScript. It has random dungeons, shadowcasting field of view, monsters that chase the player, and stairs down.
It needs the Godot editor or runtime to run; there is no C# and no exported build.

## Commands

```bash
godot --path . -e                 # open the project in the Godot 4.3+ editor
godot --path .                    # run the main scene (scenes/main.tscn)
```

Or import `project.godot` from the Godot project manager and press F5. There are no tests yet.

## Layout

- `project.godot`: the project settings, the main scene, a 1280x720 window, nearest-neighbour texture filtering,
  and the input actions `move_up`, `move_down`, `move_left`, `move_right` (WASD and arrows) and `restart` (R).
- `scripts/Game.gd`: the game controller on the main scene's root node. It builds the tile atlas in code,
  generates and draws each level, spawns the player and monsters, runs a turn on each key press (`_process`), and
  updates the field of view and the HUD labels.
- `scripts/DungeonGenerator.gd`: an 80x45 grid of `TileType`s, with rooms, L-shaped corridors, doors and stairs.
- `scripts/FOV.gd`: recursive shadowcasting over the eight octants.
- `scripts/Actor.gd`: the base class (`Node2D`) with grid position, hit points, attack and the `died` and `moved`
  signals. `Player.gd` reads the input actions; `Monster.gd` has the chase AI.
- `scenes/`: `main.tscn` (camera, `TileMap`, entities layer, UI labels), `player.tscn` and `monster.tscn`.

## Rules that keep it working

- **Turn-based, not real-time.** Nothing moves until the player acts: `_process` only reacts to a newly pressed
  input action, then every monster takes one turn. Keep game logic in those turn functions, not in per-frame code.
- **Randomness.** The dungeon has its own `RandomNumberGenerator`, so `dungeon.generate(seed)` repeats a map.
  Monster placement and combat rolls use Godot's global `randi_range`, so a seed does not repeat a whole game.
- **Graphics are made in code.** Tiles and actors are coloured squares created at run time (`_create_tile_atlas`,
  `Actor._setup_sprite`); there are no sprite files to add.
- **Edit scenes and settings in the editor.** `.tscn` files and `project.godot` are written by Godot; hand edits
  must keep their format. Input bindings live in `project.godot`.
- **Don't commit the editor cache.** `.godot/` is Godot's cache; only its `.gdignore` is tracked.

## Making a change

- Run the game in Godot and play a few levels, including dying and restarting with R.
- Update `README.md` (controls, mechanics, tuning values) to match.
