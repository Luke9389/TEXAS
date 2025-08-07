class_name DistrictManager
extends Node2D

# Constants
const DEFAULT_MAX_DISTRICTS = 5
const DELETION_ANIMATION_DELAY = 0.4
const PIPS_NODE_PATH = "../Pips"

@export var district_scene: PackedScene
@export var pip_scene: PackedScene
@export var max_districts: int = DEFAULT_MAX_DISTRICTS
@export var pips_container_path: NodePath = PIPS_NODE_PATH

var current_district: DistrictArea = null
var all_districts: Array[DistrictArea] = []
var all_pips: Array[PipArea] = []
var texas_boundary: TexasBoundary = null

signal district_created(district: DistrictArea)
signal district_deleted(district: DistrictArea)
signal pip_added(pip: PipArea)
signal district_limit_reached()

func _ready():
	# Find the Texas boundary
	texas_boundary = get_node_or_null("../TEXAS") as TexasBoundary
	if not texas_boundary:
		push_warning("DistrictManager: Could not find Texas boundary!")
	
	# Find all existing pips in the scene and add them to our tracking
	if pips_container_path:
		var pips_node = get_node_or_null(pips_container_path)
		if pips_node:
			# Connect to pip spawner if it exists
			if pips_node.has_method("get_all_spawned_pips"):
				_connect_to_pip_spawner(pips_node)
			else:
				# Fallback: check for existing pip children
				for child in pips_node.get_children():
					if child is PipArea:
						all_pips.append(child)
						child.set_random_party()  # Set random colors for existing pips
		else:
			push_warning("DistrictManager: Could not find pips container at path: " + str(pips_container_path))

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var click_pos = get_local_mouse_position()
				
				# Check if we clicked inside an existing district to delete it
				var clicked_district = get_district_at_point(click_pos)
				if clicked_district:
					delete_district(clicked_district)
					return
				
				# Check if we can draw more districts
				if all_districts.size() >= max_districts:
					district_limit_reached.emit()
					print("Cannot draw more districts! Limit: ", max_districts)
					return
				
				# Otherwise, start drawing a new district
				start_new_district(click_pos)
			else:
				# Finish drawing current district
				if current_district and current_district.is_drawing:
					if current_district.finish_drawing():
						# Clip the district to Texas boundary and existing districts
						_clip_district_to_all_boundaries(current_district)
						all_districts.append(current_district)
						district_created.emit(current_district)
						current_district = null
					else:
						# Drawing failed (not enough points), remove the district
						current_district.queue_free()
						current_district = null
	
	elif event is InputEventMouseMotion:
		# Add points to current district while dragging
		if current_district and current_district.is_drawing:
			current_district.add_point(get_local_mouse_position())

func start_new_district(start_pos: Vector2):
	# Create a new district instance
	if district_scene:
		current_district = district_scene.instantiate() as DistrictArea
	else:
		# Create district dynamically if no scene is provided
		current_district = DistrictArea.new()
	
	# Set the district manager reference so it can access pips
	current_district.set_district_manager(self)
	
	# Add to scene and start drawing
	add_child(current_district)
	current_district.start_drawing(start_pos)
	
	# Connect to the district signals
	current_district.district_completed.connect(_on_district_completed)
	current_district.pip_enclosed_while_drawing.connect(_on_pip_enclosed_while_drawing)
	current_district.pip_released_while_drawing.connect(_on_pip_released_while_drawing)

func _on_district_completed(district: DistrictArea):
	var pip_counts = district.get_pip_counts()
	print("District completed - Green: ", pip_counts.green, " Orange: ", pip_counts.orange, " Area: ", district.get_area())

func clear_all_districts():
	for district in all_districts:
		district.queue_free()
	all_districts.clear()
	if current_district:
		current_district.queue_free()
		current_district = null

func get_district_at_point(point: Vector2) -> DistrictArea:
	for district in all_districts:
		if district.has_method("get_polygon_points"):
			var polygon_points = district.get_polygon_points()
			var local_point = point - district.position
			if Geometry2D.is_point_in_polygon(local_point, polygon_points):
				return district
	return null

func delete_district(district: DistrictArea):
	if district in all_districts:
		all_districts.erase(district)
		district_deleted.emit(district)
		
		# Animate deletion before removing
		if district.has_method("animate_deletion"):
			district.animate_deletion()
			# Wait for animation to finish before freeing
			await get_tree().create_timer(DELETION_ANIMATION_DELAY).timeout
		
		district.queue_free()
		print("District deleted - remaining: ", all_districts.size())

