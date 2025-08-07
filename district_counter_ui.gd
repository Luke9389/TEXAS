class_name DistrictCounterUI
extends Control

@export var green_label: Label
@export var orange_label: Label
@export var gray_label: Label
@export var districts_progress: ProgressBar
@export var districts_label: Label

var district_manager: DistrictManager

func _ready():
	# Find the district manager in the scene
	district_manager = get_node("../DistrictManager") as DistrictManager
	
	if district_manager:
		district_manager.district_created.connect(_on_district_created)
		district_manager.district_deleted.connect(_on_district_deleted)
		district_manager.district_limit_reached.connect(_on_district_limit_reached)
	
	# Style the labels
	setup_label_styling()
	
	# Initialize labels
	update_district_counts()

func _on_district_created(_district: DistrictArea):
	update_district_counts()

func _on_district_deleted(_district: DistrictArea):
	update_district_counts()

func _on_district_limit_reached():
	# Flash both the progress bar and label red to indicate limit reached
	if districts_progress:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(districts_progress, "modulate", Color.RED, 0.2)
		tween.tween_property(districts_progress, "modulate", Color.WHITE, 0.2).set_delay(0.2)
		if districts_label:
			tween.tween_property(districts_label, "modulate", Color.RED, 0.2)
			tween.tween_property(districts_label, "modulate", Color.WHITE, 0.2).set_delay(0.2)

func update_district_counts():
	if not district_manager:
		if green_label:
			green_label.text = "🟢 Green: 0"
		if orange_label:
			orange_label.text = "🟠 Orange: 0"
		if gray_label:
			gray_label.text = "⚪ Tied: 0"
		if districts_progress:
			districts_progress.max_value = 5
			districts_progress.value = 5  # Start full (showing remaining)
		if districts_label:
			districts_label.text = "Districts: 5"
		return
	
	var green_count = 0
	var orange_count = 0
	var gray_count = 0
	
	var all_districts = district_manager.get_all_districts()
	
	for district in all_districts:
		var winning_party = district.get_winning_party()
		match winning_party:
			PipArea.Party.GREEN:
				green_count += 1
			PipArea.Party.ORANGE:
				orange_count += 1
			PipArea.Party.NONE:
				gray_count += 1
	
	# Update label text with emoji and better formatting
	if green_label:
		green_label.text = "🟢 Green: " + str(green_count)
	if orange_label:
		orange_label.text = "🟠 Orange: " + str(orange_count)
	if gray_label:
		gray_label.text = "⚪ Tied: " + str(gray_count)
	
	# Update progress bar (showing remaining districts)
	if districts_progress:
		var remaining = district_manager.get_remaining_districts()
		districts_progress.max_value = district_manager.max_districts
		districts_progress.value = remaining  # Show remaining, not used
		
		# Update progress bar color based on remaining
		if remaining == 0:
			districts_progress.modulate = Color(1.0, 0.4, 0.4)  # Red when none left
		elif remaining <= 2:
			districts_progress.modulate = Color(1.0, 0.8, 0.0)  # Yellow when running low
		else:
			districts_progress.modulate = Color(0.4, 0.8, 1.0)  # Blue when plenty left
	
	# Update districts label
	if districts_label:
		var remaining = district_manager.get_remaining_districts()
		districts_label.text = "Districts: " + str(remaining)

func get_district_summary() -> Dictionary:
	if not district_manager:
		return {"green": 0, "orange": 0, "gray": 0, "total": 0}
	
	var green_count = 0
	var orange_count = 0
	var gray_count = 0
	
	var all_districts = district_manager.get_all_districts()
	
	for district in all_districts:
		var winning_party = district.get_winning_party()
		match winning_party:
			PipArea.Party.GREEN:
				green_count += 1
			PipArea.Party.ORANGE:
				orange_count += 1
			PipArea.Party.NONE:
				gray_count += 1
	
	return {
		"green": green_count,
		"orange": orange_count,
		"gray": gray_count,
		"total": all_districts.size()
	}

func setup_label_styling():
	# Set up font styling and colors for labels
	if green_label:
		green_label.modulate = Color(0.2, 0.8, 0.2)  # Green color
		green_label.add_theme_font_size_override("font_size", 16)
	
	if orange_label:
		orange_label.modulate = Color(1.0, 0.5, 0.0)  # Orange color
		orange_label.add_theme_font_size_override("font_size", 16)
	
	if gray_label:
		gray_label.modulate = Color(0.7, 0.7, 0.7)  # Gray color
		gray_label.add_theme_font_size_override("font_size", 16)
	
	if districts_progress:
		districts_progress.modulate = Color(0.4, 0.8, 1.0)  # Blue color initially
		# Configure the progress bar
		districts_progress.max_value = 5
		districts_progress.value = 5  # Start full
		districts_progress.show_percentage = false
	
	if districts_label:
		districts_label.modulate = Color.WHITE  # White text
		districts_label.add_theme_font_size_override("font_size", 16)
		districts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER