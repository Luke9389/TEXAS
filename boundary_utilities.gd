class_name BoundaryUtilities
extends RefCounted

# Generic geometric utility functions for boundary operations
# Eliminates duplication and provides reusable boundary checking

# Check if a global point is inside a polygon attached to a node
static func is_point_in_polygon_global(global_point: Vector2, node: Node2D, local_polygon: PackedVector2Array) -> bool:
	if not node or local_polygon.size() < 3:
		return false
	
	# Convert global point to node's local coordinates
	var local_point = node.to_local(global_point)
	return Geometry2D.is_point_in_polygon(local_point, local_polygon)

# Check if a global point is inside a CollisionPolygon2D attached to a node
static func is_point_in_collision_polygon(global_point: Vector2, node: Node2D, collision_polygon: CollisionPolygon2D) -> bool:
	if not collision_polygon:
		return false
	return is_point_in_polygon_global(global_point, node, collision_polygon.polygon)

# Convert a local polygon to global coordinates
static func convert_polygon_to_global(node: Node2D, local_polygon: PackedVector2Array) -> PackedVector2Array:
	if not node or local_polygon.is_empty():
		return PackedVector2Array()
	
	var global_points = PackedVector2Array()
	for point in local_polygon:
		global_points.append(node.to_global(point))
	return global_points

# Convert a global polygon to local coordinates relative to a node
static func convert_polygon_to_local(node: Node2D, global_polygon: PackedVector2Array) -> PackedVector2Array:
	if not node or global_polygon.is_empty():
		return PackedVector2Array()
	
	var local_points = PackedVector2Array()
	for point in global_polygon:
		local_points.append(node.to_local(point))
	return local_points

# Clip a global polygon against a boundary polygon (both in global coordinates)
static func clip_polygon_to_boundary(global_polygon: PackedVector2Array, boundary_node: Node2D, boundary_polygon: PackedVector2Array) -> Array[PackedVector2Array]:
	if global_polygon.size() < 3 or boundary_polygon.size() < 3 or not boundary_node:
		return [global_polygon]
	
	# Convert global polygon to boundary node's local coordinates
	var local_polygon = convert_polygon_to_local(boundary_node, global_polygon)
	
	# Clip using Geometry2D
	var clipped = Geometry2D.clip_polygons(local_polygon, boundary_polygon)
	
	# Convert results back to global coordinates
	var result: Array[PackedVector2Array] = []
	for poly in clipped:
		if poly.size() >= 3:  # Only keep valid polygons
			var global_poly = convert_polygon_to_global(boundary_node, poly)
			result.append(global_poly)
	
	return result

# Intersect a global polygon with a boundary polygon
static func intersect_polygon_with_boundary(global_polygon: PackedVector2Array, boundary_node: Node2D, boundary_polygon: PackedVector2Array) -> Array[PackedVector2Array]:
	if global_polygon.size() < 3 or boundary_polygon.size() < 3 or not boundary_node:
		return [global_polygon]
	
	# Convert global polygon to boundary node's local coordinates
	var local_polygon = convert_polygon_to_local(boundary_node, global_polygon)
	
	# Intersect using Geometry2D
	var intersected = Geometry2D.intersect_polygons(local_polygon, boundary_polygon)
	
	# Convert results back to global coordinates
	var result: Array[PackedVector2Array] = []
	for poly in intersected:
		if poly.size() >= 3:  # Only keep valid polygons
			var global_poly = convert_polygon_to_global(boundary_node, poly)
			result.append(global_poly)
	
	return result

# Check if all points of a polygon are inside a boundary
static func is_polygon_completely_inside_boundary(global_polygon: PackedVector2Array, boundary_node: Node2D, boundary_polygon: PackedVector2Array) -> bool:
	for point in global_polygon:
		if not is_point_in_polygon_global(point, boundary_node, boundary_polygon):
			return false
	return true

# Get polygon from CollisionPolygon2D in global coordinates
static func get_collision_polygon_global(node: Node2D, collision_polygon: CollisionPolygon2D) -> PackedVector2Array:
	if not collision_polygon:
		return PackedVector2Array()
	return convert_polygon_to_global(node, collision_polygon.polygon)

# Get polygon from CollisionPolygon2D in local coordinates (just returns the polygon)
static func get_collision_polygon_local(collision_polygon: CollisionPolygon2D) -> PackedVector2Array:
	if not collision_polygon:
		return PackedVector2Array()
	return collision_polygon.polygon

# Validate that a polygon has enough points to be valid
static func is_valid_polygon(polygon: PackedVector2Array) -> bool:
	return polygon.size() >= 3