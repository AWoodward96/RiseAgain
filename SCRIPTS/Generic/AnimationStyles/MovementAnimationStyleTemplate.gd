extends AnimationStyleTemplate
class_name MovementAnimationStyleTemplate

@export var UseFootsteps : bool = true
@export var PreperationAnimString : String
@export var IsDirectional : bool = false
@export var SpeedOverride : float = -1

@export_category("VFX")
@export var Prep_VFX: PackedScene	# Prep is played at the start of movement
@export var Enter_VFX : PackedScene # For movement, Enter is played every time a new tile is reached in the path
@export var Exit_VFX : PackedScene  # Exit is played when movement is complete

var animationSuffix : String = ""
var speed : float

func Prepare(_direction : Vector2, _source : UnitInstance, _data):
	super(_direction, _source, _data)

	speed = GameManager.GameSettings.CharacterTileMovemementSpeed
	if SpeedOverride != -1:
		speed = SpeedOverride


	if UseFootsteps:
		source.footstepsSound.play()

	UpdateAnimationDirectionSuffix()

	if PreperationAnimString != "":
		source.PlayAnimation(PreperationAnimString + animationSuffix)

	PlayVFX(Prep_VFX)
	pass

func Enter():
	super()
	PlayVFX(Enter_VFX)
	pass

func UpdateAnimationDirectionSuffix():
	animationSuffix = ""
	if IsDirectional:
		var directionAsEnum = GameSettingsTemplate.GetDirectionFromVector(direction)
		match directionAsEnum:
			GameSettingsTemplate.Direction.Up:
				animationSuffix = "_up"
			GameSettingsTemplate.Direction.Down:
				animationSuffix = "_down"
			GameSettingsTemplate.Direction.Left:
				animationSuffix = "_left"
			GameSettingsTemplate.Direction.Right:
				animationSuffix = "_right"

func Execute(_delta, _destination : Vector2):
	direction = _destination - source.position
	var movementVelocity = direction.normalized() * speed
	source.position += movementVelocity * _delta
	source.PlayAnimation(UnitSettingsTemplate.GetMovementAnimationFromVector(movementVelocity))
	return true


func PlayVFX(_packedVFX: PackedScene):
	if source != null && _packedVFX != null:
		var vfx = _packedVFX.instantiate()
		vfx.position = source.position

	pass

func Exit():
	if source != null:
		source.footstepsSound.stop()

### A check to see if we can finish the movement animation. Not important for the default animation,
### but for teleporting and other more complex moves, it's pretty important
func AnimationComplete():
	return true
