# GangBand Roguelike

A minimal but complete Angband-style roguelike dungeon crawler built in Godot 4.x.

## Project Structure

```
GangBand/
├── project.godot                 # Main project configuration
├── icon.svg                      # Project icon
├── README.md                     # This file
├── scripts/
│   ├── DungeonGenerator.gd      # Procedural dungeon generation
│   ├── FOV.gd                   # Field of view (shadowcasting)
│   ├── Actor.gd                 # Base class for entities
│   ├── Player.gd                # Player character
│   ├── Monster.gd               # Monster AI
│   └── Game.gd                  # Main game controller
└── scenes/
    ├── main.tscn                # Main game scene
    ├── player.tscn              # Player entity scene
    └── monster.tscn             # Monster entity scene
```

## How to Run

1. **Install Godot 4.3 or later** from https://godotengine.org/
2. **Open Godot** and click "Import"
3. **Navigate** to this folder and select `project.godot`
4. Click "Import & Edit"
5. **Press F5** or click the "Play" button to run the game

The game will start immediately at the main scene.

## Controls

- **WASD** or **Arrow Keys**: Move player (turn-based)
- **R**: Restart game after death
- **Movement into a monster**: Attack the monster
- **Movement into a closed door**: Open the door
- **Movement onto stairs**: Descend to the next level

## Gameplay

### Objective
- Explore procedurally generated dungeons
- Fight monsters
- Descend deeper into the dungeon by reaching the stairs
- Survive as long as possible

### Mechanics
- **Turn-based**: Each move you make, all monsters take a turn
- **HP System**: You have 20 HP, monsters have 5 HP
- **Combat**: Walk into enemies to attack them; they attack back when adjacent
- **FOV**: Only see tiles within your field of view (radius 8)
- **Exploration**: Previously seen tiles remain visible but dimmed
- **Permadeath**: Game over when HP reaches 0

## How It Works

### Dungeon Generation (`DungeonGenerator.gd`)
1. **Grid Initialization**: Creates an 80x45 grid filled with walls
2. **Room Placement**: Places 15 rectangular rooms (size 4-10) without overlap
3. **Corridor Carving**: Connects all rooms with L-shaped corridors
4. **Door Placement**: 70% chance to place doors at room entrances
5. **Stairs Placement**: Places stairs in the last room (farthest from start)

### Field of View (`FOV.gd`)
- Uses **recursive shadowcasting** algorithm
- Calculates visible tiles within radius 8
- Walls and closed doors block line of sight
- Returns a dictionary of visible tile positions

### Actors (`Actor.gd`, `Player.gd`, `Monster.gd`)
- **Actor**: Base class with HP, position, attack/defense stats
- **Player**: Handles input, starts with 20 HP and 3 attack
- **Monster**: Simple chase AI, starts with 5 HP and 2 attack

### Game Loop (`Game.gd`)
1. Player inputs movement direction
2. Check for collisions (walls, doors, monsters, stairs)
3. Execute player action (move, attack, open door, descend)
4. All monsters take their turn (move toward player or attack)
5. Update FOV and UI
6. Check for game over

### Rendering
- **TileMap**: Procedurally generated colored tiles (64x64 pixels)
  - Dark gray: Walls
  - Light gray: Floors
  - Brown: Closed doors
  - Green: Open doors
  - Yellow: Stairs
- **Entities**: Colored squares created at runtime
  - Blue: Player
  - Red: Monsters

## Tuning Parameters

### Dungeon Generation (`DungeonGenerator.gd`)
```gdscript
@export var map_width := 80           # Map width in tiles
@export var map_height := 45          # Map height in tiles
@export var room_count := 15          # Number of rooms
@export var room_min_size := 4        # Minimum room size
@export var room_max_size := 10       # Maximum room size
@export var door_chance := 0.7        # Door spawn probability (0.0-1.0)
```

### Field of View (`FOV.gd`)
```gdscript
@export var fov_radius := 8           # Sight range in tiles
```

### Actor Stats (`Actor.gd`, `Player.gd`, `Monster.gd`)
```gdscript
# Player (Player.gd _init)
max_hp = 20
attack_power = 3
defense = 1

# Monster (Monster.gd _init)
max_hp = 5
attack_power = 2
defense = 0
```

### Monster Spawning (`Game.gd`)
```gdscript
# In _spawn_monsters()
var monster_count := 3 + current_level * 2  # Base 3 + 2 per level
```

## Advanced Features

### Seeded RNG
To use a fixed seed for reproducible dungeons, modify `Game.gd`:
```gdscript
func _generate_level() -> void:
    dungeon = DungeonGenerator.new()
    dungeon.generate(12345)  # Use specific seed
```

### Adjusting Difficulty
Make the game harder or easier:

**Easier:**
- Increase player HP/attack in `Player.gd`
- Decrease monster count in `Game.gd`
- Increase FOV radius in `FOV.gd`

**Harder:**
- Decrease player HP/attack
- Increase monster HP/attack in `Monster.gd`
- Add more monsters per level
- Decrease FOV radius

### Custom Tile Colors
Edit `Game.gd` in `_create_tile_atlas()`:
```gdscript
var colors := [
    Color(0.3, 0.3, 0.3),      # WALL
    Color(0.6, 0.6, 0.6),      # FLOOR
    Color(0.6, 0.4, 0.2),      # DOOR_CLOSED
    Color(0.4, 0.6, 0.3),      # DOOR_OPEN
    Color(1.0, 0.8, 0.2),      # STAIRS_DOWN
]
```

## Known Limitations

- **No inventory system**: Pure combat and exploration
- **Simple AI**: Monsters chase in a straight line
- **No items or equipment**: Focus on core roguelike mechanics
- **No save system**: Each run is standalone
- **Procedural textures only**: No sprite assets required

## Extending the Game

### Adding New Monster Types
1. Create a new script extending `Monster.gd`
2. Override `_init()` to set different stats
3. Modify `_spawn_monsters()` to use the new type

### Adding Items
1. Create an `Item.gd` class
2. Add an inventory array to `Player.gd`
3. Generate items during dungeon generation
4. Add pickup logic in `Game.gd`

### Adding Special Rooms
1. Modify `DungeonGenerator.gd` to mark special room types
2. Add special generation logic in `_carve_room()`
3. Render different tiles or spawn special monsters

## Credits

Built with Godot 4.x using GDScript.
Shadowcasting algorithm based on RogueBasin's implementation.

Enjoy your dungeon crawl!
