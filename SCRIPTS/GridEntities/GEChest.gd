extends GridEntityBase
class_name GEChest

@export var loot : LootTable
@export var visual : AnimatedSprite2D
@export var openAnimName : String = "open"
@export var unlockSound : FmodEventEmitter2D

var claimed : bool = false


func Spawn(_map : Map, _origin : Tile, _source : UnitInstance, _ability : Ability, _allegience : GameSettingsTemplate.TeamID, _direction : GameSettingsTemplate.Direction):
	super(_map, _origin, _source, _ability, _allegience, _direction)
	_origin.AddEntity(self)

func Claim(_claimingUnit : UnitInstance):
	if Map.Current == null || claimed:
		return

	var rolledLoot = loot.RollTable(Map.Current.mapRNG, 1, false)
	if rolledLoot[0] is ItemRewardEntry:
		_claimingUnit.QueueAcquireLoot(rolledLoot[0].ItemPrefab.instantiate())
	
	if unlockSound != null:
		unlockSound.play()
		
	claimed = true
	visual.play(openAnimName)


func ToJSON():
	var dict = super()
	dict["type"] = "GEChest"
	dict["claimed"] = claimed
	return dict

func InitFromJSON(_dict : Dictionary):
	super(_dict)
	position = Origin.GlobalPosition
	claimed = _dict["claimed"]
	if claimed:
		visual.play(openAnimName)
	Origin.AddEntity(self)
	pass
