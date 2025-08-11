class_name DistrictArea
extends Area2D

# Visual constants
const LINE_WIDTH_DEFAULT = 3.0
const MIN_POINT_DISTANCE = 10.0
const MIN_POLYGON_POINTS = 3
const ANIMATION_FLASH_DURATION = 0.1
const ANIMATION_FADE_DURATION = 0.3
const ANIMATION_TOTAL_DURATION = 0.4

@export var line_width: float = LINE_WIDTH_DEFAULT
@export var min_point_distance: float = MIN_POINT_DISTANCE
@export var min_polygon_points: int = MIN_POLYGON_POINTS

var is_drawing: bool = false
var polygon_points: PackedVector2Array = []
var contained_pips: Array[PipArea] = []
var district_manager: Node2D = null
var currently_enclosed_pips: Array[PipArea] = []
var post_voting_party: GameTypes.Party = GameTypes.Party.NONE
var has_voted: bool = false

var line_2d: Line2D
var polygon_2d: Polygon2D
var collision_polygon: CollisionPolygon2D

signal district_completed(district: DistrictArea)
signal pip_enclosed_while_drawing(pip: PipArea)
signal pip_released_while_drawing(pip: PipArea)

var deletion_tween: Tween
var voting_tween: Tween

func _ready():
	line_2d = Line2D.new()
	line_2d.width = line_width
	line_2d.default_color = PartyColors.get_default_border_color()
	line_2d.joint_mode = Line2D.LINE_JOINT_ROUND
	line_2d.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line_2d.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(line_2d)
	
	polygon_2d = Polygon2D.new()
	polygon_2d.color = PartyColors.get_default_fill_color()
	add_child(polygon_2d)
	
	collision_polygon = get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if not collision_polygon:
		push_warning("DistrictArea: CollisionPolygon2D node not found, creating one")
		collision_polygon = CollisionPolygon2D.new()
		add_child(collision_polygon)
	
	# Connect to SignalBus for voting result updates
	SignalBus.district_voting_complete.connect(_on_district_voting_complete)

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
	
	if line_2d:
		line_2d.points = polygon_points
	if polygon_2d:
		polygon_2d.polygon = polygon_points
	if collision_polygon:
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
				# Only claim pips that aren't already in another district
				if not _is_pip_already_claimed(pip):
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
			# Check if this pip already belongs to another district
			if _is_pip_already_claimed(pip):
				continue  # Skip pips that are already in a district
			
			newly_enclosed.append(pip)
			
			# Check if this is a newly enclosed pip
			if pip not in currently_enclosed_pips:
				pip_enclosed_while_drawing.emit(pip)
				# Visual feedback - make the pip glow or change color
				pip.modulate = Color.WHITE * PartyColors.PIP_HIGHLIGHT_FACTOR
			
			still_enclosed.append(pip)
	
	# Check for pips that were enclosed but are no longer enclosed
	for pip in currently_enclosed_pips:
		if pip not in newly_enclosed:
			pip_released_while_drawing.emit(pip)
			# Reset visual feedback
			pip.modulate = Color.WHITE
	
	currently_enclosed_pips = still_enclosed
	
	# Update district colors in real-time based on currently enclosed pips
	update_district_colors_realtime()

func get_polygon_points() -> PackedVector2Array:
	return polygon_points

func set_polygon_points(new_points: PackedVector2Array):
	polygon_points = new_points
	if line_2d:
		line_2d.points = polygon_points
	if polygon_2d:
		polygon_2d.polygon = polygon_points
	if collision_polygon:
		collision_polygon.polygon = polygon_points
	# Re-check contained pips with new boundary
	check_contained_pips()
	update_district_colors()

func get_area() -> float:
	return DistrictStatistics.calculate_polygon_area(polygon_points)

func get_pip_counts() -> Dictionary:
	return DistrictStatistics.count_pips_by_party(contained_pips)

func get_winning_party() -> GameTypes.Party:
	return DistrictStatistics.get_winning_party(contained_pips)

func update_district_colors():
	_apply_colors_for_party(get_winning_party())

func update_district_colors_realtime():
	var winning_party = DistrictStatistics.get_winning_party(currently_enclosed_pips)
	_apply_colors_for_party(winning_party, true)

