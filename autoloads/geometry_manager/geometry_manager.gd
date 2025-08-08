class_name GeometryManager
extends RefCounted

# Pure geometric operations utility - no dependencies, only static functions
# Extracted from DistrictManager to provide reusable, testable geometry operations

# Clip a district's polygon to boundaries and existing districts
static func clip_district_to_boundaries(
	district_data: DistrictData,
	boundary_polygon: PackedVector2Array,
	existing_districts: Array[DistrictData]
) -> DistrictData:
	
	if not district_data.is_valid() or district_data.polygon_points.size() < 3:
		push_warning("[GeometryManager] Invalid district data provided for clipping")
		return district_data
	
	# Convert district polygon to global coordinates
	var district_polygon_global = PackedVector2Array()
	for point in district_data.polygon_points:
		district_polygon_global.append(district_data.position + point)
	
	var result_polygon = district_polygon_global
	
	# First clip to boundary if it exists
	if boundary_polygon.size() >= 3:
		var clipped_polygons = intersect_polygon_with_boundary(result_polygon, boundary_polygon)
		if clipped_polygons.size() > 0:
			result_polygon = clipped_polygons[0]
	
	# Then subtract all existing districts
	for existing_district in existing_districts:
		if existing_district.id == district_data.id:
			continue  # Skip self
		
		if existing_district.polygon_points.size() < 3:
			continue
		
		# Convert existing district to global coordinates
		var existing_polygon_global = PackedVector2Array()
		for point in existing_district.polygon_points:
			existing_polygon_global.append(existing_district.position + point)
		
		# Subtract the existing district from our new district
		var clipped = Geometry2D.clip_polygons(result_polygon, existing_polygon_global)
		
		# Find the largest remaining polygon (in case it got split)
		if clipped.size() > 0:
			var largest_area = 0.0
			var largest_polygon = clipped[0]
			for poly in clipped:
				var area = calculate_polygon_area(poly)
				if area > largest_area:
					largest_area = area
					largest_polygon = poly
			result_polygon = largest_polygon
	
	# Convert back to local coordinates and update district
	var clipped_local = PackedVector2Array()
	for point in result_polygon:
		clipped_local.append(point - district_data.position)
	
	# Create a new DistrictData with the clipped polygon
	var clipped_district = district_data.clone()
	if clipped_local.size() >= 3:  # Only update if we still have a valid polygon
		clipped_district.polygon_points = clipped_local
	
	return clipped_district

# Intersect a polygon with a boundary polygon
static func intersect_polygon_with_boundary(
	polygon: PackedVector2Array,
	boundary_polygon: PackedVector2Array
) -> Array[PackedVector2Array]:
	
	if polygon.size() < 3 or boundary_polygon.size() < 3:
		return [polygon]
	
	var intersections = Geometry2D.intersect_polygons(polygon, boundary_polygon)
	
	# If no intersection, return empty
	if intersections.is_empty():
		return []
	
	return intersections

# Subtract one polygon from another
static func subtract_polygon(
	base_polygon: PackedVector2Array,
	subtraction_polygon: PackedVector2Array
) -> Array[PackedVector2Array]:
	
	if base_polygon.size() < 3 or subtraction_polygon.size() < 3:
		return [base_polygon]
	
	return Geometry2D.clip_polygons(base_polygon, subtraction_polygon)

# Calculate polygon area using shoelace formula
static func calculate_polygon_area(points: PackedVector2Array) -> float:
	if points.size() < 3:
		return 0.0
	
	var area = 0.0
	for i in range(points.size() - 1):
		area += points[i].x * points[i + 1].y
		area -= points[i + 1].x * points[i].y
	
	return abs(area) / 2.0

# Check if a point is inside a polygon
static func is_point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	if polygon.size() < 3:
		return false
	
	return Geometry2D.is_point_in_polygon(point, polygon)

# Check if a polygon is completely inside a boundary
static func is_polygon_inside_boundary(
	polygon: PackedVector2Array,
	boundary_polygon: PackedVector2Array
) -> bool:
	
	if polygon.size() < 3 or boundary_polygon.size() < 3:
		return false
	
	# Check if all points of the polygon are inside the boundary
	for point in polygon:
		if not is_point_in_polygon(point, boundary_polygon):
			return false
	
	return true

# Get the bounding rectangle of a polygon
static func get_polygon_bounding_rect(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty():
		return Rect2()
	
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for point in polygon:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

# Simplify a polygon by removing points that are too close together
static func simplify_polygon(polygon: PackedVector2Array, min_distance: float = 10.0) -> PackedVector2Array:
	if polygon.size() < 3:
		return polygon
	
	var simplified = PackedVector2Array()
	simplified.append(polygon[0])
	
	for i in range(1, polygon.size()):
		var last_point = simplified[simplified.size() - 1]
		var current_point = polygon[i]
		
		if last_point.distance_to(current_point) >= min_distance:
			simplified.append(current_point)
	
	# Ensure we have at least 3 points for a valid polygon
	if simplified.size() < 3:
		return polygon
	
	return simplified

# Convert global coordinates to local relative to a position
static func global_to_local_polygon(global_polygon: PackedVector2Array, local_origin: Vector2) -> PackedVector2Array:
	var local_polygon = PackedVector2Array()
	for point in global_polygon:
		local_polygon.append(point - local_origin)
	return local_polygon

# Convert local coordinates to global relative to a position
static func local_to_global_polygon(local_polygon: PackedVector2Array, local_origin: Vector2) -> PackedVector2Array:
	var global_polygon = PackedVector2Array()
	for point in local_polygon:
		global_polygon.append(point + local_origin)
	return global_polygon

# Validate that a polygon has the minimum requirements
static func is_valid_polygon(polygon: PackedVector2Array, min_points: int = 3, min_area: float = 100.0) -> bool:
	if polygon.size() < min_points:
		return false
	
	var area = calculate_polygon_area(polygon)
	return area >= min_area