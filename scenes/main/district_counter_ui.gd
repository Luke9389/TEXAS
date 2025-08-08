class_name DistrictCounterUI
extends Control

# Constants
const DEFAULT_FONT_SIZE = 16
const FLASH_DURATION = 0.2
const DEFAULT_MAX_DISTRICTS = 5
const VOTING_DISTRICT_DELAY = 1.0
const VOTING_PIP_DELAY = 0.15

@export var green_label: Label
@export var orange_label: Label
@export var gray_label: Label
@export var districts_progress: ProgressBar
@export var districts_label: Label
@export var vote_button: Button
@export var district_manager_path: NodePath = "../DistrictManager"
@export var house_seats_ui_path: NodePath = "../HouseSeatsUI"

var district_manager: DistrictManager
var house_seats_ui: HouseSeatsUI

func _ready():
	# Find the district manager in the scene
	if district_manager_path:
		district_manager = get_node_or_null(district_manager_path) as DistrictManager
	
	if not district_manager:
		push_warning("DistrictCounterUI: Could not find DistrictManager at path: " + str(district_manager_path))
	
	# Find the house seats UI
	if house_seats_ui_path:
		house_seats_ui = get_node_or_null(house_seats_ui_path) as HouseSeatsUI
	
	if not house_seats_ui:
		push_warning("DistrictCounterUI: Could not find HouseSeatsUI at path: " + str(house_seats_ui_path))
	
	if district_manager:
		district_manager.district_created.connect(_on_district_created)
		district_manager.district_deleted.connect(_on_district_deleted)
		district_manager.district_limit_reached.connect(_on_district_limit_reached)
	
	# Connect vote button
	if vote_button:
		vote_button.pressed.connect(_on_vote_button_pressed)
		vote_button.text = "Vote!"
		vote_button.disabled = true  # Start disabled
	
	# Style the labels
	setup_label_styling()
	
	# Initialize labels
	update_district_counts()

func _on_district_created(_district: DistrictArea):
	update_district_counts()
	_update_vote_button_state()
	_reset_vote_button_after_district_change()

func _on_district_deleted(_district: DistrictArea):
	update_district_counts()
	_update_vote_button_state()
	_reset_vote_button_after_district_change()

func _on_district_limit_reached():
	# Flash both the progress bar and label red to indicate limit reached
	var nodes_to_flash: Array[Node] = []
	if districts_progress:
		nodes_to_flash.append(districts_progress)
	if districts_label:
		nodes_to_flash.append(districts_label)
	
	if not nodes_to_flash.is_empty():
		AnimationUtilities.flash_multiple_nodes(nodes_to_flash, Color.RED, FLASH_DURATION, Color.WHITE)

func update_district_counts():
	if not district_manager:
		if green_label:
			green_label.text = "🟢 Green: 0"
		if orange_label:
			orange_label.text = "🟠 Orange: 0"
		if gray_label:
			gray_label.text = "⚪ Tied: 0"
		if districts_progress:
			districts_progress.max_value = DEFAULT_MAX_DISTRICTS
			districts_progress.value = DEFAULT_MAX_DISTRICTS  # Start full (showing remaining)
		if districts_label:
			districts_label.text = "Districts: " + str(DEFAULT_MAX_DISTRICTS)
		return
	
	var summary = DistrictStatistics.get_all_districts_summary(district_manager.get_all_districts())
	var green_count = summary.districts_green
	var orange_count = summary.districts_orange
	var gray_count = summary.districts_tied
	
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
			districts_progress.modulate = PartyColors.PROGRESS_RED
		elif remaining <= 2:
			districts_progress.modulate = PartyColors.PROGRESS_YELLOW
		else:
			districts_progress.modulate = PartyColors.PROGRESS_BLUE
	
	# Update districts label
	if districts_label:
		var remaining = district_manager.get_remaining_districts()
		districts_label.text = "Districts: " + str(remaining)

