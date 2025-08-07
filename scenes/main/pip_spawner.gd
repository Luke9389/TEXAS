class_name PipSpawner
extends Node2D

@export var num_pips_to_spawn: int = 50
@export var pip_scene: PackedScene = preload("res://scenes/pip/pip.tscn")
@export var texas_boundary_path: NodePath = "../TEXAS"

var spawn_strategy: SpawnStrategy
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
	
	# Set default spawn strategy if none assigned
	if not spawn_strategy:
		spawn_strategy = RandomSpawnStrategy.new()
	
	# Wait a frame to ensure everything is ready
	await get_tree().process_frame
	
	spawn_pips()

func spawn_pips():
	print("Spawning ", num_pips_to_spawn, " pips in Texas...")
	
	if not spawn_strategy:
		push_error("PipSpawner: No spawn strategy assigned!")
		return
	
	# Get existing pip positions to avoid conflicts
	var existing_positions: Array[Vector2] = []
	for pip in spawned_pips:
		existing_positions.append(pip.global_position)
	
	# Use strategy to generate positions
	var positions = spawn_strategy.generate_positions(num_pips_to_spawn, texas_boundary, existing_positions)
	
	# Spawn pips at generated positions
	for spawn_position in positions:
		_spawn_pip_at_position(spawn_position)
	
	print("Successfully spawned ", positions.size(), " pips out of ", num_pips_to_spawn, " requested")

func _spawn_pip_at_position(spawn_position: Vector2):
	var pip_instance = pip_scene.instantiate() as PipArea
	if not pip_instance:
		push_error("PipSpawner: Failed to instantiate pip scene!")
		return
	
	# Set position
	pip_instance.global_position = spawn_position
	
	# Set random party
	pip_instance.set_random_party()
	
	# Add to scene
	add_child(pip_instance)
	spawned_pips.append(pip_instance)

# This method is now handled by spawn strategies, but kept for backward compatibility
func _is_position_valid(_position: Vector2, min_distance: float = 60.0) -> bool:
	var existing_positions: Array[Vector2] = []
	for pip in spawned_pips:
		existing_positions.append(pip.global_position)
	
	if spawn_strategy:
		return spawn_strategy.is_position_valid(_position, existing_positions, min_distance)
	else:
		# Fallback to old logic if no strategy
		for existing_pip in spawned_pips:
			if existing_pip.global_position.distance_to(_position) < min_distance:
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