func get_all_districts() -> Array[DistrictArea]:
	return all_districts

func get_total_area() -> float:
	var total = 0.0
	for district in all_districts:
		total += district.get_area()
	return total

func get_remaining_districts() -> int:
	return max_districts - all_districts.size()

func can_draw_district() -> bool:
	return all_districts.size() < max_districts

func add_pip(pip_position: Vector2, party: PipArea.Party) -> PipArea:
	var pip: PipArea
	if pip_scene:
		pip = pip_scene.instantiate() as PipArea
	else:
		pip = PipArea.new()
	
	pip.position = pip_position
	pip.party = party
	add_child(pip)
	all_pips.append(pip)
	pip_added.emit(pip)
	
	# Update any existing districts that might contain this pip
	for district in all_districts:
		if district.has_method("check_contained_pips"):
			district.check_contained_pips()
	
	return pip

func get_all_pips() -> Array[PipArea]:
	return all_pips

func spawn_random_pips(count: int, bounds: Rect2):
	for i in range(count):
		var random_pos = Vector2(
			randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
			randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
		)
		var party = PipArea.Party.GREEN if randf() < 0.5 else PipArea.Party.ORANGE
		add_pip(random_pos, party)

# Signal handlers for real-time pip tracking
func _on_pip_enclosed_while_drawing(_pip: PipArea):
	# Could be used for sound effects or visual feedback
	pass

func _on_pip_released_while_drawing(_pip: PipArea):
	# Could be used for sound effects or visual feedback  
	pass

# Clip a district to all boundaries (Texas and existing districts)
func _clip_district_to_all_boundaries(district: DistrictArea):
	if not district:
		return
	
	# Get the district's polygon in global coordinates
	var district_polygon_local = district.get_polygon_points()
	if district_polygon_local.size() < 3:
		return
	
	var district_polygon_global = PackedVector2Array()
	for point in district_polygon_local:
		district_polygon_global.append(district.global_position + point)
	
	var result_polygon = district_polygon_global
	
	# First clip to Texas boundary if it exists
	if texas_boundary:
		var clipped_polygons = texas_boundary.intersect_polygon_with_boundary(result_polygon)
		if clipped_polygons.size() > 0:
			result_polygon = clipped_polygons[0]
	
	# Then subtract all existing districts
	for existing_district in all_districts:
		if existing_district == district:
			continue  # Skip self
		
		# Get existing district polygon in global coordinates
		var existing_polygon_local = existing_district.get_polygon_points()
		if existing_polygon_local.size() < 3:
			continue
		
		var existing_polygon_global = PackedVector2Array()
		for point in existing_polygon_local:
			existing_polygon_global.append(existing_district.global_position + point)
		
		# Subtract the existing district from our new district
		var clipped = Geometry2D.clip_polygons(result_polygon, existing_polygon_global)
		
		# Find the largest remaining polygon (in case it got split)
		if clipped.size() > 0:
			var largest_area = 0.0
			var largest_polygon = clipped[0]
			for poly in clipped:
				var area = DistrictStatistics.calculate_polygon_area(poly)
				if area > largest_area:
					largest_area = area
					largest_polygon = poly
			result_polygon = largest_polygon
	
	# Convert back to local coordinates for the district
	var clipped_local = PackedVector2Array()
	for point in result_polygon:
		clipped_local.append(point - district.global_position)
	
	# Update the district's polygon
	if clipped_local.size() >= 3:  # Only update if we still have a valid polygon
		district.set_polygon_points(clipped_local)

# Connect to the pip spawner to get pip references
func _connect_to_pip_spawner(pip_spawner: Node):
	if pip_spawner.has_method("get_all_spawned_pips"):
		# Get all currently spawned pips
		all_pips = pip_spawner.get_all_spawned_pips()
		print("DistrictManager: Connected to pip spawner, found ", all_pips.size(), " pips")
		
		# Also periodically refresh in case pips are spawned later
		# This is a simple approach - alternatively we could use signals
		_refresh_pips_from_spawner.call_deferred()

func _refresh_pips_from_spawner():
	# Wait for pip spawner to finish spawning
	await get_tree().process_frame
	await get_tree().process_frame
	
	var pips_node = get_node_or_null(pips_container_path)
	if pips_node and pips_node.has_method("get_all_spawned_pips"):
		all_pips = pips_node.get_all_spawned_pips()
		print("DistrictManager: Refreshed pip list, now tracking ", all_pips.size(), " pips")