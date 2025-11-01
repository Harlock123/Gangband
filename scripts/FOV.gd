extends Node
class_name FOV

## Field of View calculator using recursive shadowcasting
## Based on http://www.roguebasin.com/index.php?title=FOV_using_recursive_shadowcasting

# FOV radius - TWEAK THIS
@export var fov_radius := 8

# Octant multipliers for transforming coordinates
const OCTANTS := [
	[1, 0, 0, 1],   # 0: East
	[0, 1, 1, 0],   # 1: Northeast
	[0, -1, 1, 0],  # 2: Southeast
	[-1, 0, 0, 1],  # 3: West
	[-1, 0, 0, -1], # 4: Southwest
	[0, -1, -1, 0], # 5: Northwest
	[0, 1, -1, 0],  # 6: Northwest alt
	[1, 0, 0, -1],  # 7: South
]

## Calculate visible tiles from origin position
## Returns a dictionary of Vector2i -> bool for visible tiles
func calculate_fov(origin: Vector2i, dungeon: DungeonGenerator) -> Dictionary:
	var visible_tiles := {}

	# Origin is always visible
	visible_tiles[origin] = true

	# Cast shadows in all 8 octants
	for octant in range(8):
		_cast_light(dungeon, origin, 1, 1.0, 0.0, fov_radius,
					OCTANTS[octant][0], OCTANTS[octant][1],
					OCTANTS[octant][2], OCTANTS[octant][3],
					visible_tiles)

	return visible_tiles

## Recursive shadowcasting for a single octant
func _cast_light(dungeon: DungeonGenerator, origin: Vector2i, row: int,
				 start_slope: float, end_slope: float, radius: int,
				 xx: int, xy: int, yx: int, yy: int, visible_tiles: Dictionary) -> void:
	if start_slope < end_slope:
		return

	var next_start_slope := start_slope

	for i in range(row, radius + 1):
		var blocked := false
		var dy := -i

		for dx in range(-i, 1):
			var left_slope := (dx - 0.5) / (dy + 0.5)
			var right_slope := (dx + 0.5) / (dy - 0.5)

			if start_slope < right_slope:
				continue
			elif end_slope > left_slope:
				break

			# Calculate actual map coordinates
			var map_x := origin.x + dx * xx + dy * xy
			var map_y := origin.y + dx * yx + dy * yy

			# Check if within radius (circular FOV)
			var distance_sq := dx * dx + dy * dy
			if distance_sq <= radius * radius:
				visible_tiles[Vector2i(map_x, map_y)] = true

			# Handle blocking tiles
			if blocked:
				if dungeon.blocks_sight(map_x, map_y):
					next_start_slope = right_slope
					continue
				else:
					blocked = false
					start_slope = next_start_slope
			else:
				if dungeon.blocks_sight(map_x, map_y) and i < radius:
					blocked = true
					next_start_slope = right_slope
					_cast_light(dungeon, origin, i + 1, start_slope, left_slope,
							   radius, xx, xy, yx, yy, visible_tiles)

		if blocked:
			break
