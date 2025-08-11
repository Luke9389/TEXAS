class_name DistrictData
extends Resource

@export var id: String = ""
@export var pip_ids: Array[String] = []
@export var pip_data: Array[PipData] = []  # Contains full pip data for voting
@export var polygon_points: PackedVector2Array = PackedVector2Array()
@export var position: Vector2 = Vector2.ZERO
@export var winning_party: GameTypes.Party = GameTypes.Party.NONE
@export var has_voted: bool = false

func get_pip_count() -> int:
	return pip_ids.size()

func add_pip_id(pip_id: String) -> void:
	if pip_id not in pip_ids:
		pip_ids.append(pip_id)

func remove_pip_id(pip_id: String) -> void:
	pip_ids.erase(pip_id)

func has_pip(pip_id: String) -> bool:
	return pip_id in pip_ids

func clear_pips() -> void:
	pip_ids.clear()

func is_valid() -> bool:
	return id != "" and polygon_points.size() >= 3

func get_area() -> float:
	if polygon_points.size() < 3:
		return 0.0
	
	var area = 0.0
	for i in range(polygon_points.size() - 1):
		area += polygon_points[i].x * polygon_points[i + 1].y
		area -= polygon_points[i + 1].x * polygon_points[i].y
	
	return abs(area) / 2.0

func clone() -> DistrictData:
	var new_district = DistrictData.new()
	new_district.id = id
	new_district.pip_ids = pip_ids.duplicate()
	new_district.pip_data = pip_data.duplicate()
	new_district.polygon_points = polygon_points.duplicate()
	new_district.position = position
	new_district.winning_party = winning_party
	new_district.has_voted = has_voted
	return new_district