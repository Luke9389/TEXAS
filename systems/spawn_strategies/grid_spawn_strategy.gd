class_name GridSpawnStrategy
extends SpawnStrategy

# Grid-based spawning strategy with jitter
# Creates a more organized distribution with some randomness

@export var grid_spacing: float = 80.0
@export var jitter_amount: float = 20.0  # Random offset from grid points
@export var min_distance_between_pips: float = 40.0

func generate_positions(count: int, boundary_node: TexasBoundary, existing_positions: Array[Vector2] = []) -> Array[Vector2]:
	if not boundary_node:
		push_error("GridSpawnStrategy: boundary_node is required")
		return []
	
	var boundary_rect = get_boundary_bounding_rect(boundary_node)
	if boundary_rect.size == Vector2.ZERO:
		push_error("GridSpawnStrategy: No valid boundary found")
		return []
	
	var generated_positions: Array[Vector2] = []
	var all_existing = existing_positions.duplicate()
	var grid_positions: Array[Vector2] = []
	
	# Generate grid points within bounding rectangle
	var x = boundary_rect.position.x
	while x <= boundary_rect.position.x + boundary_rect.size.x:
		var y = boundary_rect.position.y
		while y <= boundary_rect.position.y + boundary_rect.size.y:
			var grid_point = Vector2(x, y)
			
			# Add jitter to make it less rigid
			var jittered_point = grid_point + Vector2(
				randf_range(-jitter_amount, jitter_amount),
				randf_range(-jitter_amount, jitter_amount)
			)
			
			# Check if it's inside the boundary
			if boundary_node.is_point_inside_inner_boundary(jittered_point):
				grid_positions.append(jittered_point)
			
			y += grid_spacing
		x += grid_spacing
	
	# Shuffle grid positions for variety
	grid_positions.shuffle()
	
	# Take the first 'count' positions that don't conflict with existing
	for grid_pos in grid_positions:
		if generated_positions.size() >= count:
			break
		
		if is_position_valid(grid_pos, all_existing, min_distance_between_pips):
			generated_positions.append(grid_pos)
			all_existing.append(grid_pos)
	
	if generated_positions.size() < count:
		print("GridSpawnStrategy: Warning - Only generated ", generated_positions.size(), " positions out of ", count, " requested")
	
	return generated_positions