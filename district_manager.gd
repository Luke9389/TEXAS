class_name DistrictManager
extends Node2D

@export var district_scene: PackedScene
@export var pip_scene: PackedScene
@export var max_districts: int = 5

var current_district: DistrictArea = null
var all_districts: Array[DistrictArea] = []
var all_pips: Array[PipArea] = []

signal district_created(district: DistrictArea)
signal district_deleted(district: DistrictArea)
signal pip_added(pip: PipArea)
signal district_limit_reached()

func _ready():
	# Find all existing pips in the scene and add them to our tracking
	var pips_node = get_node("../Pips")
	if pips_node:
		for child in pips_node.get_children():
			if child is PipArea:
				all_pips.append(child)
				child.set_random_party()  # Set random colors for existing pips

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
	
	# Connect to the completed signal
	current_district.district_completed.connect(_on_district_completed)

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
			await get_tree().create_timer(0.4).timeout
		
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