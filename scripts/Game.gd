extends Node2D
class_name Game

## Main game controller - handles turn-based loop, FOV, combat, and level transitions

# Scenes to instantiate
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const MONSTER_SCENE := preload("res://scenes/monster.tscn")

# Game state
var dungeon: DungeonGenerator
var fov: FOV
var player: Player
var monsters: Array[Monster] = []
var current_level := 1
var game_over := false

# FOV and exploration
var visible_tiles := {}
var explored_tiles := {}

# Tilemap for rendering dungeon
@onready var tilemap: TileMap = $TileMap
@onready var entities_layer: Node2D = $EntitiesLayer
@onready var ui: CanvasLayer = $UI
@onready var hp_label: Label = $UI/HPLabel
@onready var level_label: Label = $UI/LevelLabel
@onready var log_label: Label = $UI/LogLabel
@onready var game_over_panel: Panel = $UI/GameOverPanel
@onready var game_over_label: Label = $UI/GameOverPanel/GameOverLabel

const TILE_SIZE := 64

# Tilemap source IDs (we'll create these at runtime)
var tile_source_id := 0

func _ready() -> void:
	_setup_tilemap()
	_start_new_game()

## Setup tilemap with procedurally generated tile textures
func _setup_tilemap() -> void:
	# Create a new TileSet if one doesn't exist
	if tilemap.tile_set == null:
		tilemap.tile_set = TileSet.new()

	# Create tile source
	var tile_source := TileSetAtlasSource.new()
	tile_source.texture = _create_tile_atlas()
	tile_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Define tiles in the atlas
	var tiles := [
		Vector2i(0, 0),  # WALL
		Vector2i(1, 0),  # FLOOR
		Vector2i(2, 0),  # DOOR_CLOSED
		Vector2i(3, 0),  # DOOR_OPEN
		Vector2i(4, 0),  # STAIRS_DOWN
	]

	for i in range(tiles.size()):
		tile_source.create_tile(tiles[i])

	tilemap.tile_set.add_source(tile_source, tile_source_id)

## Create a simple tile atlas texture with colored squares
func _create_tile_atlas() -> ImageTexture:
	var atlas_width := 5 * TILE_SIZE
	var atlas_height := TILE_SIZE
	var img := Image.create(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)

	# Define colors for each tile type
	var colors := [
		Color(0.3, 0.3, 0.3),      # WALL - dark gray
		Color(0.6, 0.6, 0.6),      # FLOOR - light gray
		Color(0.6, 0.4, 0.2),      # DOOR_CLOSED - brown
		Color(0.4, 0.6, 0.3),      # DOOR_OPEN - green
		Color(1.0, 0.8, 0.2),      # STAIRS_DOWN - yellow
	]

	# Fill each tile with its color
	for i in range(colors.size()):
		for y in range(TILE_SIZE):
			for x in range(TILE_SIZE):
				img.set_pixel(i * TILE_SIZE + x, y, colors[i])

	return ImageTexture.create_from_image(img)

## Start a new game
func _start_new_game() -> void:
	current_level = 1
	game_over = false
	game_over_panel.visible = false
	_generate_level()

## Generate a new dungeon level
func _generate_level() -> void:
	# Clear previous level
	_clear_level()

	# Generate dungeon
	dungeon = DungeonGenerator.new()
	fov = FOV.new()
	dungeon.generate()

	# Render dungeon to tilemap
	_render_dungeon()

	# Spawn player
	_spawn_player()

	# Spawn monsters
	_spawn_monsters()

	# Calculate initial FOV
	_update_fov()

	# Update UI
	_update_ui()

	add_log("Welcome to level %d!" % current_level)

## Clear the current level
func _clear_level() -> void:
	# Remove all entities
	if player:
		player.queue_free()
		player = null

	for monster in monsters:
		if is_instance_valid(monster):
			monster.queue_free()
	monsters.clear()

	# Clear tilemap
	tilemap.clear()

	# Reset exploration
	visible_tiles.clear()
	explored_tiles.clear()

## Render dungeon to tilemap
func _render_dungeon() -> void:
	for y in range(dungeon.map_height):
		for x in range(dungeon.map_width):
			var tile_type: DungeonGenerator.TileType = dungeon.get_tile(x, y)
			var atlas_coords := Vector2i(tile_type, 0)
			tilemap.set_cell(0, Vector2i(x, y), tile_source_id, atlas_coords)

## Spawn the player
func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	entities_layer.add_child(player)

	var start_pos := dungeon.get_player_start_position()
	player.set_grid_pos(start_pos)

	player.died.connect(_on_player_died)

## Spawn monsters in random rooms
func _spawn_monsters() -> void:
	var monster_count := 3 + current_level * 2

	for i in range(monster_count):
		if dungeon.rooms.size() <= 1:
			break

		# Pick a random room (skip first room where player spawns)
		var room_idx := randi_range(1, dungeon.rooms.size() - 1)
		var room: Rect2i = dungeon.rooms[room_idx]

		# Find a random floor position in the room
		var attempts := 0
		while attempts < 20:
			attempts += 1
			var x := randi_range(room.position.x, room.position.x + room.size.x - 1)
			var y := randi_range(room.position.y, room.position.y + room.size.y - 1)
			var pos := Vector2i(x, y)

			# Check if position is free
			if dungeon.is_walkable(x, y) and not _get_actor_at(pos):
				var monster := MONSTER_SCENE.instantiate()
				entities_layer.add_child(monster)
				monster.set_grid_pos(pos)
				monster.set_target(player)
				monster.died.connect(_on_monster_died)
				monsters.append(monster)
				break

