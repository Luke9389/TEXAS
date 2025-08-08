class_name DistrictManager
extends Node2D

# Constants
const DEFAULT_MAX_DISTRICTS = 5
const DELETION_ANIMATION_DELAY = 0.4
const PIPS_NODE_PATH = "../Pips"

@export var district_scene: PackedScene
@export var max_districts: int = DEFAULT_MAX_DISTRICTS
@export var pips_container_path: NodePath = PIPS_NODE_PATH

var all_districts: Array[DistrictArea] = []
var all_pips: Array[PipArea] = []
var texas_boundary: TexasBoundary = null

signal district_created(district: DistrictArea)
signal district_deleted(district: DistrictArea)
signal district_limit_reached()
signal districts_cleared()

func _ready():
	# Find the Texas boundary
	texas_boundary = get_node_or_null("../../Geography/TEXAS") as TexasBoundary
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



func _on_district_completed(district: DistrictArea):
	var pip_counts = district.get_pip_counts()
	print("District completed - Green: ", pip_counts.green, " Orange: ", pip_counts.orange, " Area: ", district.get_area())

func clear_all_districts():
	for district in all_districts:
		district.queue_free()
	all_districts.clear()
	districts_cleared.emit()


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

# Create a new district instance for the input handler
func create_district_instance() -> DistrictArea:
	var new_district: DistrictArea
	if district_scene:
		new_district = district_scene.instantiate() as DistrictArea
	else:
		# Create district dynamically if no scene is provided
		new_district = DistrictArea.new()
	
	# Set the district manager reference so it can access pips
	new_district.set_district_manager(self)
	
	# Connect to district signals
	new_district.pip_enclosed_while_drawing.connect(_on_pip_enclosed_while_drawing)
	new_district.pip_released_while_drawing.connect(_on_pip_released_while_drawing)
	
	return new_district

# Register a completed district from the input handler
func register_completed_district(district: DistrictArea):
	if not district:
		return
	
	# Clip the district to Texas boundary and existing districts
	_clip_district_to_all_boundaries(district)
	all_districts.append(district)
	district_created.emit(district)
	print("District registered - total districts: ", all_districts.size())


func get_all_pips() -> Array[PipArea]:
	return all_pips


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