class_name VotingResult
extends Resource

@export var district_id: String = ""
@export var green_votes: int = 0
@export var orange_votes: int = 0
@export var winning_party: GameTypes.Party = GameTypes.Party.NONE
@export var was_runoff: bool = false
@export var round_number: int = 1
@export var total_pips: int = 0
@export var turnout_percentage: float = 0.0

func get_total_votes() -> int:
	return green_votes + orange_votes

func is_tie() -> bool:
	return green_votes == orange_votes

func is_valid() -> bool:
	return district_id != "" and get_total_votes() >= 0

func calculate_winning_party() -> GameTypes.Party:
	if green_votes > orange_votes:
		winning_party = GameTypes.Party.GREEN
	elif orange_votes > green_votes:
		winning_party = GameTypes.Party.ORANGE
	else:
		winning_party = GameTypes.Party.NONE
	return winning_party

func get_vote_margin() -> int:
	return abs(green_votes - orange_votes)

func get_winner_vote_count() -> int:
	return max(green_votes, orange_votes)

func get_loser_vote_count() -> int:
	return min(green_votes, orange_votes)

func calculate_turnout_percentage() -> float:
	if total_pips == 0:
		turnout_percentage = 0.0
	else:
		turnout_percentage = (float(get_total_votes()) / float(total_pips)) * 100.0
	return turnout_percentage

func set_vote_counts(green: int, orange: int, total: int) -> void:
	green_votes = green
	orange_votes = orange
	total_pips = total
	calculate_winning_party()
	calculate_turnout_percentage()

func add_vote(party: GameTypes.Party) -> void:
	match party:
		GameTypes.Party.GREEN:
			green_votes += 1
		GameTypes.Party.ORANGE:
			orange_votes += 1

func reset_votes() -> void:
	green_votes = 0
	orange_votes = 0
	winning_party = GameTypes.Party.NONE

func clone() -> VotingResult:
	var new_result = VotingResult.new()
	new_result.district_id = district_id
	new_result.green_votes = green_votes
	new_result.orange_votes = orange_votes
	new_result.winning_party = winning_party
	new_result.was_runoff = was_runoff
	new_result.round_number = round_number
	new_result.total_pips = total_pips
	new_result.turnout_percentage = turnout_percentage
	return new_result

func to_log_string() -> String:
	var party_name = "TIE"
	match winning_party:
		GameTypes.Party.GREEN:
			party_name = "GREEN"
		GameTypes.Party.ORANGE:
			party_name = "ORANGE"
	
	var runoff_text = " (RUNOFF)" if was_runoff else ""
	return "VotingResult(district=%s, votes=G:%d/O:%d, winner=%s, round=%d, turnout=%.1f%%)%s" % [
		district_id, green_votes, orange_votes, party_name, round_number, turnout_percentage, runoff_text
	]
