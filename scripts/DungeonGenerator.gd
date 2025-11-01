extends Node
class_name DungeonGenerator

## Procedural dungeon generator using BSP-like room placement and corridor carving
## Generates rectangular rooms connected by hallways with optional doors

# Tile type constants
enum TileType {
	WALL,
	FLOOR,
	DOOR_CLOSED,
	DOOR_OPEN,
	STAIRS_DOWN
}

# Generation parameters - TWEAK THESE
@export var map_width := 80
@export var map_height := 45
@export var room_count := 15
@export var room_min_size := 4
@export var room_max_size := 10
@export var corridor_width := 1
@export var door_chance := 0.7  # Probability of placing a door at room entrance

# The dungeon grid
var grid: Array[Array] = []
var rooms: Array[Rect2i] = []
var stairs_position: Vector2i

# Random seed support
var rng := RandomNumberGenerator.new()

## Initialize and generate a new dungeon
func generate(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()

	_init_grid()
	_generate_rooms()
	_connect_rooms()
	_place_stairs()

## Initialize grid with all walls
func _init_grid() -> void:
	grid.clear()
	rooms.clear()

	for y in range(map_height):
		var row: Array[TileType] = []
		row.resize(map_width)
		row.fill(TileType.WALL)
		grid.append(row)

## Generate non-overlapping rooms using rejection sampling
func _generate_rooms() -> void:
	var attempts := 0
	var max_attempts := room_count * 50

	while rooms.size() < room_count and attempts < max_attempts:
		attempts += 1

		var w := rng.randi_range(room_min_size, room_max_size)
		var h := rng.randi_range(room_min_size, room_max_size)
		var x := rng.randi_range(1, map_width - w - 2)
		var y := rng.randi_range(1, map_height - h - 2)

		var new_room := Rect2i(x, y, w, h)

		# Check for overlap with existing rooms (with 1-tile padding)
		var overlaps := false
		for room in rooms:
			if new_room.grow(1).intersects(room):
				overlaps = true
				break

		if not overlaps:
			rooms.append(new_room)
			_carve_room(new_room)

## Carve out a room by setting tiles to FLOOR
func _carve_room(room: Rect2i) -> void:
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			grid[y][x] = TileType.FLOOR

## Connect all rooms with L-shaped corridors
func _connect_rooms() -> void:
	for i in range(rooms.size() - 1):
		var room_a := rooms[i]
		var room_b := rooms[i + 1]

		var start := _get_room_center(room_a)
		var end := _get_room_center(room_b)

		# Create L-shaped corridor (horizontal then vertical)
		if rng.randf() > 0.5:
			_carve_horizontal_corridor(start.x, end.x, start.y)
			_carve_vertical_corridor(start.y, end.y, end.x)
		else:
			_carve_vertical_corridor(start.y, end.y, start.x)
			_carve_horizontal_corridor(start.x, end.x, end.y)

## Get the center point of a room
func _get_room_center(room: Rect2i) -> Vector2i:
	return Vector2i(
		room.position.x + room.size.x / 2,
		room.position.y + room.size.y / 2
	)

## Carve a horizontal corridor
func _carve_horizontal_corridor(x1: int, x2: int, y: int) -> void:
	var start_x := mini(x1, x2)
	var end_x := maxi(x1, x2)

	for x in range(start_x, end_x + 1):
		if _in_bounds(x, y):
			_carve_corridor_tile(x, y)

## Carve a vertical corridor
func _carve_vertical_corridor(y1: int, y2: int, x: int) -> void:
	var start_y := mini(y1, y2)
	var end_y := maxi(y1, y2)

	for y in range(start_y, end_y + 1):
		if _in_bounds(x, y):
			_carve_corridor_tile(x, y)

## Carve a single corridor tile and optionally place doors
func _carve_corridor_tile(x: int, y: int) -> void:
	if grid[y][x] == TileType.WALL:
		# Check if this is a room entrance (adjacent to room floor)
		var adjacent_to_room := false
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var nx := x + dx
				var ny := y + dy
				if _in_bounds(nx, ny) and _is_in_room(nx, ny):
					adjacent_to_room = true
					break
			if adjacent_to_room:
				break

		# Place door at entrance with some probability
		if adjacent_to_room and rng.randf() < door_chance:
			# Only place door if it's a proper doorway (wall on opposite sides)
			var has_walls := false
			if (grid[y - 1][x] == TileType.WALL and grid[y + 1][x] == TileType.WALL) or \
			   (grid[y][x - 1] == TileType.WALL and grid[y][x + 1] == TileType.WALL):
				has_walls = true

			if has_walls:
				grid[y][x] = TileType.DOOR_CLOSED
			else:
				grid[y][x] = TileType.FLOOR
		else:
			grid[y][x] = TileType.FLOOR

## Check if a position is inside any room
func _is_in_room(x: int, y: int) -> bool:
	for room in rooms:
		if room.has_point(Vector2i(x, y)):
			return true
	return false

## Place stairs in a random room far from player start
func _place_stairs() -> void:
	if rooms.is_empty():
		return

	# Place stairs in the last room (farthest from first room)
	var stairs_room := rooms[rooms.size() - 1]
	stairs_position = _get_random_floor_in_room(stairs_room)
	grid[stairs_position.y][stairs_position.x] = TileType.STAIRS_DOWN

## Get a random floor position within a room
func _get_random_floor_in_room(room: Rect2i) -> Vector2i:
	return Vector2i(
		rng.randi_range(room.position.x, room.position.x + room.size.x - 1),
		rng.randi_range(room.position.y, room.position.y + room.size.y - 1)
	)

## Get a random floor position in the first room (for player spawn)
func get_player_start_position() -> Vector2i:
	if rooms.is_empty():
		return Vector2i(1, 1)
	return _get_random_floor_in_room(rooms[0])

## Check if coordinates are within grid bounds
func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < map_width and y >= 0 and y < map_height

## Check if a tile blocks movement
func is_walkable(x: int, y: int) -> bool:
	if not _in_bounds(x, y):
		return false
	var tile := grid[y][x]
	return tile == TileType.FLOOR or tile == TileType.DOOR_OPEN or tile == TileType.STAIRS_DOWN

## Check if a tile blocks line of sight
func blocks_sight(x: int, y: int) -> bool:
	if not _in_bounds(x, y):
		return true
	var tile := grid[y][x]
	return tile == TileType.WALL or tile == TileType.DOOR_CLOSED

## Open a door at the given position
func open_door(x: int, y: int) -> bool:
	if _in_bounds(x, y) and grid[y][x] == TileType.DOOR_CLOSED:
		grid[y][x] = TileType.DOOR_OPEN
		return true
	return false

## Get tile type at position
func get_tile(x: int, y: int) -> TileType:
	if not _in_bounds(x, y):
		return TileType.WALL
	return grid[y][x]
