extends GEProp
class_name GESlowSpeedAttack

const TELEGRAPH_ATLAS : int = 2
const TELEGRAPH_TILE : Vector2i = Vector2i(0,2)

@export var executionStack : Array[ActionStep]
@export var autoExpire : bool = true
@export var telegraphTilemap : TileMapLayer
@export var autoUpdateTelegraph : bool = true
var log : ActionLog

func Spawn(_map : Map, _origin : Tile, _source : UnitInstance, _ability : Ability, _allegience : GameSettingsTemplate.TeamID, _direction : GameSettingsTemplate.Direction):
	super(_map, _origin, _source, _ability, _allegience, _direction)
	UpdateTelegraph()

func Enter():
	super()
	log = ActionLog.Construct(CurrentMap.grid, Source, SourceAbility)
	log.actionOriginTile = Origin
	log.affectedTiles = tiles
	BuildResults()
	log.actionStackIndex = -1

func UpdateTelegraph():
	if telegraphTilemap != null:
		telegraphTilemap.clear()
		var originPosition = Origin.Position
		for tileTargetData in tiles:
			telegraphTilemap.set_cell(tileTargetData.Tile.Position - originPosition, TELEGRAPH_ATLAS, TELEGRAPH_TILE)

	pass


func UpdateGridEntity_TeamTurn(_delta : float):
	if Source == null:
		Expired = true
		return true

	if CurrentMap.currentTurn != Source.UnitAllegiance:
		return true

	if log.actionStackIndex < 0:
		log.actionStackIndex = 0
		executionStack[log.actionStackIndex].Enter(log)


	if log.actionStackIndex < executionStack.size():
		if executionStack[log.actionStackIndex].Execute(_delta):
			log.actionStackIndex += 1
			if log.actionStackIndex < executionStack.size():
				executionStack[log.actionStackIndex].Enter(log)
			else:
				ExecutionComplete = true
				if autoExpire:
					Expired = true
				return true

	return false

func BuildResults():
	log.actionStepResults.clear()
	for tile in log.affectedTiles:
		var index = 0
		for step in executionStack:
			var result = step.GetResult(log, tile)
			if result != null:
				if result is ActionStepResult:
					result.StepIndex = index
					log.actionStepResults.append(result)
				else:
					push_error("Ability Step: " + str(step.get_script()) + " - attached to ability " + SourceAbility.name + " has an improper ActionStepResult and cannot be previewed.")
			index += 1


func ToJSON():
	var dict = super()
	dict["type"] = "GESlowSpeedAttack"
	return dict

func InitFromJSON(_dict : Dictionary):
	super(_dict)
	position = Origin.GlobalPosition
	UpdatePositionOnGrid()
	UpdateTelegraph()
	pass
