extends Resource
class_name AnimationStyleTemplate

### Why is this a resource instead of a node on an ability?
### Because I want to use it for all kinds of animations, including movement animations (jumping, teleporting, etc).
### If this was a node2d, I wouldn't be able to do that. I'd have to put it in the visual and that's extra clutter. Additionally, i'd want the movement action itself to have this reference to do what it wants to do

static var TIMEOUT : float = 10

# called when the style should deal the damage
signal PerformDamageCallback

@export var HasStandardWindup : bool = true
var direction : Vector2
var initialDirection : Vector2
var source : UnitInstance
var movementData : MovementData
var actionLog : ActionLog


## Called once in order to play a prepare animation. Should be called once and never brick a sequence by awaiting. Also serves as an initiate phase of this
func Prepare(_direction : Vector2, _source : UnitInstance, _data):
	direction = _direction
	initialDirection = _direction
	source = _source
	if _data is ActionLog:
		actionLog = _data
	elif _data is MovementData:
		movementData = _data
	pass

## Called to begin the attack sequence. Should only be called once, similar to Prepare.
func Enter():
	PerformDamageCallback.emit()
	pass

## Called to execute any effects that happen over time.
## Direction here can change over time for movement based abilities or animations
func Execute(_delta, _direction : Vector2):
	return true

func Exit():
	pass
