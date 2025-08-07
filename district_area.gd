class_name DistrictArea
extends Area2D

@export var line_color: Color = Color(0.2, 0.4, 0.8, 0.5)
@export var fill_color: Color = Color(0.2, 0.4, 0.8, 0.3)
@export var line_width: float = 3.0
@export var min_point_distance: float = 10.0
@export var min_polygon_points: int = 3

var is_drawing: bool = false
var polygon_points: PackedVector2Array = []
var contained_pips: Array[PipArea] = []
var district_manager: Node2D = null
var currently_enclosed_pips: Array[PipArea] = []

var line_2d: Line2D
var polygon_2d: Polygon2D
var collision_polygon: CollisionPolygon2D

signal district_completed(district: DistrictArea)
signal pip_enclosed_while_drawing(pip: PipArea)
signal pip_released_while_drawing(pip: PipArea)

var deletion_tween: Tween

func _ready():
	line_2d = Line2D.new()
	line_2d.width = line_width
	line_2d.default_color = line_color
	line_2d.joint_mode = 2  # LINE_JOINT_ROUND
	line_2d.begin_cap_mode = 2  # LINE_CAP_ROUND
	line_2d.end_cap_mode = 2  # LINE_CAP_ROUND
	add_child(line_2d)
	
	polygon_2d = Polygon2D.new()
	polygon_2d.color = fill_color
	add_child(polygon_2d)
	
	collision_polygon = $CollisionPolygon2D

func set_district_manager(manager: Node2D):
	district_manager = manager

func start_drawing(start_pos: Vector2):
	is_drawing = true
	polygon_points.clear()
	currently_enclosed_pips.clear()
	polygon_points.append(start_pos)
	line_2d.clear_points()
	line_2d.add_point(start_pos)
	polygon_2d.polygon = PackedVector2Array()

func add_point(new_point: Vector2):
	if not is_drawing:
		return
	
	if polygon_points.size() > 0:
		var last_point = polygon_points[polygon_points.size() - 1]
		var distance = last_point.distance_to(new_point)
		
		if distance >= min_point_distance:
			polygon_points.append(new_point)
			line_2d.add_point(new_point)
			
			if polygon_points.size() > 2:
				var temp_polygon = polygon_points.duplicate()
				temp_polygon.append(polygon_points[0])
				line_2d.points = temp_polygon
				
				# Check for newly enclosed pips in real-time
				check_contained_pips_realtime(temp_polygon)

func finish_drawing() -> bool:
	if not is_drawing:
		return false
	
	is_drawing = false
	
	if polygon_points.size() < min_polygon_points:
		# Reset any highlighted pips
		for pip in currently_enclosed_pips:
			pip.modulate = Color(1.0, 1.0, 1.0, 1.0)
		currently_enclosed_pips.clear()
		return false
	
	polygon_points.append(polygon_points[0])
	
	line_2d.points = polygon_points
	polygon_2d.polygon = polygon_points
	collision_polygon.polygon = polygon_points
	
	# Reset pip highlighting and finalize containment
	for pip in currently_enclosed_pips:
		pip.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	check_contained_pips()
	update_district_colors()
	district_completed.emit(self)
	
	return true

func check_contained_pips():
	contained_pips.clear()
	
	if not district_manager:
		return
	
	if district_manager.has_method("get_all_pips"):
		var all_pips = district_manager.get_all_pips()
		
		for pip in all_pips:
			var local_pip_pos = pip.position - position
			if Geometry2D.is_point_in_polygon(local_pip_pos, polygon_points):
				contained_pips.append(pip)

func check_contained_pips_realtime(temp_polygon: PackedVector2Array):
	if not district_manager or not district_manager.has_method("get_all_pips"):
		return
	
	var all_pips = district_manager.get_all_pips()
	var newly_enclosed: Array[PipArea] = []
	var still_enclosed: Array[PipArea] = []
	
	# Check which pips are currently inside the temporary polygon
	for pip in all_pips:
		var local_pip_pos = pip.position - position
		if Geometry2D.is_point_in_polygon(local_pip_pos, temp_polygon):
			newly_enclosed.append(pip)
			
			# Check if this is a newly enclosed pip
			if pip not in currently_enclosed_pips:
				pip_enclosed_while_drawing.emit(pip)
				# Visual feedback - make the pip glow or change color
				pip.modulate = Color(1.5, 1.5, 1.5, 1.0)  # Brighten the pip
			
			still_enclosed.append(pip)
	
	# Check for pips that were enclosed but are no longer enclosed
	for pip in currently_enclosed_pips:
		if pip not in newly_enclosed:
			pip_released_while_drawing.emit(pip)
			# Reset visual feedback
			pip.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Reset to normal
	
	currently_enclosed_pips = still_enclosed
	
	# Update district colors in real-time based on currently enclosed pips
	update_district_colors_realtime()

