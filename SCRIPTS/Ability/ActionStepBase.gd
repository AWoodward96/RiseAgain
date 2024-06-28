extends Resource
class_name ActionStep

var source
var log : ActionLog
var ability : Ability

func Enter(_actionLog : ActionLog):
	log = _actionLog

	if _actionLog == null:
		push_error("Entering an Ability Step with a null ActionLog. What are you doing?")
		return

	source = log.source
	ability = log.ability
	if ability == null:
		push_error("Entering an Ability Step with a null Ability. Did you set the ability in the action log?")
	pass

func Execute():
	return true
