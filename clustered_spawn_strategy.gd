class_name ClusteredSpawnStrategy
extends SpawnStrategy

# Clustered spawning strategy
# Creates distinct clusters of pips for more realistic population distribution

@export var num_clusters: int = 3
@export var cluster_radius: float = 120.0
@export var min_distance_between_pips: float = 30.0  # Closer spacing within clusters
@export var max_attempts_per_pip: int = 50

func generate_positions(count: int, boundary_node: TexasBoundary, existing_positions: Array[Vector2] = []) -> Array[Vector2]:
	if not boundary_node:
		push_error("ClusteredSpawnStrategy: boundary_node is required")
		return []
	
	var boundary_rect = get_boundary_bounding_rect(boundary_node)
	if boundary_rect.size == Vector2.ZERO:
		push_error("ClusteredSpawnStrategy: No valid boundary found")
		return []
	
	var generated_positions: Array[Vector2] = []
	var all_existing = existing_positions.duplicate()
	
	# Generate cluster centers
	var cluster_centers: Array[Vector2] = []
	for i in range(num_clusters):
		var attempts = 0
		while attempts < 100:  # Try to find good cluster centers
			var center = Vector2(
				randf_range(boundary_rect.position.x, boundary_rect.position.x + boundary_rect.size.x),
				randf_range(boundary_rect.position.y, boundary_rect.position.y + boundary_rect.size.y)
			)
			
			if boundary_node.is_point_inside_inner_boundary(center):
				cluster_centers.append(center)
				break
			
			attempts += 1
	
	if cluster_centers.is_empty():
		push_error("ClusteredSpawnStrategy: Could not find any valid cluster centers")
		return []
	
	# Distribute pips among clusters
	var pips_per_cluster = float(count) / float(cluster_centers.size())
	var remaining_pips = count % cluster_centers.size()
	
	for cluster_idx in range(cluster_centers.size()):
		var cluster_center = cluster_centers[cluster_idx]
		var pips_for_this_cluster = int(pips_per_cluster)
		
		# Add extra pip to first clusters if there's a remainder
		if cluster_idx < remaining_pips:
			pips_for_this_cluster += 1
		
		# Generate positions around this cluster center
		for i in range(pips_for_this_cluster):
			var position_found = false
			
			for attempt in range(max_attempts_per_pip):
				# Generate position within cluster radius
				var angle = randf() * 2.0 * PI
				var distance = randf() * cluster_radius
				var cluster_pos = cluster_center + Vector2(cos(angle), sin(angle)) * distance
				
				# Check if position is inside boundary
				if boundary_node.is_point_inside_inner_boundary(cluster_pos):
					# Check if position is valid (not too close to others)
					if is_position_valid(cluster_pos, all_existing, min_distance_between_pips):
						generated_positions.append(cluster_pos)
						all_existing.append(cluster_pos)
						position_found = true
						break
			
			if not position_found:
				print("ClusteredSpawnStrategy: Warning - Could not find valid position for pip in cluster ", cluster_idx)
	
	return generated_positions