func get_polygon_points() -> PackedVector2Array:
	return polygon_points

func get_area() -> float:
	if polygon_points.size() < 3:
		return 0.0
	
	var area = 0.0
	for i in range(polygon_points.size() - 1):
		area += polygon_points[i].x * polygon_points[i + 1].y
		area -= polygon_points[i + 1].x * polygon_points[i].y
	
	return abs(area) / 2.0

func get_pip_counts() -> Dictionary:
	var counts = {"green": 0, "orange": 0}
	for pip in contained_pips:
		if pip.party == PipArea.Party.GREEN:
			counts.green += 1
		else:
			counts.orange += 1
	return counts

func get_winning_party() -> PipArea.Party:
	var counts = get_pip_counts()
	if counts.green > counts.orange:
		return PipArea.Party.GREEN
	elif counts.orange > counts.green:
		return PipArea.Party.ORANGE
	else:
		return PipArea.Party.NONE

func update_district_colors():
	var winning_party = get_winning_party()
	
	match winning_party:
		PipArea.Party.GREEN:
			line_2d.default_color = Color(0.2, 0.8, 0.2, 0.8)  # Green border
			polygon_2d.color = Color(0.2, 0.8, 0.2, 0.3)      # Green fill
		PipArea.Party.ORANGE:
			line_2d.default_color = Color(1.0, 0.5, 0.0, 0.8)  # Orange border
			polygon_2d.color = Color(1.0, 0.5, 0.0, 0.3)      # Orange fill
		PipArea.Party.NONE:
			line_2d.default_color = Color(0.5, 0.5, 0.5, 0.8)  # Gray border (tie)
			polygon_2d.color = Color(0.5, 0.5, 0.5, 0.3)      # Gray fill (tie)

func update_district_colors_realtime():
	# Calculate the winning party from currently enclosed pips (while drawing)
	var green_count = 0
	var orange_count = 0
	
	for pip in currently_enclosed_pips:
		if pip.party == PipArea.Party.GREEN:
			green_count += 1
		else:
			orange_count += 1
	
	var winning_party: PipArea.Party
	if green_count > orange_count:
		winning_party = PipArea.Party.GREEN
	elif orange_count > green_count:
		winning_party = PipArea.Party.ORANGE
	else:
		winning_party = PipArea.Party.NONE
	
	# Update colors based on current majority
	match winning_party:
		PipArea.Party.GREEN:
			line_2d.default_color = Color(0.2, 0.8, 0.2, 0.8)  # Green border
			polygon_2d.color = Color(0.2, 0.8, 0.2, 0.3)      # Green fill
		PipArea.Party.ORANGE:
			line_2d.default_color = Color(1.0, 0.5, 0.0, 0.8)  # Orange border
			polygon_2d.color = Color(1.0, 0.5, 0.0, 0.3)      # Orange fill
		PipArea.Party.NONE:
			line_2d.default_color = Color(0.2, 0.4, 0.8, 0.5)  # Default blue border
			polygon_2d.color = Color(0.2, 0.4, 0.8, 0.3)      # Default blue fill

func animate_deletion():
	# Create a deletion animation - flash red then fade out
	deletion_tween = create_tween()
	deletion_tween.set_parallel(true)
	
	# Flash red
	deletion_tween.tween_property(line_2d, "default_color", Color(1.0, 0.2, 0.2, 0.8), 0.1)
	deletion_tween.tween_property(polygon_2d, "color", Color(1.0, 0.2, 0.2, 0.4), 0.1)
	
	# Then fade out
	deletion_tween.tween_property(line_2d, "default_color", Color(1.0, 0.2, 0.2, 0.0), 0.3).set_delay(0.1)
	deletion_tween.tween_property(polygon_2d, "color", Color(1.0, 0.2, 0.2, 0.0), 0.3).set_delay(0.1)
	deletion_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.3).set_delay(0.1)
