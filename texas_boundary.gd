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
	
	return BoundaryUtilities.is_point_in_collision_polygon(global_point, self, outer_boundary_polygon)

# Check if a point is inside the inner Texas boundary (spawn area)
func is_point_inside_inner_boundary(global_point: Vector2) -> bool:
	if not inner_boundary_polygon:
		return true  # If no boundary, allow everything
	
	return BoundaryUtilities.is_point_in_collision_polygon(global_point, self, inner_boundary_polygon)

# Backward compatibility - uses outer boundary
func is_point_inside(global_point: Vector2) -> bool:
	return is_point_inside_outer_boundary(global_point)

# Get the outer boundary polygon in global coordinates
func get_global_outer_boundary_polygon() -> PackedVector2Array:
	return BoundaryUtilities.get_collision_polygon_global(self, outer_boundary_polygon)

# Get the inner boundary polygon in global coordinates
func get_global_inner_boundary_polygon() -> PackedVector2Array:
	return BoundaryUtilities.get_collision_polygon_global(self, inner_boundary_polygon)


# Get the outer boundary polygon in local coordinates
func get_local_outer_boundary_polygon() -> PackedVector2Array:
	return BoundaryUtilities.get_collision_polygon_local(outer_boundary_polygon)

# Get the inner boundary polygon in local coordinates
func get_local_inner_boundary_polygon() -> PackedVector2Array:
	return BoundaryUtilities.get_collision_polygon_local(inner_boundary_polygon)


# Clip a polygon to the outer Texas boundary
func clip_polygon_to_boundary(polygon_global: PackedVector2Array) -> Array[PackedVector2Array]:
	if not outer_boundary_polygon:
		return [polygon_global]
	
	return BoundaryUtilities.clip_polygon_to_boundary(polygon_global, self, outer_boundary_polygon.polygon)

# Check if a polygon is completely inside the boundary
func is_polygon_inside(polygon_global: PackedVector2Array) -> bool:
	if not outer_boundary_polygon:
		return true
	
	return BoundaryUtilities.is_polygon_completely_inside_boundary(polygon_global, self, outer_boundary_polygon.polygon)

# Get the intersection of a polygon with the outer boundary
func intersect_polygon_with_boundary(polygon_global: PackedVector2Array) -> Array[PackedVector2Array]:
	if not outer_boundary_polygon:
		return [polygon_global]
	
	return BoundaryUtilities.intersect_polygon_with_boundary(polygon_global, self, outer_boundary_polygon.polygon)