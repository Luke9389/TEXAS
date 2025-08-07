class_name SpawnStrategy
extends RefCounted

# Base class for pip spawning strategies
# Provides flexible, testable approaches to positioning pips within boundaries

# Generate positions for spawning pips
# Returns Array[Vector2] of global positions where pips should be spawned
func generate_positions(_count: int, _boundary_node: TexasBoundary, _existing_positions: Array[Vector2] = []) -> Array[Vector2]:
	push_error("SpawnStrategy: generate_positions() must be implemented by subclass")
	return []

# Check if a position is valid (not too close to existing positions)
func is_position_valid(position: Vector2, existing_positions: Array[Vector2], min_distance: float = 60.0) -> bool:
	for existing_pos in existing_positions:
		if existing_pos.distance_to(position) < min_distance:
			return false
	return true

# Get bounding rectangle for a boundary polygon in global coordinates
func get_boundary_bounding_rect(boundary_node: TexasBoundary) -> Rect2:
	var boundary_polygon = boundary_node.get_global_inner_boundary_polygon()
	if boundary_polygon.is_empty():
		return Rect2()
	
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for point in boundary_polygon:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))