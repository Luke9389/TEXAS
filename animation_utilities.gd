class_name AnimationUtilities
extends RefCounted

# Reusable animation patterns for the TEXAS game

# Flash a node between two colors and return to original
static func flash_color(node: Node, target_color: Color, duration: float, restore_color: Color = Color.WHITE) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween = node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate", target_color, duration)
	tween.tween_property(node, "modulate", restore_color, duration).set_delay(duration)
	return tween

# Flash multiple nodes simultaneously with the same timing
static func flash_multiple_nodes(nodes: Array[Node], target_color: Color, duration: float, restore_color: Color = Color.WHITE) -> Tween:
	if nodes.is_empty():
		return null
	
	var tween = nodes[0].create_tween()
	tween.set_parallel(true)
	
	for node in nodes:
		tween.tween_property(node, "modulate", target_color, duration)
		tween.tween_property(node, "modulate", restore_color, duration).set_delay(duration)
	
	return tween

# Bounce scale animation - scale up then back down
static func bounce_scale(node: Node, target_scale: Vector2, duration: float, restore_scale: Vector2 = Vector2.ONE) -> Tween:
	var tween = node.create_tween()
	var bounce_duration = duration * 0.6
	var restore_duration = duration * 0.4
	
	tween.tween_property(node, "scale", target_scale, bounce_duration)
	tween.tween_property(node, "scale", restore_scale, restore_duration).set_delay(bounce_duration)
	return tween

# Fade out animation with optional callback
static func fade_out(node: Node, duration: float, callback: Callable = Callable()) -> Tween:
	var tween = node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate", Color.TRANSPARENT, duration)
	
	if callback.is_valid():
		tween.tween_callback(callback).set_delay(duration)
	
	return tween

# Fade in animation
static func fade_in(node: Node, duration: float, target_color: Color = Color.WHITE) -> Tween:
	node.modulate = Color.TRANSPARENT
	var tween = node.create_tween()
	tween.tween_property(node, "modulate", target_color, duration)
	return tween

# Looping flash animation between two colors
static func looping_flash(node: Node, color_a: Color, color_b: Color, duration: float) -> Tween:
	var tween = node.create_tween()
	tween.set_parallel(true)
	tween.set_loops()
	
	tween.tween_property(node, "modulate", color_a, duration)
	tween.tween_property(node, "modulate", color_b, duration).set_delay(duration)
	
	return tween

# Complex flash-then-fade sequence (for deletion animations)
static func flash_then_fade(node: Node, target_color: Color, flash_duration: float, fade_duration: float) -> Tween:
	var tween = node.create_tween()
	
	# Flash to the specified color
	tween.tween_property(node, "modulate", target_color, flash_duration)
	# Then fade to transparent
	tween.tween_property(node, "modulate", Color.TRANSPARENT, fade_duration).set_delay(flash_duration)
	
	return tween

# Animate multiple properties of a node with specific colors
static func flash_node_properties(node: Node, property_configs: Array[Dictionary], flash_duration: float, fade_duration: float = 0.0) -> Tween:
	if property_configs.is_empty():
		return null
	
	var tween = node.create_tween()
	tween.set_parallel(true)
	var has_tweeners = false
	
	for config in property_configs:
		var property_name = config.get("property", "")
		var flash_value = config.get("flash_value", Color.WHITE)
		var fade_value = config.get("fade_value", null)
		
		if property_name.is_empty():
			continue
		
		# Flash to the specified value
		tween.tween_property(node, property_name, flash_value, flash_duration)
		has_tweeners = true
		
		# If fade value is provided, fade to it after the flash
		if fade_value != null and fade_duration > 0:
			tween.tween_property(node, property_name, fade_value, fade_duration).set_delay(flash_duration)
	
	# If no valid properties were animated, kill the tween and return null
	if not has_tweeners:
		tween.kill()
		return null
	
	return tween

# Scale animation that hides by scaling to zero
static func hide_by_scale(node: Node, duration: float, callback: Callable = Callable()) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween = node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "scale", Vector2.ZERO, duration)
	tween.tween_property(node, "modulate", Color.TRANSPARENT, duration)
	
	if callback.is_valid():
		tween.tween_callback(callback).set_delay(duration)
	
	return tween

# Show by scaling from zero with bounce
static func show_by_scale_bounce(node: Node, target_scale: Vector2, duration: float, bounce_factor: float = 1.2) -> Tween:
	if not is_instance_valid(node):
		return null
	node.scale = Vector2.ZERO
	node.modulate = Color.WHITE
	node.visible = true
	
	var bounce_target_scale = target_scale * bounce_factor
	var bounce_duration = duration * 0.6
	var settle_duration = duration * 0.4
	
	var tween = node.create_tween()
	tween.tween_property(node, "scale", bounce_target_scale, bounce_duration)
	tween.tween_property(node, "scale", target_scale, settle_duration).set_delay(bounce_duration)
	
	return tween