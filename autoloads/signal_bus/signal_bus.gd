extends Node

# === Level Generation Signals ===
signal regenerate_map_requested()
signal set_generation_strategy_requested(strategy: String)


# === VOTING SYSTEM SIGNALS ===
signal vote_requested()
signal voting_started()
signal voting_round_started(round_number: int, is_runoff: bool)
signal district_voting_started(district_id: String)
signal pip_voted(pip_data: PipData)
signal all_voting_complete(results: Array[VotingResult])

# === DISTRICT MANAGEMENT SIGNALS === 
signal districts_modified(districts: Array[DistrictData])
signal district_voting_complete(result: VotingResult)
