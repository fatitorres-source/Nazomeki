@tool
class_name Player
extends CharacterBody2D
## A player's character for top-down movement, which can walk in 8 directions.

#region Constants used by special abilities
## How many pixels the player-character should teleport when the
## teleport special ability is used.
## [br][br]
## Used by [method _teleport].
const TELEPORT_DISTANCE = 512
#endregion

#region Exported parameters that the game designer can adjust in the Inspector tab for the Player
## Which player controls this character?
@export var player: Global.Player = Global.Player.ONE

## Use this to change the sprite frames of your character.
@export var sprite_frames: SpriteFrames = _initial_sprite_frames:
	set = _set_sprite_frames

## How fast does your character move?
@export_range(0, 1000, 10, "suffix:px/s") var speed: float = 500.0:
	set = _set_speed

## How fast does your character accelerate?
@export_range(0, 5000, 1000, "suffix:px/s²") var acceleration: float = 5000.0
#endregion

#region Internal variables
# Stores the player's original position when the game begins. Used by reset() to send the player
# back to the start of the level after losing a life.
var original_position: Vector2

# Whether the player-character is currently shrunk. See _shrink().
var _is_shrunk := false

# The last non-zero movement direction, used to know which way the character is "facing"
# when the player stops moving (useful for idle animations that depend on facing direction).
var _last_direction: Vector2 = Vector2.DOWN
#endregion

#region References to other nodes and resources in the Player scene
@onready var _sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _initial_sprite_frames: SpriteFrames = %AnimatedSprite2D.sprite_frames

@onready var _teleport_sfx: AudioStreamPlayer = %TeleportSFX
#endregion


#region Custom property-setting functions used by exported variables
func _set_sprite_frames(new_sprite_frames):
	sprite_frames = new_sprite_frames
	if sprite_frames and is_node_ready():
		_sprite.sprite_frames = sprite_frames


func _set_speed(new_speed):
	speed = new_speed
	if is_node_ready():
		_sprite.speed_scale = speed / 500


#endregion


# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
	else:
		Global.lives_changed.connect(_on_lives_changed)

	original_position = position
	_set_speed(speed)
	_set_sprite_frames(sprite_frames)


#region Signal handlers
# Handler for the Global.lives_changed signal, which is emitted when the player loses a life.
func _on_lives_changed():
	if Global.lives > 0:
		reset()


#endregion


#region Special abilities
## If the "teleport" action is pressed, and the player is moving the character,
## teleport the character in the direction it is currently moving.
func _teleport(input_direction: Vector2) -> void:
	if (
		Input.is_action_just_pressed(Actions.lookup(player, "teleport"))
		and not input_direction.is_zero_approx()
	):
		# TODO: Check if we are teleporting into a wall (in which case the player should lose a
		# life) or an enemy (in which case maybe the enemy should be telefragged/defeated?)
		global_position += TELEPORT_DISTANCE * input_direction.normalized()
		_teleport_sfx.play()


## If the "phase" action is pressed, make the player-character invulnerable, but also unable to
## interact with coins. Should be called from [code]_physics_process[/code] before calling
## [code]move_and_slide()[/code].
func _phase() -> void:
	# Check if the player is holding the "phase" action button.
	if Input.is_action_just_pressed(Actions.lookup(player, "phase")):
		# While phasing, disable collisions on the PLAYER physics layer.
		set_collision_layer_value(Global.PhysicsLayers.PLAYER, false)
		set_collision_mask_value(Global.PhysicsLayers.PLAYER, false)

		# Make the sprite semitransparent
		_sprite.modulate.a = 0.5

		# TODO: Is this ability too powerful? Should it have a timer/stamina so the player can only
		# use it occasionally and for a short time?
	elif Input.is_action_just_released(Actions.lookup(player, "phase")):
		# Re-enable collisions on the PLAYER physics layer.
		set_collision_layer_value(Global.PhysicsLayers.PLAYER, true)
		set_collision_mask_value(Global.PhysicsLayers.PLAYER, true)

		# Make the sprite opaque again
		_sprite.modulate.a = 1


## When the "shrink" action is pressed, toggle the player between normal size and half-size. While
## shrunk, the player can pass through narrower passages.
func _shrink() -> void:
	if Input.is_action_just_pressed(Actions.lookup(player, "shrink")):
		_is_shrunk = not _is_shrunk

		if _is_shrunk:
			# Shrink the player-character's sprite and collision shape
			scale = Vector2(0.5, 0.5)
		else:
			scale = Vector2(1, 1)

	# TODO: should there be other consequences to being small? Could we make the player somehow more
	# vulnerable to enemies?


#endregion


# Called by Godot for every physics frame. Moves the player-character in response to player inputs
# and the physics of the level.
func _physics_process(delta):
	# Don't move if there are no lives left.
	if Global.lives <= 0:
		return

	# Remove the '#' below to enable the phase special ability
	#_phase()

	# Remove the '#' below to enable the shrink special ability
	#_shrink()

	# Get the input direction (both axes) and handle the movement/deceleration.
	var direction = Input.get_vector(
		Actions.lookup(player, "left"),
		Actions.lookup(player, "right"),
		Actions.lookup(player, "up"),
		Actions.lookup(player, "down"),
	)

	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
		_last_direction = direction
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)

	if velocity.is_zero_approx():
		_sprite.play("idle")
	else:
		_sprite.play("walk")
		# Flip the sprite horizontally when moving left, mirroring the original platformer logic.
		# If your sprite sheet has separate up/down frames, replace this block with logic that
		# plays "walk_up" / "walk_down" / "walk_side" depending on abs(direction.y) vs abs(direction.x).
		if not is_zero_approx(direction.x):
			_sprite.flip_h = direction.x < 0

	move_and_slide()

	# Remove the '#' below to enable the teleport special ability
	#_teleport(direction)


## Restore the player to their initial position in the level. Called by _on_lives_changed.
func reset():
	position = original_position
	velocity = Vector2.ZERO
