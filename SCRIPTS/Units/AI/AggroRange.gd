extends AggroOnDamage
class_name AggroRange

# -----------------------
# Aggros if any unit in the TargetingFlags is within either Movement range, or the RangeOverride variable
# -----------------------

@export_flags("ALLY", "ENEMY", "NEUTRAL") var TargetingFlags : int = 1
# If this is not 0, then it should use this instead of the units movement speed
@export var RangeOverride = 0
@export var WeaponRangeAggros : bool = true


func Check(_self : UnitInstance, _map : Map) -> bool:
	var grid = _map.grid
	var range = _self.GetUnitMovement() + _self.GetEffectiveAttackRange().y
	if RangeOverride != 0:
		range = RangeOverride

	var allUnits = _map.GetUnitsOnTeam(TargetingFlags)
	for u in allUnits:
		if u == null || u.CurrentTile == null:
			continue

		if _self.EquippedWeapon != null && WeaponRangeAggros:
			var manhattanDistence = grid.GetManhattanDistance(_self.GridPosition, u.GridPosition)
			var weaponRange = _self.EquippedWeapon.GetRange()
			if manhattanDistence >= weaponRange.x && manhattanDistence <= weaponRange.y:
				return true


		# Remember to use this helper method because otherwise, the Unit might be a wall depending on whose turn it is
		var path = grid.GetPathBetweenTwoUnits(_self, u)
		if path.size() == 0:
			continue

		# Path.Size - 1, because GetPathBetweenTwoUnits includes the origin, IE, selfs currentTile
		if path.size() - 1 <= range:
			return true



	return false
