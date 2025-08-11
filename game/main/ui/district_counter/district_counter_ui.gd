class_name DistrictCounterUI
extends Control

# Constants
const DEFAULT_MAX_DISTRICTS = 5

@export var green_label: Label
@export var orange_label: Label
@export var gray_label: Label
@export var districts_progress: ProgressBar
@export var districts_label: Label

func _ready():
	# Connect to SignalBus for district management
	SignalBus.districts_modified.connect(_on_districts_modified) # Comes with all district data



# Updates the district counter UI based on current districts
func _on_districts_modified(districts: Array[DistrictData]) -> void:
	# Count districts by winning party
	var green_count = 0
	var orange_count = 0
	var gray_count = 0
	
	for district in districts:
		match district.winning_party:
			GameTypes.Party.GREEN:
				green_count += 1
			GameTypes.Party.ORANGE:
				orange_count += 1
			GameTypes.Party.NONE:
				gray_count += 1
	
	# Update labels
	if green_label:
		green_label.text = "Green Districts: " + str(green_count)
	if orange_label:
		orange_label.text = "Orange Districts: " + str(orange_count)
	if gray_label:
		gray_label.text = "Undecided Districts: " + str(gray_count)
	
	# Update progress bar
	var total_districts = districts.size()
	if districts_progress:
		districts_progress.max_value = DEFAULT_MAX_DISTRICTS
		districts_progress.value = total_districts
	
	# Update districts label
	if districts_label:
		districts_label.text = str(total_districts) + "/" + str(DEFAULT_MAX_DISTRICTS) + " Districts"

