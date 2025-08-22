extends DamageStepResult
class_name PushStepResult

var willCollide : bool
var canDamageUser : bool
var ctrl : PlayerController

func PreCalc():
	if TileTargetData == null:
		return

	if TileTargetData.pushCollision != null && TileTargetData.pushStack.size() != 0:
		willCollide = true

	HealthDelta = -GameManager.GameSettings.CollisionDamageCalculation(Source)


func PreviewResult(_map : Map):
	if TileTargetData == null:
		return

	ctrl = _map.playercontroller
	if ctrl == null:
		return

	for stack in TileTargetData.pushStack:
		var unit = stack.Subject
		if unit == null:
			continue

		unit.damage_indicator.SetHealthLevels(unit.currentHealth, unit.maxHealth)
		if unit == Source:
			# Prioritize death to killbox over other damage
			if stack.ResultingTile != null && stack.ResultingTile.ActiveKillbox && !unit.IsFlying:
				unit.damage_indicator.collisionDamage += -unit.currentHealth
			elif willCollide && canDamageUser:
				unit.damage_indicator.collisionDamage += HealthDelta

			# TODO: Make a system for phantoms - showing where a unit might be after an action is performed
			ctrl.movement_tracker.visible = true
			ctrl.movement_preview_sprite.visible = true
			ctrl.movement_tracker.clear_points()
			var positionalOffset = Vector2i(_map.grid.CellSize / 2, _map.grid.CellSize / 2)
			var points = PackedVector2Array()
			points.append(Vector2i(stack.Subject.CurrentTile.GlobalPosition) + positionalOffset)
			points.append(Vector2i(stack.ResultingTile.GlobalPosition) + positionalOffset)
			ctrl.movement_tracker.points = points

			if Source.Template.unitMovementPreview != null:
				ctrl.movement_preview_sprite.texture = Source.Template.unitMovementPreview
			else:
				ctrl.movement_preview_sprite.texture = Source.Template.icon
			ctrl.movement_preview_sprite.position = points[points.size() - 1]
		else:
			unit.PreviewModifiedTile(stack.ResultingTile)

			if stack.ResultingTile != null && stack.ResultingTile.ActiveKillbox && !unit.IsFlying:
				unit.damage_indicator.collisionDamage += -unit.currentHealth
			elif willCollide:
				unit.damage_indicator.collisionDamage += HealthDelta

	if willCollide:
		# The thing we're colliding with also takes damage
		var occupant = TileTargetData.pushCollision.Occupant
		if occupant != null:
			occupant.damage_indicator.collisionDamage += HealthDelta
			occupant.damage_indicator.SetHealthLevels(occupant.currentHealth, occupant.maxHealth)
		else:
			TileTargetData.pushCollision.PreviewDamage(0, HealthDelta, 0)
	pass

func CancelPreview():
	for stack in TileTargetData.pushStack:
		stack.Subject.ResetVisualToTile()

	if ctrl != null:
		ctrl.movement_preview_sprite.visible = false
		ctrl.movement_tracker.visible = false
