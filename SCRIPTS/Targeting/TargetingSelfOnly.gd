extends TargetingDataBase
### Targeting Self Only:
## A very simple targeting type. You can only target yourself. That's it. Nothing else.
class_name TargetingSelfOnly


func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	super(_log, _ctrl)
	log.availableTiles = [source.CurrentTile]
	log.actionOriginTile = source.CurrentTile
	log.affectedTiles.append(log.actionOriginTile.AsTargetData())
	ctrl.ForceReticlePosition(log.source.CurrentTile.Position)
	ctrl.combatHUD.UpdateTargetingInstructions(true, GetTargetingString(), {})
	ShowPreview()

func GetTargetingString():
	return "ui_targeting_confirmselection"
