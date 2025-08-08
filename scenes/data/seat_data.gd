class_name SeatData
extends Resource

@export var seat_index: int = -1
@export var district_id: String = ""
@export var assigned_party: PipArea.Party = PipArea.Party.NONE
@export var is_voting: bool = false

func is_assigned() -> bool:
	return district_id != ""

func is_valid() -> bool:
	return seat_index >= 0

func assign_to_district(district_data: DistrictData) -> void:
	district_id = district_data.id
	assigned_party = district_data.winning_party

func clear_assignment() -> void:
	district_id = ""
	assigned_party = PipArea.Party.NONE
	is_voting = false

func set_voting_state(voting: bool) -> void:
	is_voting = voting

func update_party(party: PipArea.Party) -> void:
	assigned_party = party

func get_party_texture_name() -> String:
	match assigned_party:
		PipArea.Party.GREEN:
			return "green_chair"
		PipArea.Party.ORANGE:
			return "orange_chair"
		_:
			return "blue_chair"

func get_party_color() -> Color:
	return PartyColors.get_party_color(assigned_party)

func clone() -> SeatData:
	var new_seat = SeatData.new()
	new_seat.seat_index = seat_index
	new_seat.district_id = district_id
	new_seat.assigned_party = assigned_party
	new_seat.is_voting = is_voting
	return new_seat

func to_string() -> String:
	var party_name = "NONE"
	match assigned_party:
		PipArea.Party.GREEN:
			party_name = "GREEN"
		PipArea.Party.ORANGE:
			party_name = "ORANGE"
	
	return "SeatData(index=%d, district=%s, party=%s, voting=%s)" % [seat_index, district_id, party_name, is_voting]