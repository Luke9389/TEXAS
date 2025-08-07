class_name TexasBoundary
extends Node2D

# Reference to the collision polygons that define the Texas boundaries
var outer_boundary_polygon: CollisionPolygon2D
var inner_boundary_polygon: CollisionPolygon2D
var outer_boundary_area: Area2D
var inner_boundary_area: Area2D

func _ready():
	# Find the boundary polygons in our scene structure
	outer_boundary_area = $OuterBorder
	outer_boundary_polygon = $OuterBorder/CollisionPolygon2D
	inner_boundary_area = $InnerBorder
	inner_boundary_polygon = $InnerBorder/CollisionPolygon2D
	
	if not outer_boundary_polygon:
		push_error("TexasBoundary: OuterBorder CollisionPolygon2D not found!")
		return
	
	if not inner_boundary_polygon:
		push_error("TexasBoundary: InnerBorder CollisionPolygon2D not found!")
		return
	
	if outer_boundary_polygon.polygon.size() < 3:
		push_error("TexasBoundary: Outer boundary polygon needs at least 3 points!")
	
	if inner_boundary_polygon.polygon.size() < 3:
		push_error("TexasBoundary: Inner boundary polygon needs at least 3 points!")

# Check if a point is inside the outer Texas boundary
func is_point_inside_outer_boundary(global_point: Vector2) -> bool:
	if not outer_boundary_polygon:
		return true  # If no boundary, allow everything
	
	# Convert global point to local coordinates
	var local_point = to_local(global_point)
	return Geometry2D.is_point_in_polygon(local_point, outer_boundary_polygon.polygon)

# Check if a point is inside the inner Texas boundary (spawn area)
func is_point_inside_inner_boundary(global_point: Vector2) -> bool:
	if not inner_boundary_polygon:
		return true  # If no boundary, allow everything
	
	# Convert global point to local coordinates
	var local_point = to_local(global_point)
	return Geometry2D.is_point_in_polygon(local_point, inner_boundary_polygon.polygon)

# Backward compatibility - uses outer boundary
func is_point_inside(global_point: Vector2) -> bool:
	return is_point_inside_outer_boundary(global_point)

# Get the outer boundary polygon in global coordinates
func get_global_outer_boundary_polygon() -> PackedVector2Array:
	if not outer_boundary_polygon:
		return PackedVector2Array()
	
	var global_points = PackedVector2Array()
	for point in outer_boundary_polygon.polygon:
		global_points.append(to_global(point))
	return global_points

# Get the inner boundary polygon in global coordinates
func get_global_inner_boundary_polygon() -> PackedVector2Array:
	if not inner_boundary_polygon:
		return PackedVector2Array()
	
	var global_points = PackedVector2Array()
	for point in inner_boundary_polygon.polygon:
		global_points.append(to_global(point))
	return global_points


# Get the outer boundary polygon in local coordinates
func get_local_outer_boundary_polygon() -> PackedVector2Array:
	if not outer_boundary_polygon:
		return PackedVector2Array()
	return outer_boundary_polygon.polygon

# Get the inner boundary polygon in local coordinates
func get_local_inner_boundary_polygon() -> PackedVector2Array:
	if not inner_boundary_polygon:
		return PackedVector2Array()
	return inner_boundary_polygon.polygon


# Clip a polygon to the outer Texas boundary
func clip_polygon_to_boundary(polygon_global: PackedVector2Array) -> Array[PackedVector2Array]:
	if not outer_boundary_polygon or polygon_global.size() < 3:
		return [polygon_global]
	
	# Convert global polygon to local coordinates
	var polygon_local = PackedVector2Array()
	for point in polygon_global:
		polygon_local.append(to_local(point))
	
	# Clip using Geometry2D
	var clipped = Geometry2D.clip_polygons(polygon_local, outer_boundary_polygon.polygon)
	
	# Convert result back to global coordinates
	var result: Array[PackedVector2Array] = []
	for poly in clipped:
		if poly.size() >= 3:  # Only keep valid polygons
			var global_poly = PackedVector2Array()
			for point in poly:
				global_poly.append(to_global(point))
			result.append(global_poly)
	
	return result

# Check if a polygon is completely inside the boundary
func is_polygon_inside(polygon_global: PackedVector2Array) -> bool:
	for point in polygon_global:
		if not is_point_inside(point):
			return false
	return true

# Get the intersection of a polygon with the outer boundary
func intersect_polygon_with_boundary(polygon_global: PackedVector2Array) -> Array[PackedVector2Array]:
	if not outer_boundary_polygon or polygon_global.size() < 3:
		return [polygon_global]
	
	# Convert global polygon to local coordinates
	var polygon_local = PackedVector2Array()
	for point in polygon_global:
		polygon_local.append(to_local(point))
	
	# Intersect using Geometry2D
	var intersected = Geometry2D.intersect_polygons(polygon_local, outer_boundary_polygon.polygon)
	
	# Convert result back to global coordinates
	var result: Array[PackedVector2Array] = []
	for poly in intersected:
		if poly.size() >= 3:  # Only keep valid polygons
			var global_poly = PackedVector2Array()
			for point in poly:
				global_poly.append(to_global(point))
			result.append(global_poly)
	
	return result