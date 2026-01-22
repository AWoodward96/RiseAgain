extends TargetingShapedDirectional
### Targeting Summon Grid Entity Directional
## This is a form of shaped free targeting that summons a grid entity.
class_name TargetingGEDirectional

@export_file("*.tscn") var gridEntityPrefab : String

var createdEntity : GridEntityBase

func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	var prefab = load(gridEntityPrefab)
	if prefab != null:
		createdEntity = prefab.instantiate()
		_ctrl.reticle.add_child(createdEntity)
		createdEntity.position = Vector2.ZERO
	super(_log, _ctrl)

func ShowAvailableTilesOnGrid():
	super()
	if createdEntity != null:
		createdEntity.rotation = deg_to_rad(90 * direction)
		createdEntity.position = GameSettingsTemplate.GetRotationalOffset(direction)


func EndTargeting():
	if createdEntity != null:
		createdEntity.queue_free()