func animate_deletion():
	# Create a deletion animation - flash red then fade out
	deletion_tween = create_tween()
	deletion_tween.set_parallel(true)
	
	# Flash red
	var flash_border = PartyColors.DELETION_RED
	flash_border.a = PartyColors.BORDER_ALPHA
	var flash_fill = PartyColors.DELETION_RED
	flash_fill.a = 0.4
	
	deletion_tween.tween_property(line_2d, "default_color", flash_border, ANIMATION_FLASH_DURATION)
	deletion_tween.tween_property(polygon_2d, "color", flash_fill, ANIMATION_FLASH_DURATION)
	
	# Then fade out
	var fade_border = PartyColors.DELETION_RED
	fade_border.a = 0.0
	var fade_fill = PartyColors.DELETION_RED
	fade_fill.a = 0.0
	
	deletion_tween.tween_property(line_2d, "default_color", fade_border, ANIMATION_FADE_DURATION).set_delay(ANIMATION_FLASH_DURATION)
	deletion_tween.tween_property(polygon_2d, "color", fade_fill, ANIMATION_FADE_DURATION).set_delay(ANIMATION_FLASH_DURATION)
	deletion_tween.tween_property(self, "modulate", Color.TRANSPARENT, ANIMATION_FADE_DURATION).set_delay(ANIMATION_FLASH_DURATION)

# Helper function to apply colors based on party
func _apply_colors_for_party(party: GameTypes.Party, use_default_for_tie: bool = false):
	if not line_2d or not polygon_2d:
		return
	
	if party == GameTypes.Party.NONE and use_default_for_tie:
		line_2d.default_color = PartyColors.get_default_border_color()
		polygon_2d.color = PartyColors.get_default_fill_color()
	else:
		line_2d.default_color = PartyColors.get_party_border_color(party)
		polygon_2d.color = PartyColors.get_party_fill_color(party)

# Check if a pip is already claimed by another district
func _is_pip_already_claimed(pip: PipArea) -> bool:
	if not district_manager or not district_manager.has_method("get_all_districts"):
		return false
	
	var all_districts = district_manager.get_all_districts()
	for district in all_districts:
		if district == self:
			continue  # Skip self
		if district.contained_pips.has(pip):
			return true
	return false

# Visual feedback for voting state
func set_voting_state(is_voting: bool):
	if is_voting:
		_start_voting_animation()
	else:
		_stop_voting_animation()

func _start_voting_animation():
	# Stop any existing voting animation
	if voting_tween:
		voting_tween.kill()
	
	# Flash the district blue to indicate it's about to vote
	var voting_border = PartyColors.PROGRESS_BLUE
	voting_border.a = PartyColors.BORDER_ALPHA
	var voting_fill = PartyColors.PROGRESS_BLUE
	voting_fill.a = 0.3
	
	var original_border = line_2d.default_color
	var original_fill = polygon_2d.color
	
	# Use animation utilities for the looping flash
	var flash_duration = 0.5
	voting_tween = create_tween()
	voting_tween.set_parallel(true)
	voting_tween.set_loops()
	
	voting_tween.tween_property(line_2d, "default_color", voting_border, flash_duration)
	voting_tween.tween_property(polygon_2d, "color", voting_fill, flash_duration)
	voting_tween.tween_property(line_2d, "default_color", original_border, flash_duration).set_delay(flash_duration)
	voting_tween.tween_property(polygon_2d, "color", original_fill, flash_duration).set_delay(flash_duration)

func _stop_voting_animation():
	if voting_tween:
		voting_tween.kill()
		voting_tween = null
	
	# If we've voted, keep the post-voting colors
	# Otherwise restore normal colors
	if not has_voted:
		update_district_colors()

func set_post_voting_party(party: GameTypes.Party):
	post_voting_party = party
	has_voted = true
	_apply_colors_for_party(party)

func reset_voting_state():
	has_voted = false
	post_voting_party = GameTypes.Party.NONE
	update_district_colors()

# Handle voting completion signal from VotingManager
func _on_district_voting_complete(result: VotingResult) -> void:
	# Check if this result is for me
	var my_id = "district_" + str(get_instance_id())
	if result.district_id == my_id:
		set_post_voting_party(result.winning_party)

# Convert this district node to DistrictData for SignalBus communication
func to_district_data(district_index: int = 0) -> DistrictData:
	var district_data = DistrictData.new()
	district_data.id = "district_" + str(get_instance_id())
	district_data.position = position
	district_data.polygon_points = polygon_points
	district_data.winning_party = get_winning_party()
	district_data.has_voted = has_voted
	
	# Collect pip IDs from contained pips
	for pip in contained_pips:
		var pip_id = "pip_" + str(pip.get_instance_id())
		district_data.add_pip_id(pip_id)
	
	return district_data
