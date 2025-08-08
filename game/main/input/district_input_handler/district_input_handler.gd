class_name DistrictInputHandler
extends Node2D

# Handles all input for district creation and deletion
# Separates user interaction from district data management

@export var district_manager_path: NodePath = "../DistrictManager"

var district_manager: DistrictManager
var current_district: DistrictArea = null

# Signals up to Main for coordination
signal district_creation_requested(district: DistrictArea)
signal district_deletion_requested(district: DistrictArea)

func _ready():
	# Find the district manager
	if district_manager_path:
		district_manager = get_node_or_null(district_manager_path) as DistrictManager
	
	if not district_manager:
		push_error("DistrictInputHandler: Could not find DistrictManager at path: " + str(district_manager_path))

func _unhandled_input(event: InputEvent) -> void:
	if not district_manager:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_mouse_press(get_local_mouse_position())
			else:
				_handle_mouse_release()
	
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(get_local_mouse_position())

func _handle_mouse_press(click_pos: Vector2):
	# Check if we clicked inside an existing district to delete it
	var clicked_district = get_district_at_point(click_pos)
	if clicked_district:
		# Signal up to Main instead of calling manager directly
		district_deletion_requested.emit(clicked_district)
		return
	
	# Check if we can draw more districts
	if not district_manager.can_draw_district():
		district_manager.district_limit_reached.emit()
		print("Cannot draw more districts! Limit: ", district_manager.max_districts)
		return
	
	# Otherwise, start drawing a new district
	start_new_district(click_pos)

func _handle_mouse_release():
	# Finish drawing current district
	if current_district and current_district.is_drawing:
		if current_district.finish_drawing():
			# Signal up to Main instead of calling manager directly
			district_creation_requested.emit(current_district)
			current_district = null
		else:
			# Drawing failed (not enough points), remove the district
			current_district.queue_free()
			current_district = null

func _handle_mouse_motion(mouse_pos: Vector2):
	# Add points to current district while dragging
	if current_district and current_district.is_drawing:
		current_district.add_point(mouse_pos)

func start_new_district(start_pos: Vector2):
	# Create a new district instance
	current_district = district_manager.create_district_instance()
	
	if not current_district:
		push_error("DistrictInputHandler: Failed to create district instance")
		return
	
	# Add to scene and start drawing
	add_child(current_district)
	current_district.start_drawing(start_pos)
	
	# Connect to the district signals
	current_district.district_completed.connect(_on_district_completed)

func _on_district_completed(district: DistrictArea):
	# Forward to district manager for logging
	district_manager._on_district_completed(district)

func get_district_at_point(point: Vector2) -> DistrictArea:
	if not district_manager:
		return null
	
	var all_districts = district_manager.get_all_districts()
	for district in all_districts:
		if district.has_method("get_polygon_points"):
			var polygon_points = district.get_polygon_points()
			var local_point = point - district.position
			if Geometry2D.is_point_in_polygon(local_point, polygon_points):
				return district
	return null

func clear_current_district():
	if current_district:
		current_district.queue_free()
		current_district = null