extends Actor
class_name Monster

## Monster AI - simple chase behavior using A* pathfinding

var target: Actor = null

func _init() -> void:
	max_hp = 5
	hp = 5
	attack_power = 2
	defense = 0
	actor_color = Color(1.0, 0.3, 0.3)  # Red

## Set the monster's target (usually the player)
func set_target(new_target: Actor) -> void:
	target = new_target

## Calculate next move toward target using simple chase AI
func get_ai_move(dungeon: DungeonGenerator) -> Vector2i:
	if not target or not target.is_alive():
		return Vector2i.ZERO

	# Simple chase: move one step closer to target
	var dx := sign(target.grid_pos.x - grid_pos.x)
	var dy := sign(target.grid_pos.y - grid_pos.y)

	# Try to move toward target (prefer axis with larger distance)
	var moves := []

	if abs(target.grid_pos.x - grid_pos.x) > abs(target.grid_pos.y - grid_pos.y):
		moves = [Vector2i(dx, 0), Vector2i(0, dy), Vector2i(dx, dy)]
	else:
		moves = [Vector2i(0, dy), Vector2i(dx, 0), Vector2i(dx, dy)]

	# Try each move in order of preference
	for move in moves:
		if move == Vector2i.ZERO:
			continue
		var new_pos := grid_pos + move
		if dungeon.is_walkable(new_pos.x, new_pos.y):
			return move

	# Can't move
	return Vector2i.ZERO
