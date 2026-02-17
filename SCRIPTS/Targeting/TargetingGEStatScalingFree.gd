extends TargetingMultiShapedFree
### Targeting GE StatScaling Simple
## Same as parent, but with support for creating grid entities in the targeting
class_name TargetingGEStatScalingFree

@export_file("*.tscn") var gridEntityPrefab : String

@export var StatScalingDefs : Array[StatDef]
@export var NumberOfTargets : Array[int]

var hoveringEntity : GridEntityBase
var createdEntities : Array[GridEntityBase]


func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	var prefab = load(gridEntityPrefab)
	if prefab != null:
		hoveringEntity = prefab.instantiate()
		_ctrl.reticle.add_child(hoveringEntity)
		hoveringEntity.position = Vector2.ZERO
	super(_log, _ctrl)

func RefreshPreview():
	super()

	hoveringEntity.visible = selectedTiles.size() < GetMaximumNumberOfTargets()

	for c in createdEntities:
		if c != null:
			c.queue_free()

	for tile in selectedTiles:
		var prefab = load(gridEntityPrefab)
		if prefab != null:
			var newEntity = prefab.instantiate()
			newEntity.name = newEntity.name + "_PREVIEW"
			currentMap.add_child(newEntity)
			newEntity.position = tile.GlobalPosition
			createdEntities.append(newEntity)


func EndTargeting():
	super()
	if hoveringEntity != null:
		hoveringEntity.queue_free()

	for c in createdEntities:
		if c != null:
			c.queue_free()
	createdEntities.clear()


func GetMaximumNumberOfTargets():
	if log == null || log.source == null:
		return 0

	var index = 0
	for i in range(0, StatScalingDefs.size() - 1):
		var statFloor = StatScalingDefs[i]
		var reqStat = log.source.GetWorkingStat(statFloor.Template)
		if reqStat >= statFloor.Value:
			index = i
		else:
			break

	return NumberOfTargets[index]
