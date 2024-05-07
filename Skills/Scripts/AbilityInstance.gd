extends Node2D
class_name AbilityInstance

@export var loc_displayName : String
@export var loc_displayDesc : String
@export var AbilityStack : Array[AbilityActionBase]
@export var AutoEndTurn = true

var persisted_dictionary = {}
var context : AbilityContext
var unit : UnitInstance

var active = false
var stackIndex = 0

func _ready():
	pass

func _process(_delta):
	if active:
		var currentStack = AbilityStack[stackIndex]

		# Run Execute every frame until it returns true
		if currentStack._Execute(context):
			# once it returns true, increase the stack, to go onto the next step of the ability
			stackIndex += 1

			# if we've reached the end of the stack
			if stackIndex >= AbilityStack.size():
				# Disable this ability and if AutoEndTurn is true, end this units turn
				active = false

				# discard the context
				context = null
				if AutoEndTurn:
					unit.EndTurn()
			else:
				# otherwise, call the Enter of the next ability on the stack
				AbilityStack[stackIndex]._Enter(context)

func ExecuteAbility(_unit : UnitInstance, _map : Map, _optionalContext : AbilityContext = null):
	# construct the ability context and start the stack
	if AbilityStack.size() == 0:
		return false

	unit = _unit
	context = _optionalContext
	if context == null:
		context = AbilityContext.new()
		context.Construct(_map, _unit, self)

	active = true
	stackIndex = 0

	# do the logic in the _process method, we have to call Enter for the first action here
	AbilityStack[stackIndex]._Enter(context)

	return true

func CancelAbility():
	active = false