func get_district_summary() -> Dictionary:
	if not district_manager:
		return {"green": 0, "orange": 0, "gray": 0, "total": 0}
	
	var summary = DistrictStatistics.get_all_districts_summary(district_manager.get_all_districts())
	var green_count = summary.districts_green
	var orange_count = summary.districts_orange
	var gray_count = summary.districts_tied
	
	return {
		"green": green_count,
		"orange": orange_count,
		"gray": gray_count,
		"total": summary.total_districts
	}

func setup_label_styling():
	# Set up font styling and colors for labels
	if green_label:
		green_label.modulate = PartyColors.GREEN
		green_label.add_theme_font_size_override("font_size", DEFAULT_FONT_SIZE)
	
	if orange_label:
		orange_label.modulate = PartyColors.ORANGE
		orange_label.add_theme_font_size_override("font_size", DEFAULT_FONT_SIZE)
	
	if gray_label:
		gray_label.modulate = PartyColors.GRAY
		gray_label.add_theme_font_size_override("font_size", DEFAULT_FONT_SIZE)
	
	if districts_progress:
		districts_progress.modulate = PartyColors.PROGRESS_BLUE
		# Configure the progress bar
		districts_progress.max_value = DEFAULT_MAX_DISTRICTS
		districts_progress.value = DEFAULT_MAX_DISTRICTS  # Start full
		districts_progress.show_percentage = false
	
	if districts_label:
		districts_label.modulate = Color.WHITE
		districts_label.add_theme_font_size_override("font_size", DEFAULT_FONT_SIZE)
		districts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# Check if all pips are accounted for in districts
func _are_all_pips_districted() -> bool:
	if not district_manager:
		return false
	
	var all_pips = district_manager.get_all_pips()
	var districted_pips = 0
	
	# Count pips in all districts
	for district in district_manager.get_all_districts():
		districted_pips += district.contained_pips.size()
	
	return districted_pips == all_pips.size()

# Update the vote button's enabled state
func _update_vote_button_state():
	if not vote_button:
		return
	
	vote_button.disabled = not _are_all_pips_districted()

# Handle vote button press
func _on_vote_button_pressed():
	if not district_manager:
		return
	
	print("Starting voting simulation...")
	_simulate_voting()

# Simulate voting with 80% turnout per pip
func _simulate_voting():
	# First reset all pips to not voted status
	_reset_all_pip_voting()
	
	# Disable vote button during animation
	if vote_button:
		vote_button.disabled = true
		vote_button.text = "Voting..."
	
	# Start the sequential voting animation
	_animate_voting_by_district()

# Animate voting district by district
func _animate_voting_by_district():
	var districts = district_manager.get_all_districts()
	if districts.is_empty():
		_finish_voting()
		return
	
	var round_number = 1
	var tied_districts: Array[DistrictArea] = []
	
	print("=== ROUND ", round_number, ": General Election ===")
	
	# Process each district sequentially in the first round
	for i in range(districts.size()):
		var district = districts[i]
		print("Starting voting for district ", i + 1)
		
		# Wait for previous district to finish (except first district)
		if i > 0:
			await get_tree().create_timer(VOTING_DISTRICT_DELAY).timeout
		
		# Animate pips in this district
		var winning_party = await _animate_district_voting(district)
		
		# Check if this district tied
		if winning_party == PipArea.Party.NONE:
			tied_districts.append(district)

	# Keep running runoff rounds until no ties remain
	while not tied_districts.is_empty():
		round_number += 1
		print("=== ROUND ", round_number, ": Runoff Elections ===")
		print("Found ", tied_districts.size(), " tied districts, starting runoff round ", round_number - 1, "...")
		
		# Update vote button text to show current runoff round
		if vote_button:
			if round_number == 2:
				vote_button.text = "Runoff Election..."
			else:
				vote_button.text = "Runoff Round " + str(round_number - 1) + "..."
		
		# Wait a bit before starting runoffs
		await get_tree().create_timer(VOTING_DISTRICT_DELAY * 2).timeout
		
		var still_tied_districts: Array[DistrictArea] = []
		
		# Process each tied district
		for i in range(tied_districts.size()):
			var district = tied_districts[i]
			print("Starting runoff election for tied district")
			
			# Wait between runoff districts
			if i > 0:
				await get_tree().create_timer(VOTING_DISTRICT_DELAY).timeout
			
			# Run the voting again for this tied district
			var winning_party = await _animate_district_voting(district)
			
			# If still tied, add to next round
			if winning_party == PipArea.Party.NONE:
				still_tied_districts.append(district)
				print("District still tied after round ", round_number, ", will continue to next round")
			else:
				print("District resolved in round ", round_number, ", winner: ", winning_party)
		
		# Update tied districts list for potential next round
		tied_districts = still_tied_districts

	# All districts done
	print("All districts resolved after ", round_number, " rounds!")
	_finish_voting()

