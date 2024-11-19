extends ActionStep
class_name PushStep


func Enter(_actionLog : ActionLog):
	super(_actionLog)

	if ability.PushComponentData == null:
		push_error("Ability " + ability.name + ", has a push step but doesn't have a push component.")
		return

	#var actionDirection = _actionLog.actionDirection

	# WIP
	#for pushData in ability.PushComponentData.pushData:
		#var direction = actionDirection
		#if pushData.overrideActionDirection:
			#direction = pushData.pushDirectionOverride
