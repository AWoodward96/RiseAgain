class_name Tile

var GlobalPosition
var Position
var IsWall

var Health : int = -1
var MaxHealth : int = -1
var Killbox : bool

var CanAttack: bool
var CanMove: bool
var InRange : bool
var Occupant : UnitInstance

var popupStack : Array[Node2D]
var popingOffPopups : bool = false

var damageIndicator : DamageIndicator

func AsTargetData():
	var target = TileTargetedData.new()
	target.Tile = self
	return target


func PlayPopupDeffered():
	popingOffPopups = true

	var nextPopup = popupStack.pop_front() as Node2D
	while(nextPopup != null):
		nextPopup.visible = true
		var anim = nextPopup.find_child("AnimationPlayer") as AnimationPlayer
		if anim != null:
			anim.active = true
		await nextPopup.get_tree().create_timer(Juice.combatPopupCooldown).timeout


		nextPopup = popupStack.pop_front()


	popingOffPopups = false


func QueuePopup(_node : Node):
	_node.visible = false
	popupStack.append(_node)
	if !popingOffPopups:
		PlayPopupDeffered()
	pass

func PreviewDamage(_normalDamage : int, _collisionDamage : int, _heal : int):
	if Health == 0 || Health == -1:
		return false

	if damageIndicator == null:
		damageIndicator = Juice.CreateDamageIndicator(self) as DamageIndicator
		damageIndicator.SetHealthLevels(Health, MaxHealth)

	damageIndicator.normalDamage += _normalDamage
	damageIndicator.collisionDamage += _collisionDamage
	damageIndicator.healAmount += _heal

	# Everything should always hit this
	damageIndicator.hitChance = 100
	return true

func CancelPreview():
	if damageIndicator != null:
		damageIndicator.queue_free()
	damageIndicator = null
