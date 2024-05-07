extends AbilityActionBase
class_name AATargetingSimple

@export var AbilityRange : Vector2i

var TargetData : TargetingData
var ReturnedTargets
var ctrl : PlayerController

func _Enter(_context : AbilityContext):
	ReturnedTargets = null
	TargetData = TargetingData.new()
	TargetData.TargetRange = AbilityRange
	var options =  _context.grid.GetCharacterAttackOptions(_context.source, [_context.source.CurrentTile], TargetData.TargetRange)
	options.sort_custom(OrderTargets)
	TargetData.TilesInRange = options
	TargetData.Type = TargetingData.TargetingType.Simple

	_context.grid.ShowActions()

	ctrl = _context.controller
	if not ctrl.OnTileSelected.is_connected(ReturnedTile):
		ctrl.OnTileSelected.connect(ReturnedTile)

	ctrl.EnterTargetingState(TargetData)
	return true

func _Execute(_context : AbilityContext):
	# Waits for ReturnedTile to be called and for a valid target to be returned before going through
	if ReturnedTargets != null:
		_context.target = ReturnedTargets
		return true
	return false

# called from the targeting system. Free's the _execute loop to go through
func ReturnedTile(_tile : Tile):
	ctrl.OnTileSelected.disconnect(ReturnedTile)
	if _tile != null && _tile.Occupant != null:
		ReturnedTargets = _tile.Occupant

# Orders the Tiles based on if they're currently occupied by another unit
func OrderTargets(a : Tile, b : Tile):
	if a.Occupant == null && b.Occupant == null:
		return true

	if a.Occupant != null && b.Occupant == null:
		return true
	elif a.Occupant == null && b.Occupant != null:
		return false

	if a.Occupant != null && b.Occupant != null:
		var aHealth = (a.Occupant.currentHealth / a.Occupant.maxHealth)
		var bHealth = (b.Occupant.currentHealth / b.Occupant.maxHealth)
		return aHealth < bHealth

	return true