## Update field of view
func _update_fov() -> void:
	visible_tiles = fov.calculate_fov(player.grid_pos, dungeon)

	# Mark visible tiles as explored
	for tile_pos in visible_tiles.keys():
		explored_tiles[tile_pos] = true

	_update_tile_visibility()

## Update tile visibility based on FOV
func _update_tile_visibility() -> void:
	for y in range(dungeon.map_height):
		for x in range(dungeon.map_width):
			var pos := Vector2i(x, y)
			var tile_id := tilemap.get_cell_source_id(0, pos)

			if tile_id == -1:
				continue

			if visible_tiles.has(pos):
				# Visible - full brightness
				tilemap.set_cell(0, pos, tile_source_id, tilemap.get_cell_atlas_coords(0, pos))
				var tile_data := tilemap.get_cell_tile_data(0, pos)
				if tile_data:
					tile_data.modulate = Color.WHITE
			elif explored_tiles.has(pos):
				# Explored but not visible - dimmed
				var tile_data := tilemap.get_cell_tile_data(0, pos)
				if tile_data:
					tile_data.modulate = Color(0.4, 0.4, 0.4)

	# Update entity visibility
	for monster in monsters:
		if is_instance_valid(monster):
			monster.visible = visible_tiles.has(monster.grid_pos)

## Process input and game logic
func _process(_delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("restart"):
			_start_new_game()
		return

	if not player or not player.is_alive():
		return

	# Get player input
	var direction := player.get_input_direction()

	if direction != Vector2i.ZERO:
		_process_player_turn(direction)

## Process a player turn
func _process_player_turn(direction: Vector2i) -> void:
	var new_pos := player.grid_pos + direction

	# Check bounds and walkability
	if not dungeon._in_bounds(new_pos.x, new_pos.y):
		return

	# Check for door
	if dungeon.get_tile(new_pos.x, new_pos.y) == DungeonGenerator.TileType.DOOR_CLOSED:
		dungeon.open_door(new_pos.x, new_pos.y)
		_render_dungeon()
		add_log("You open the door.")
		_process_monster_turns()
		_update_fov()
		_update_ui()
		return

	# Check for monster
	var target_monster := _get_monster_at(new_pos)
	if target_monster:
		_player_attack(target_monster)
		_process_monster_turns()
		_update_fov()
		_update_ui()
		return

	# Check walkability
	if not dungeon.is_walkable(new_pos.x, new_pos.y):
		return

	# Move player
	player.set_grid_pos(new_pos)

	# Check for stairs
	if dungeon.get_tile(new_pos.x, new_pos.y) == DungeonGenerator.TileType.STAIRS_DOWN:
		_descend_stairs()
		return

	# Process monster turns
	_process_monster_turns()

	# Update FOV and UI
	_update_fov()
	_update_ui()

## Player attacks a monster
func _player_attack(target: Monster) -> void:
	var result: Dictionary = player.attack(target)
	add_log("You hit the monster for %d damage!" % result.damage)

	if result.target_died:
		add_log("The monster dies!")

## Process all monster turns
func _process_monster_turns() -> void:
	for monster in monsters:
		if not is_instance_valid(monster) or not monster.is_alive():
			continue

		# Only act if monster can see player
		if not visible_tiles.has(monster.grid_pos):
			continue

		# Check if adjacent to player
		var distance := (monster.grid_pos - player.grid_pos).abs()
		if distance.x <= 1 and distance.y <= 1 and distance != Vector2i.ZERO:
			# Attack player
			_monster_attack(monster)
		else:
			# Move toward player
			var move := monster.get_ai_move(dungeon)
			if move != Vector2i.ZERO:
				var new_pos := monster.grid_pos + move

				# Check if position is occupied by another monster
				if not _get_monster_at(new_pos):
					monster.set_grid_pos(new_pos)

## Monster attacks player
func _monster_attack(monster: Monster) -> void:
	var result: Dictionary = monster.attack(player)
	add_log("Monster hits you for %d damage!" % result.damage)

	if result.target_died:
		add_log("You have died!")

## Descend to next level
func _descend_stairs() -> void:
	current_level += 1
	add_log("You descend to level %d..." % current_level)
	await get_tree().create_timer(0.5).timeout
	_generate_level()

## Get actor at position
func _get_actor_at(pos: Vector2i) -> Actor:
	if player and player.grid_pos == pos:
		return player

	for monster in monsters:
		if is_instance_valid(monster) and monster.grid_pos == pos:
			return monster

	return null

## Get monster at position
func _get_monster_at(pos: Vector2i) -> Monster:
	for monster in monsters:
		if is_instance_valid(monster) and monster.grid_pos == pos:
			return monster
	return null

## Update UI elements
func _update_ui() -> void:
	if player and player.is_alive():
		hp_label.text = "HP: %d/%d" % [player.hp, player.max_hp]
	else:
		hp_label.text = "HP: 0/0"

	level_label.text = "Level: %d" % current_level

## Add message to log
func add_log(message: String) -> void:
	log_label.text = message

## Handle player death
func _on_player_died(_actor: Actor) -> void:
	game_over = true
	game_over_panel.visible = true
	game_over_label.text = "You Died!\n\nYou reached level %d.\n\nPress R to restart" % current_level

## Handle monster death
func _on_monster_died(actor: Actor) -> void:
	monsters.erase(actor)
