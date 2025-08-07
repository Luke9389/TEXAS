class_name RandomSpawnStrategy
extends SpawnStrategy

# Random scatter spawning strategy
# Generates positions randomly within the boundary with collision avoidance

@export var max_attempts_per_pip: int = 100
@export var min_distance_between_pips: float = 60.0

func generate_positions(count: int, boundary_node: TexasBoundary, existing_positions: Array[Vector2] = []) -> Array[Vector2]:
	if not boundary_node:
		push_error("RandomSpawnStrategy: boundary_node is required")
		return []
	
	var boundary_rect = get_boundary_bounding_rect(boundary_node)
	if boundary_rect.size == Vector2.ZERO:
		push_error("RandomSpawnStrategy: No valid boundary found")
		return []
	
	var generated_positions: Array[Vector2] = []
	var all_existing = existing_positions.duplicate()
	
	for i in range(count):
		var position_found = false
		
		# Try multiple times to find a valid position
		for attempt in range(max_attempts_per_pip):
			# Generate random position within bounding box
			var random_pos = Vector2(
				randf_range(boundary_rect.position.x, boundary_rect.position.x + boundary_rect.size.x),
				randf_range(boundary_rect.position.y, boundary_rect.position.y + boundary_rect.size.y)
			)
			
			# Check if position is inside boundary
			if boundary_node.is_point_inside_inner_boundary(random_pos):
				# Check if position is valid (not too close to others)
				if is_position_valid(random_pos, all_existing, min_distance_between_pips):
					generated_positions.append(random_pos)
					all_existing.append(random_pos)  # Add to existing for next iteration
					position_found = true
					break
		
		if not position_found:
			print("RandomSpawnStrategy: Warning - Could not find valid position for pip ", i + 1)
	
	return generated_positions