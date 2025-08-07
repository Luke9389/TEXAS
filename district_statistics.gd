class_name DistrictStatistics
extends RefCounted

# Calculate pip counts for a collection of pips
static func count_pips_by_party(pips: Array) -> Dictionary:
	var counts = {"green": 0, "orange": 0}
	for pip in pips:
		if pip is PipArea:
			if pip.party == PipArea.Party.GREEN:
				counts.green += 1
			elif pip.party == PipArea.Party.ORANGE:
				counts.orange += 1
	return counts

# Determine winning party from pip counts
static func get_winning_party_from_counts(green_count: int, orange_count: int) -> PipArea.Party:
	if green_count > orange_count:
		return PipArea.Party.GREEN
	elif orange_count > green_count:
		return PipArea.Party.ORANGE
	else:
		return PipArea.Party.NONE

# Determine winning party from a collection of pips
static func get_winning_party(pips: Array) -> PipArea.Party:
	var counts = count_pips_by_party(pips)
	return get_winning_party_from_counts(counts.green, counts.orange)

# Calculate polygon area using shoelace formula
static func calculate_polygon_area(points: PackedVector2Array) -> float:
	if points.size() < 3:
		return 0.0
	
	var area = 0.0
	for i in range(points.size() - 1):
		area += points[i].x * points[i + 1].y
		area -= points[i + 1].x * points[i].y
	
	return abs(area) / 2.0

# Check if a point is contained within a polygon
static func is_pip_in_district(pip_position: Vector2, district_position: Vector2, polygon_points: PackedVector2Array) -> bool:
	var local_pip_pos = pip_position - district_position
	return Geometry2D.is_point_in_polygon(local_pip_pos, polygon_points)

# Get all pips contained in a district
static func get_contained_pips(all_pips: Array, district_position: Vector2, polygon_points: PackedVector2Array) -> Array:
	var contained = []
	for pip in all_pips:
		if pip is PipArea and is_pip_in_district(pip.position, district_position, polygon_points):
			contained.append(pip)
	return contained

# Calculate district summary for all districts
static func get_all_districts_summary(districts: Array) -> Dictionary:
	var green_count = 0
	var orange_count = 0
	var tied_count = 0
	var total_green_pips = 0
	var total_orange_pips = 0
	
	for district in districts:
		if district.has_method("get_winning_party") and district.has_method("get_pip_counts"):
			var winning_party = district.get_winning_party()
			var pip_counts = district.get_pip_counts()
			
			total_green_pips += pip_counts.get("green", 0)
			total_orange_pips += pip_counts.get("orange", 0)
			
			match winning_party:
				PipArea.Party.GREEN:
					green_count += 1
				PipArea.Party.ORANGE:
					orange_count += 1
				PipArea.Party.NONE:
					tied_count += 1
	
	return {
		"districts_green": green_count,
		"districts_orange": orange_count,
		"districts_tied": tied_count,
		"total_districts": districts.size(),
		"total_green_pips": total_green_pips,
		"total_orange_pips": total_orange_pips
	}