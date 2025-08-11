class_name VotingManager
extends Node

# Decoupled voting simulation manager - communicates only via SignalBus
# Zero direct dependencies on other game systems

# Constants from original implementation
const VOTING_DISTRICT_DELAY = 1.0
const VOTING_PIP_DELAY = 0.15
const TURNOUT_RATE = 0.8  # 80% of pips vote

# Internal state
var current_districts: Array[DistrictData] = []
var current_pips: Array[PipData] = []
var voting_results: Array[VotingResult] = []
var is_voting_active: bool = false

func _ready():
	print("[VotingManager] Initialized - ready to handle voting simulations")

# Main entry point - called directly by Main
func start_voting(districts: Array[DistrictData]) -> void:
	if is_voting_active:
		push_warning("[VotingManager] Voting already in progress!")
		return
	
	if districts.is_empty():
		push_warning("[VotingManager] No districts provided for voting!")
		SignalBus.all_voting_complete.emit([])
		return
	
	# Extract pip data from districts
	var all_pips: Array[PipData] = []
	for district in districts:
		all_pips.append_array(district.pip_data)
	
	print("[VotingManager] Starting voting simulation with ", districts.size(), " districts and ", all_pips.size(), " pips")
	
	is_voting_active = true
	current_districts = districts
	current_pips = all_pips
	voting_results.clear()
	
	# Reset all pip voting states
	_reset_all_pip_voting_states()
	
	SignalBus.voting_started.emit()
	
	# Start the sequential voting process
	await _simulate_voting_rounds()
	
	is_voting_active = false
	SignalBus.all_voting_complete.emit(voting_results)

# Reset all pip voting states to NOT_VOTED
func _reset_all_pip_voting_states() -> void:
	for pip_data in current_pips:
		pip_data.reset_voting()

# Main voting simulation with runoff handling
func _simulate_voting_rounds() -> void:
	var round_number = 1
	var districts_to_vote = current_districts.duplicate()
	
	# First round - general election
	print("[VotingManager] === ROUND ", round_number, ": General Election ===")
	SignalBus.voting_round_started.emit(round_number, false)
	
	var tied_districts: Array[DistrictData] = []
	
	# Process each district sequentially
	for i in range(districts_to_vote.size()):
		var district = districts_to_vote[i]
		print("[VotingManager] Starting voting for district ", district.id)
		
		# Wait for previous district to finish (except first district)
		if i > 0:
			await get_tree().create_timer(VOTING_DISTRICT_DELAY).timeout
		
		# Simulate voting for this district
		var result = await _simulate_district_voting(district, round_number, false)
		voting_results.append(result)
		
		# Check if this district tied
		if result.is_tie():
			tied_districts.append(district)
			print("[VotingManager] District ", district.id, " tied, will need runoff")
	
	# Keep running runoff rounds until no ties remain
	while not tied_districts.is_empty():
		round_number += 1
		print("[VotingManager] === ROUND ", round_number, ": Runoff Elections ===")
		print("[VotingManager] Found ", tied_districts.size(), " tied districts, starting runoff round")
		
		SignalBus.voting_round_started.emit(round_number, true)
			
		# Wait a bit before starting runoffs
		await get_tree().create_timer(VOTING_DISTRICT_DELAY * 2).timeout
		
		var still_tied_districts: Array[DistrictData] = []
		
		# Process each tied district
		for i in range(tied_districts.size()):
			var district = tied_districts[i]
			print("[VotingManager] Starting runoff election for district ", district.id)
			
			# Wait between runoff districts
			if i > 0:
				await get_tree().create_timer(VOTING_DISTRICT_DELAY).timeout
			
			# Run the voting again for this tied district
			var result = await _simulate_district_voting(district, round_number, true)
			
			# Update the existing result or add new runoff result
			_update_voting_result(district.id, result)
			
			# If still tied, add to next round
			if result.is_tie():
				still_tied_districts.append(district)
				print("[VotingManager] District ", district.id, " still tied after round ", round_number)
			else:
				print("[VotingManager] District ", district.id, " resolved in round ", round_number, ", winner: ", result.winning_party)
		
		# Update tied districts list for potential next round
		tied_districts = still_tied_districts
	
	print("[VotingManager] All districts resolved after ", round_number, " rounds!")

# Simulate voting for a single district
func _simulate_district_voting(district_data: DistrictData, round_number: int, is_runoff: bool) -> VotingResult:
	SignalBus.district_voting_started.emit(district_data.id)
	
	# Get pips in this district
	var district_pips = _get_pips_in_district(district_data)
	
	# Create voting result
	var result = VotingResult.new()
	result.district_id = district_data.id
	result.round_number = round_number
	result.was_runoff = is_runoff
	result.total_pips = district_pips.size()
	
	# Reset votes for runoff elections
	if is_runoff:
		for pip_data in district_pips:
			pip_data.reset_voting()
	
	var green_votes = 0
	var orange_votes = 0
	
	# Process each pip with a delay
	for i in range(district_pips.size()):
		var pip_data = district_pips[i]
		
		# Wait before this pip votes (except first pip)
		if i > 0:
			await get_tree().create_timer(VOTING_PIP_DELAY).timeout
		
		# Determine if this pip votes (80% chance)
		if randf() < TURNOUT_RATE:
			pip_data.vote()
			if pip_data.party == GameTypes.Party.GREEN:
				green_votes += 1
			elif pip_data.party == GameTypes.Party.ORANGE:
				orange_votes += 1
		else:
			pip_data.abstain()
		
		# Emit signal for each pip vote via SignalBus
		SignalBus.pip_voted.emit(pip_data)
	
	# Small pause before finalizing result
	await get_tree().create_timer(0.3).timeout
	
	# Set vote counts and determine winner
	result.set_vote_counts(green_votes, orange_votes, district_pips.size())
	
	print("[VotingManager] District ", district_data.id, " voted - Green: ", green_votes, " Orange: ", orange_votes, " Winner: ", result.winning_party, " Turnout: ", result.turnout_percentage, "%")
	
	SignalBus.district_voting_complete.emit(result)
	return result

# Get all pips that belong to a specific district
func _get_pips_in_district(district_data: DistrictData) -> Array[PipData]:
	var district_pips: Array[PipData] = []
	
	for pip_data in current_pips:
		if pip_data.id in district_data.pip_ids:
			district_pips.append(pip_data)
	
	return district_pips

# Helper to get array of district IDs
func _get_district_ids(districts: Array[DistrictData]) -> Array[String]:
	var ids: Array[String] = []
	for district in districts:
		ids.append(district.id)
	return ids

# Update an existing voting result or add a new one
func _update_voting_result(district_id: String, new_result: VotingResult) -> void:
	for i in range(voting_results.size()):
		if voting_results[i].district_id == district_id:
			voting_results[i] = new_result
			return
	
	# If not found, add new result
	voting_results.append(new_result)

# === QUERY METHODS FOR TESTING AND DEBUGGING ===
func is_voting_in_progress() -> bool:
	return is_voting_active

func get_current_results() -> Array[VotingResult]:
	return voting_results.duplicate()

func get_districts_count() -> int:
	return current_districts.size()

func get_pips_count() -> int:
	return current_pips.size()

func get_current_round_info() -> Dictionary:
	return {
		"is_active": is_voting_active,
		"district_count": current_districts.size(),
		"pip_count": current_pips.size(),
		"results_count": voting_results.size()
	}
