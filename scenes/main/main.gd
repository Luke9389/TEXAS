extends Node

# Central coordinator for game state and flow
# Follows "Call Down, Signal Up" pattern:
# - Listens to UI/Input signals (up)
# - Calls manager methods directly (down)
# - Managers emit SignalBus events for reactive UI

# Manager references (call down)
@onready var district_manager: DistrictManager = $GameplayManagement/DistrictManager
@onready var voting_manager: VotingManager = $VotingManager
@onready var pip_spawner: PipSpawner = $GameplayManagement/PipSpawner

# Input handler reference
@onready var district_input_handler: DistrictInputHandler = $GameplayManagement/InputHandler

func _ready():
	_connect_input_signals()
	_connect_signalbus_signals()

# Connect to input systems that signal up to Main
func _connect_input_signals():
	if district_input_handler:
		district_input_handler.district_creation_requested.connect(_on_district_creation_requested)
		district_input_handler.district_deletion_requested.connect(_on_district_deletion_requested)

# Connect to SignalBus for UI requests
func _connect_signalbus_signals():
	SignalBus.vote_requested.connect(_on_vote_requested)
	SignalBus.regenerate_map_requested.connect(_on_regenerate_map_requested)
	SignalBus.set_generation_strategy_requested.connect(_on_set_generation_strategy_requested)

# === DISTRICT MANAGEMENT ===
# Called when user completes drawing a district
func _on_district_creation_requested(district: DistrictArea):
	if district_manager:
		var success = district_manager.register_completed_district(district)
		if success:
			print("[Main] District created successfully")
		else:
			print("[Main] District creation failed - likely validation error")

# Called when user clicks to delete a district
func _on_district_deletion_requested(district: DistrictArea):
	if district_manager:
		var success = await district_manager.delete_district(district)
		if success:
			print("[Main] District deleted successfully")
		else:
			print("[Main] District deletion failed")

# === VOTING SYSTEM ===
# Called when user presses Vote button (via SignalBus)
func _on_vote_requested():
	if not voting_manager or not district_manager:
		print("[Main] Cannot start voting - missing managers")
		return
	
	# Get district data from DistrictManager (includes pip data)
	var district_data: Array[DistrictData] = district_manager.get_district_data()
	
	# Start voting process
	voting_manager.start_voting(district_data)
	print("[Main] Started voting with ", district_data.size(), " districts")

# === DEV TOOLS ===
# Called when user requests map regeneration (via SignalBus)
func _on_regenerate_map_requested():
	if district_manager and pip_spawner:
		# Clear existing districts and pips
		district_manager.clear_all_districts()
		
		# Regenerate pips with current strategy
		pip_spawner.regenerate_pips()
		
		print("[Main] Map regenerated")

# Called when user changes pip spawn strategy (via SignalBus)
func _on_set_generation_strategy_requested(strategy: String):
	if pip_spawner and pip_spawner.has_method("set_spawn_strategy"):
		pip_spawner.set_spawn_strategy(strategy)
		print("[Main] Set spawn strategy to: ", strategy)