# Animate voting for pips in a single district
func _animate_district_voting(district: DistrictArea) -> PipArea.Party:
	# Set the district to voting state (blue flashing)
	if district.has_method("set_voting_state"):
		district.set_voting_state(true)
	
	# Notify house seats UI that this district is being voted on
	if house_seats_ui:
		house_seats_ui.start_voting_for_district(district)
	
	var green_votes = 0
	var orange_votes = 0
	
	# Process each pip with a delay
	for i in range(district.contained_pips.size()):
		var pip = district.contained_pips[i]
		
		# Wait before this pip votes (except first pip)
		if i > 0:
			await get_tree().create_timer(VOTING_PIP_DELAY).timeout
		
		# Determine if this pip votes (80% chance)
		if randf() < 0.8:  # 80% turnout
			pip.set_vote_status(pip.VoteStatus.VOTED)
			if pip.party == PipArea.Party.GREEN:
				green_votes += 1
			elif pip.party == PipArea.Party.ORANGE:
				orange_votes += 1
		else:
			pip.set_vote_status(pip.VoteStatus.DID_NOT_VOTE)
	
	# Small pause before updating district colors
	await get_tree().create_timer(0.3).timeout
	
	# Determine winner and update district
	var winning_party: PipArea.Party
	if green_votes > orange_votes:
		winning_party = PipArea.Party.GREEN
	elif orange_votes > green_votes:
		winning_party = PipArea.Party.ORANGE
	else:
		winning_party = PipArea.Party.NONE  # Tie
	
	# Stop the voting animation and update district colors based on actual votes
	if district.has_method("set_voting_state"):
		district.set_voting_state(false)
	
	# Set the post-voting party so colors persist
	if district.has_method("set_post_voting_party"):
		district.set_post_voting_party(winning_party)
	
	# Update the house seat immediately after this district finishes voting
	if house_seats_ui:
		house_seats_ui.finish_voting_for_district(district, winning_party)
	
	print("District voted - Green: ", green_votes, " Orange: ", orange_votes, " Winner: ", winning_party)
	return winning_party

# Finish the voting process
func _finish_voting():
	# Ensure all districts are back to normal state
	var districts = district_manager.get_all_districts()
	for district in districts:
		if district.has_method("set_voting_state"):
			district.set_voting_state(false)
	
	# Update the UI with final results
	update_district_counts()
	
	# Re-enable vote button
	if vote_button:
		vote_button.disabled = true
		vote_button.text = "Voting Complete"
	
	print("All districts have finished voting!")

# Reset all pips to not voted status
func _reset_all_pip_voting():
	if not district_manager:
		return
	
	var all_pips = district_manager.get_all_pips()
	for pip in all_pips:
		pip.reset_voting()
	
	# Also reset voting state for all districts
	var all_districts = district_manager.get_all_districts()
	for district in all_districts:
		if district.has_method("reset_voting_state"):
			district.reset_voting_state()

# Reset vote button when districts change so user can vote again
func _reset_vote_button_after_district_change():
	if vote_button:
		vote_button.text = "Vote!"
		# Button state will be handled by _update_vote_button_state()

func reset_counters():
	update_district_counts()
	_update_vote_button_state()
	_reset_vote_button_after_district_change()
	_reset_all_pip_voting()
	
	# Reset house seats
	if house_seats_ui:
		house_seats_ui.reset_seats()