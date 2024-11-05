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

var popupStack : Array[Node]
var popingOffPopups : bool = false

func AsTargetData():
	var target = TileTargetedData.new()
	target.Tile = self
	return target


func PlayPopupDeffered():
	popingOffPopups = true

	var nextPopup = popupStack.pop_front()
	while(nextPopup != null):
		nextPopup.visible = true
		await nextPopup.get_tree().create_timer(Juice.combatPopupCooldown)
		nextPopup = popupStack.pop_front()

	popingOffPopups = false
#
	#pass


func QueuePopup(_node : Node):
	_node.visible = false
	popupStack.append(_node)
	if !popingOffPopups:
		PlayPopupDeffered()
	pass
