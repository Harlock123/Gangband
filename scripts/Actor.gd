extends Node2D
class_name Actor

## Base class for all entities (Player, Monsters)
## Manages grid position, HP, and basic combat stats

signal died(actor: Actor)
signal moved(old_pos: Vector2i, new_pos: Vector2i)

# Grid position (use integers to avoid floating point drift)
var grid_pos: Vector2i = Vector2i.ZERO

# Stats - TWEAK THESE FOR BALANCE
@export var max_hp := 10
@export var hp := 10
@export var attack_power := 2
@export var defense := 0

# Visual
@export var sprite: Sprite2D
@export var actor_color := Color.WHITE

const TILE_SIZE := 64

func _ready() -> void:
	_update_world_position()
	_setup_sprite()

## Initialize the actor's sprite
func _setup_sprite() -> void:
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)

	# Create a simple colored square texture
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(actor_color)
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.centered = false

## Set grid position and update world position
func set_grid_pos(pos: Vector2i) -> void:
	var old_pos := grid_pos
	grid_pos = pos
	_update_world_position()
	moved.emit(old_pos, grid_pos)

## Convert grid position to world position
func _update_world_position() -> void:
	position = Vector2(grid_pos) * TILE_SIZE

## Take damage and check for death
func take_damage(damage: int) -> void:
	var actual_damage := maxi(1, damage - defense)
	hp -= actual_damage

	if hp <= 0:
		hp = 0
		die()

## Handle death
func die() -> void:
	died.emit(self)
	queue_free()

## Check if actor is alive
func is_alive() -> bool:
	return hp > 0

## Perform an attack on another actor
func attack(target: Actor) -> Dictionary:
	var damage := randi_range(1, attack_power)
	target.take_damage(damage)

	return {
		"attacker": self,
		"target": target,
		"damage": damage,
		"target_died": not target.is_alive()
	}
