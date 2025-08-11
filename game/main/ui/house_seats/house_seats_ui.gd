class_name HouseSeatsUI
extends Control

@export var blue_chair_texture: Texture2D = preload("res://assets/textures/chairs/blue-chair@4x.png")
@export var green_chair_texture: Texture2D = preload("res://assets/textures/chairs/green-chair@4x.png")
@export var orange_chair_texture: Texture2D = preload("res://assets/textures/chairs/orange-chair@4x.png")

var seat_textures: Array[TextureRect] = []
var district_to_seat_map: Dictionary = {}  # district_id -> seat_index
var current_districts: Array[DistrictData] = []

func _ready():
	_collect_seat_nodes()
	_connect_signals()
	_initialize_seats()

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
	# Connect to SignalBus for reactive updates
	SignalBus.districts_modified.connect(_on_districts_modified)
	SignalBus.district_voting_started.connect(_on_district_voting_started)
	SignalBus.district_voting_complete.connect(_on_district_voting_complete)

func _initialize_seats():
	for seat in seat_textures:
		seat.texture = blue_chair_texture
		seat.modulate = Color.WHITE

func _on_districts_modified(districts: Array[DistrictData]):
	current_districts = districts
	
	# Build set of current district IDs
	var new_district_ids = {}
	for district in districts:
		new_district_ids[district.id] = district
	
	# Remove seats for deleted districts
	var districts_to_remove = []
	for district_id in district_to_seat_map:
		if not new_district_ids.has(district_id):
			districts_to_remove.append(district_id)
	
	for district_id in districts_to_remove:
		district_to_seat_map.erase(district_id)
	
	# Reassign all seats based on current districts
	_reassign_all_seats()

func _reassign_all_seats():
	# Clear current assignments
	district_to_seat_map.clear()
	_initialize_seats()
	
	# Assign seats to districts in order
	for i in range(min(current_districts.size(), seat_textures.size())):
		var district = current_districts[i]
		district_to_seat_map[district.id] = i
		_set_seat_texture_for_party(i, district.winning_party)

func _on_district_voting_started(district_id: String):
	# Start pulsing animation for the district that's voting
	start_voting_animation_for_district(district_id)

func _on_district_voting_complete(result: VotingResult):
	# Update the seat color based on voting result
	if result.district_id in district_to_seat_map:
		var seat_index = district_to_seat_map[result.district_id]
		_stop_seat_animation(seat_index)
		_set_seat_texture_for_party(seat_index, result.winning_party)

func _set_seat_texture_for_party(seat_index: int, party: GameTypes.Party):
	if seat_index < 0 or seat_index >= seat_textures.size():
		return
	
	var seat = seat_textures[seat_index]
	
	match party:
		GameTypes.Party.GREEN:
			seat.texture = green_chair_texture
		GameTypes.Party.ORANGE:
			seat.texture = orange_chair_texture
		_:
			seat.texture = blue_chair_texture
	
	seat.modulate = Color.WHITE

func start_voting_animation_for_district(district_id: String):
	if district_id in district_to_seat_map:
		var seat_index = district_to_seat_map[district_id]
		_animate_seat_voting(seat_index)

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

func reset_seats():
	district_to_seat_map.clear()
	_initialize_seats()