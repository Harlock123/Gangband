extends Actor
class_name Player

## Player character - handles input and player-specific logic

func _init() -> void:
	max_hp = 20
	hp = 20
	attack_power = 3
	defense = 1
	actor_color = Color(0.2, 0.6, 1.0)  # Blue

## Process player input and return intended movement direction
func get_input_direction() -> Vector2i:
	var direction := Vector2i.ZERO

	if Input.is_action_just_pressed("move_up"):
		direction.y = -1
	elif Input.is_action_just_pressed("move_down"):
		direction.y = 1
	elif Input.is_action_just_pressed("move_left"):
		direction.x = -1
	elif Input.is_action_just_pressed("move_right"):
		direction.x = 1

	return direction
