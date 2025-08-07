class_name PipArea
extends Area2D

enum Party { NONE, GREEN, ORANGE }

@export var party: Party = Party.GREEN:
	set(value):
		party = value
		update_visual()

@export var green_texture: Texture2D = preload("res://assets/green_pip.png")
@export var orange_texture: Texture2D = preload("res://assets/orange_pip.png")
@export var pip_scale: float = 0.5

var sprite: Sprite2D

func _ready():
	sprite = Sprite2D.new()
	sprite.scale = Vector2(pip_scale, pip_scale)
	add_child(sprite)
	update_visual()
	
	var collision_shape = $CollisionShape2D
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = 25

func update_visual():
	if not sprite:
		return
	
	match party:
		Party.GREEN:
			sprite.texture = green_texture
			sprite.modulate = Color(0.2, 0.8, 0.2)
		Party.ORANGE:
			sprite.texture = orange_texture
			sprite.modulate = Color(1.0, 0.5, 0.0)
		Party.NONE:
			sprite.modulate = Color.GRAY

func get_party_color() -> Color:
	match party:
		Party.GREEN:
			return Color(0.2, 0.8, 0.2)
		Party.ORANGE:
			return Color(1.0, 0.5, 0.0)
		_:
			return Color.GRAY

func set_random_party():
	party = Party.GREEN if randf() < 0.5 else Party.ORANGE