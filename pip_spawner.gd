class_name PipSpawner
extends Node2D

@export var num_pips_to_spawn: int = 50
@export var pip_scene: PackedScene = preload("res://pip.tscn")
@export var texas_boundary_path: NodePath = "../TEXAS"
@export var spawn_attempts_per_pip: int = 100

var texas_boundary: TexasBoundary
var spawned_pips: Array[PipArea] = []

func _ready():
	# Find the Texas boundary
	if texas_boundary_path:
		texas_boundary = get_node_or_null(texas_boundary_path) as TexasBoundary
	
	if not texas_boundary:
		push_error("PipSpawner: Could not find TexasBoundary at path: " + str(texas_boundary_path))
		return
	
	if not pip_scene:
		push_error("PipSpawner: No pip scene assigned!")
		return
	
	# Wait a frame to ensure everything is ready
	await get_tree().process_frame
	
	spawn_pips()

func spawn_pips():
	print("Spawning ", num_pips_to_spawn, " pips in Texas...")
	
	# Get the inner boundary polygon to determine spawn area
	var boundary_polygon = texas_boundary.get_local_inner_boundary_polygon()
	if boundary_polygon.is_empty():
		push_error("PipSpawner: No inner boundary polygon found!")
		return
	
	# Calculate bounding box of Texas
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for point in boundary_polygon:
		var global_point = texas_boundary.to_global(point)
		min_x = min(min_x, global_point.x)
		max_x = max(max_x, global_point.x)
		min_y = min(min_y, global_point.y)
		max_y = max(max_y, global_point.y)
	
	# Spawn pips
	var successful_spawns = 0
	for i in range(num_pips_to_spawn):
		var pip_spawned = false
		
		# Try multiple times to find a valid position
		for attempt in range(spawn_attempts_per_pip):
			# Generate random position within bounding box
			var random_pos = Vector2(
				randf_range(min_x, max_x),
				randf_range(min_y, max_y)
			)
			
			# Check if position is inside inner Texas boundary
			if texas_boundary.is_point_inside_inner_boundary(random_pos):
				# Check if position is not too close to existing pips
				if _is_position_valid(random_pos):
					_spawn_pip_at_position(random_pos)
					successful_spawns += 1
					pip_spawned = true
					break
		
		if not pip_spawned:
			print("Warning: Could not find valid position for pip ", i + 1)
	
	print("Successfully spawned ", successful_spawns, " pips out of ", num_pips_to_spawn, " requested")

func _spawn_pip_at_position(position: Vector2):
	var pip_instance = pip_scene.instantiate() as PipArea
	if not pip_instance:
		push_error("PipSpawner: Failed to instantiate pip scene!")
		return
	
	# Set position
	pip_instance.global_position = position
	
	# Set random party
	pip_instance.set_random_party()
	
	# Add to scene
	add_child(pip_instance)
	spawned_pips.append(pip_instance)

func _is_position_valid(position: Vector2, min_distance: float = 60.0) -> bool:
	# Check distance from existing pips to avoid overlap
	for existing_pip in spawned_pips:
		if existing_pip.global_position.distance_to(position) < min_distance:
			return false
	return true

func get_all_spawned_pips() -> Array[PipArea]:
	return spawned_pips

func clear_all_pips():
	for pip in spawned_pips:
		if is_instance_valid(pip):
			pip.queue_free()
	spawned_pips.clear()

func respawn_pips():
	clear_all_pips()
	# Wait for nodes to be freed
	await get_tree().process_frame
	spawn_pips()