class_name PipArea
extends Node2D

enum VoteStatus { NOT_VOTED, VOTED, DID_NOT_VOTE }

@export var party: GameTypes.Party = GameTypes.Party.GREEN:
	set(value):
		party = value
		update_visual()

var vote_status: VoteStatus = VoteStatus.NOT_VOTED

@export var green_texture: Texture2D = preload("res://assets/textures/pips/green_pip.png")
@export var orange_texture: Texture2D = preload("res://assets/textures/pips/orange_pip.png")
# Constants
const DEFAULT_PIP_SCALE = 0.5
const COLLISION_RADIUS = 25.0
const VOTED_BRIGHTNESS = 1.2
const DID_NOT_VOTE_BRIGHTNESS = 0.4
const VOTE_ANIMATION_DURATION = 0.3
const VOTE_BOUNCE_SCALE = 1.2

@export var pip_scale: float = DEFAULT_PIP_SCALE

var pip_sprite: Sprite2D
var vote_sprite: Sprite2D
var area_2d: Area2D
var animation_tween: Tween

func _ready():
	# Get references to child nodes
	area_2d = $Area2D
	pip_sprite = $PipSprite
	vote_sprite = $VoteSprite
	
	# Setup pip sprite scale
	if pip_sprite:
		pip_sprite.scale = Vector2(pip_scale, pip_scale)
	
	# Setup collision
	var collision_shape = $Area2D/CollisionShape2D
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = COLLISION_RADIUS
	
	# Initialize vote sprite as hidden
	if vote_sprite:
		vote_sprite.visible = false
		vote_sprite.scale = Vector2.ZERO
	
	# Connect to SignalBus for voting animations
	SignalBus.pip_voted.connect(_on_pip_voted)
	
	update_visual()

func update_visual():
	if not pip_sprite:
		return
	
	# Set base color and texture based on party
	var base_color: Color
	match party:
		GameTypes.Party.GREEN:
			pip_sprite.texture = green_texture
			base_color = PartyColors.GREEN
		GameTypes.Party.ORANGE:
			pip_sprite.texture = orange_texture
			base_color = PartyColors.ORANGE
		GameTypes.Party.NONE:
			base_color = PartyColors.GRAY
	
	# Modify brightness based on voting status
	match vote_status:
		VoteStatus.VOTED:
			pip_sprite.modulate = base_color * VOTED_BRIGHTNESS
		VoteStatus.DID_NOT_VOTE:
			pip_sprite.modulate = base_color * DID_NOT_VOTE_BRIGHTNESS
		VoteStatus.NOT_VOTED:
			pip_sprite.modulate = base_color

func get_party_color() -> Color:
	return PartyColors.get_party_color(party)

func set_random_party():
	party = GameTypes.Party.GREEN if randf() < 0.5 else GameTypes.Party.ORANGE

func set_vote_status(status: VoteStatus):
	vote_status = status
	update_visual()
	_animate_vote_status(status)

func reset_voting():
	vote_status = VoteStatus.NOT_VOTED
	update_visual()
	_animate_vote_status(VoteStatus.NOT_VOTED)

# Animate the vote checkbox based on status
func _animate_vote_status(status: VoteStatus):
	if not vote_sprite:
		return
	
	# Stop any existing animation
	if animation_tween:
		animation_tween.kill()
	
	match status:
		VoteStatus.VOTED:
			# Show and animate in the checkbox with a bounce
			if vote_sprite:
				var original_scale = Vector2(0.294118, 0.294118)  # From the scene file
				
				# Use animation utilities for bounce effect
				animation_tween = AnimationUtilities.show_by_scale_bounce(vote_sprite, original_scale, VOTE_ANIMATION_DURATION, VOTE_BOUNCE_SCALE)
			
		VoteStatus.DID_NOT_VOTE:
			# Hide the checkbox using animation utilities
			if vote_sprite.visible:
				animation_tween = AnimationUtilities.hide_by_scale(vote_sprite, VOTE_ANIMATION_DURATION * 0.5, _hide_vote_sprite)
			else:
				# If already hidden, just ensure animation_tween is null
				animation_tween = null
			
		VoteStatus.NOT_VOTED:
			# Hide immediately without animation
			vote_sprite.visible = false
			vote_sprite.scale = Vector2.ZERO
			vote_sprite.modulate = Color.WHITE
			animation_tween = null

func _hide_vote_sprite():
	if vote_sprite:
		vote_sprite.visible = false

# Handle pip voting signal from VotingManager
func _on_pip_voted(pip_data: PipData) -> void:
	# Check if this signal is for me
	var my_id = "pip_" + str(get_instance_id())
	if pip_data.id == my_id:
		# Update my vote status and play animation
		set_vote_status(pip_data.vote_status)

# Convert this pip node to PipData for SignalBus communication
func to_pip_data() -> PipData:
	var pip_data = PipData.new()
	pip_data.id = "pip_" + str(get_instance_id())
	pip_data.party = party
	pip_data.position = position
	pip_data.vote_status = vote_status
	return pip_data