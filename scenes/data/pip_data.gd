class_name PipData
extends Resource

@export var id: String = ""
@export var party: PipArea.Party = PipArea.Party.NONE
@export var position: Vector2 = Vector2.ZERO
@export var vote_status: PipArea.VoteStatus = PipArea.VoteStatus.NOT_VOTED

func is_valid() -> bool:
	return id != ""

func get_party_color() -> Color:
	return PartyColors.get_party_color(party)

func set_random_party() -> void:
	party = PipArea.Party.GREEN if randf() < 0.5 else PipArea.Party.ORANGE

func has_voted() -> bool:
	return vote_status == PipArea.VoteStatus.VOTED

func did_not_vote() -> bool:
	return vote_status == PipArea.VoteStatus.DID_NOT_VOTE

func reset_voting() -> void:
	vote_status = PipArea.VoteStatus.NOT_VOTED

func vote() -> void:
	vote_status = PipArea.VoteStatus.VOTED

func abstain() -> void:
	vote_status = PipArea.VoteStatus.DID_NOT_VOTE

func clone() -> PipData:
	var new_pip = PipData.new()
	new_pip.id = id
	new_pip.party = party
	new_pip.position = position
	new_pip.vote_status = vote_status
	return new_pip

func to_string() -> String:
	var party_name = "NONE"
	match party:
		PipArea.Party.GREEN:
			party_name = "GREEN"
		PipArea.Party.ORANGE:
			party_name = "ORANGE"
	
	var status_name = "NOT_VOTED"
	match vote_status:
		PipArea.VoteStatus.VOTED:
			status_name = "VOTED"
		PipArea.VoteStatus.DID_NOT_VOTE:
			status_name = "DID_NOT_VOTE"
	
	return "PipData(id=%s, party=%s, vote_status=%s, pos=%s)" % [id, party_name, status_name, position]