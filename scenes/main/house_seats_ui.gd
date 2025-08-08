class_name HouseSeatsUI
extends Control

@export var district_manager_path: NodePath = "../../GameplayManagement/DistrictManager"
@export var district_counter_ui_path: NodePath = "../DistrictCounterUI"

@export var blue_chair_texture: Texture2D = preload("res://assets/blue-chair@4x.png")
@export var green_chair_texture: Texture2D = preload("res://assets/green-chair@4x.png")
@export var orange_chair_texture: Texture2D = preload("res://assets/orange-chair@4x.png")

var district_manager: DistrictManager
var district_counter_ui: DistrictCounterUI
var seat_textures: Array[TextureRect] = []
var district_to_seat_map: Dictionary = {}

func _ready():
	_find_dependencies()
	_collect_seat_nodes()
	_connect_signals()
	_initialize_seats()

func _find_dependencies():
	if district_manager_path:
		district_manager = get_node_or_null(district_manager_path) as DistrictManager
	
	if district_counter_ui_path:
		district_counter_ui = get_node_or_null(district_counter_ui_path) as DistrictCounterUI
	
	if not district_manager:
		push_warning("HouseSeatsUI: Could not find DistrictManager at path: " + str(district_manager_path))
	
	if not district_counter_ui:
		push_warning("HouseSeatsUI: Could not find DistrictCounterUI at path: " + str(district_counter_ui_path))

func _collect_seat_nodes():
	var container = $HBoxContainer
	if not container:
		push_error("HouseSeatsUI: Could not find HBoxContainer")
		return
	
	for child in container.get_children():
		if child is TextureRect:
			seat_textures.append(child)
	
	print("HouseSeatsUI: Found ", seat_textures.size(), " seat nodes")

func _connect_signals():
	if district_manager:
		district_manager.district_created.connect(_on_district_created)
		district_manager.district_deleted.connect(_on_district_deleted)
		district_manager.districts_cleared.connect(_on_districts_cleared)

func _initialize_seats():
	for seat in seat_textures:
		seat.texture = blue_chair_texture
		seat.modulate = Color.WHITE

func _on_district_created(district: DistrictArea):
	_update_seat_for_district(district)

func _on_district_deleted(district: DistrictArea):
	if district in district_to_seat_map:
		var seat_index = district_to_seat_map[district]
		if seat_index < seat_textures.size():
			seat_textures[seat_index].texture = blue_chair_texture
			seat_textures[seat_index].modulate = Color.WHITE
		district_to_seat_map.erase(district)
	
	_reassign_all_seats()

func _on_districts_cleared():
	district_to_seat_map.clear()
	_initialize_seats()

func _update_seat_for_district(district: DistrictArea):
	var seat_index = _get_next_available_seat_index()
	if seat_index == -1:
		return
	
	district_to_seat_map[district] = seat_index
	
	var party = _get_district_party(district)
	_set_seat_texture_for_party(seat_index, party)

func _get_next_available_seat_index() -> int:
	var used_indices = district_to_seat_map.values()
	for i in range(seat_textures.size()):
		if i not in used_indices:
			return i
	return -1

func _get_district_party(district: DistrictArea) -> PipArea.Party:
	if district.has_method("get_winning_party"):
		return district.get_winning_party()
	return PipArea.Party.NONE

func _set_seat_texture_for_party(seat_index: int, party: PipArea.Party):
	if seat_index < 0 or seat_index >= seat_textures.size():
		return
	
	var seat = seat_textures[seat_index]
	
	match party:
		PipArea.Party.GREEN:
			seat.texture = green_chair_texture
		PipArea.Party.ORANGE:
			seat.texture = orange_chair_texture
		_:
			seat.texture = blue_chair_texture
	
	seat.modulate = Color.WHITE

func _reassign_all_seats():
	district_to_seat_map.clear()
	_initialize_seats()
	
	if not district_manager:
		return
	
	var districts = district_manager.get_all_districts()
	for district in districts:
		_update_seat_for_district(district)

func start_voting_for_district(district: DistrictArea):
	var seat_index = _get_seat_index_for_district(district)
	if seat_index != -1:
		_animate_seat_voting(seat_index)

func finish_voting_for_district(district: DistrictArea, winning_party: PipArea.Party):
	var seat_index = _get_seat_index_for_district(district)
	if seat_index != -1:
		_stop_seat_animation(seat_index)
		_set_seat_texture_for_party(seat_index, winning_party)

func _get_seat_index_for_district(district: DistrictArea) -> int:
	if district in district_to_seat_map:
		return district_to_seat_map[district]
	
	# If not in map, try to find by order
	var districts = district_manager.get_all_districts()
	for i in range(districts.size()):
		if districts[i] == district:
			return i
	return -1

func _animate_seat_voting(seat_index: int):
	if seat_index < 0 or seat_index >= seat_textures.size():
		return
	
	var seat = seat_textures[seat_index]
	
	# Create pulsing brightness animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(seat, "modulate", Color(1.5, 1.5, 1.5), 0.3)
	tween.tween_property(seat, "modulate", Color(1.2, 1.2, 1.2), 0.3)
	
	# Store tween reference so we can stop it later
	seat.set_meta("voting_tween", tween)

func _stop_seat_animation(seat_index: int):
	if seat_index < 0 or seat_index >= seat_textures.size():
		return
	
	var seat = seat_textures[seat_index]
	
	# Stop the tween
	if seat.has_meta("voting_tween"):
		var tween = seat.get_meta("voting_tween")
		if tween and is_instance_valid(tween):
			tween.kill()
		seat.remove_meta("voting_tween")
	
	# Reset modulate
	seat.modulate = Color.WHITE

func update_seats_after_voting():
	if not district_manager:
		return
	
	var districts = district_manager.get_all_districts()
	for i in range(min(districts.size(), seat_textures.size())):
		var district = districts[i]
		var party = _get_district_party_after_voting(district)
		_set_seat_texture_for_party(i, party)

func _get_district_party_after_voting(district: DistrictArea) -> PipArea.Party:
	var green_votes = 0
	var orange_votes = 0
	
	for pip in district.contained_pips:
		if pip.vote_status == pip.VoteStatus.VOTED:
			if pip.party == PipArea.Party.GREEN:
				green_votes += 1
			elif pip.party == PipArea.Party.ORANGE:
				orange_votes += 1
	
	if green_votes > orange_votes:
		return PipArea.Party.GREEN
	elif orange_votes > green_votes:
		return PipArea.Party.ORANGE
	else:
		return PipArea.Party.NONE

func reset_seats():
	district_to_seat_map.clear()
	_initialize_seats()