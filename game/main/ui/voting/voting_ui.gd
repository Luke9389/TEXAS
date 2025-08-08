class_name VotingUI
extends Control

@export var vote_button: Button

func _ready():
	_connect_signals()
	_setup_ui()

func _connect_signals():
	# Connect vote button - signals up to Main
	if vote_button:
		vote_button.pressed.connect(_on_vote_button_pressed)
	
	# Connect to SignalBus for reactive updates
	SignalBus.districts_modified.connect(_on_districts_modified)
	SignalBus.voting_started.connect(_on_voting_started)
	SignalBus.all_voting_complete.connect(_on_all_voting_complete)

func _setup_ui():
	if vote_button:
		vote_button.text = "VOTE!"
		vote_button.disabled = true  # Start disabled until districts exist

# Emits signal to Main to start voting
func _on_vote_button_pressed() -> void:
	SignalBus.vote_requested.emit()

# Updates button state when districts change
func _on_districts_modified(districts: Array[DistrictData]) -> void:
	if vote_button:
		var district_count = districts.size()
		vote_button.disabled = (district_count == 0)
		
		if vote_button.text == "Voting...":
			return  # Don't change text during voting
		
		if district_count == 0:
			vote_button.text = "Create Districts"
		else:
			vote_button.text = "VOTE!"

# Sets vote button state to "Voting..."
func _on_voting_started() -> void:
	if vote_button:
		vote_button.disabled = true
		vote_button.text = "Voting..."

# Resets vote button when all voting is complete
func _on_all_voting_complete(_results: Array[VotingResult]) -> void:
	if vote_button:
		vote_button.disabled = false
		vote_button.text = "VOTE!"