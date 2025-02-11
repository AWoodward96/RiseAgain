class_name Tile

var GlobalPosition
var Position
var IsWall

var MainTileData : TileMetaData 	# For the 'main' tile - or anything that sits on top of the bg
var BGTileData : TileMetaData		# For the 'bg' tile - which can never be null
var SubBGTileData : TileMetaData	# For the 'water' or other tiles that hide behind the BG - this CAN be null

var Health : int = -1
var MaxHealth : int = -1

var Killbox : bool
var ActiveKillbox : bool
var OnFire : bool :
	get:
		return FireLevel > 0

var FireLevel : int = 0

var CanAttack: bool
var CanMove: bool
var CanBuff : bool
var InRange : bool
var Occupant : UnitInstance

var GridEntities : Array[GridEntityBase]

var popupStack : Array[Node2D]
var popingOffPopups : bool = false

var damageIndicator : DamageIndicator


func InitMetaData():
	if MainTileData != null:
		MaxHealth = MainTileData.Health
		Health = MainTileData.Health

	Killbox = false
	if BGTileData != null:
		Killbox = BGTileData.Killbox

	if SubBGTileData != null:
		Killbox = Killbox || SubBGTileData.Killbox

# Handles what happens if a unit steps on this tile
# Returns true or false - if true then the unit's movement has been interrupted
func OnUnitTraversed(_unitInstance : UnitInstance):
	var result = GameSettingsTemplate.TraversalResult.OK
	for ge in GridEntities:
		# Since multiple GE's can be stacked on top of one another, each one needs to be checked to see if traversal
		# has interrupted their movement
		var nextResult = ge.OnUnitTraversed(_unitInstance, self)
		if int(result) < int(nextResult):
			result = nextResult

	return result

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

func AddEntity(_gridEntity : GridEntityBase):
	if !GridEntities.has(_gridEntity):
		GridEntities.append(_gridEntity)
	RefreshActiveKillbox()

func RemoveEntity(_gridEntity : GridEntityBase):
	if GridEntities.has(_gridEntity):
		var index = GridEntities.find(_gridEntity)
		GridEntities.remove_at(index)
	RefreshActiveKillbox()

func RefreshActiveKillbox():
	var hasPlatform = false
	for e in GridEntities:
		if e == null:
			continue

		if e is GEWalkablePlatform:
			hasPlatform = true
			break
	ActiveKillbox = Killbox && (MaxHealth == -1 || MaxHealth != -1 && Health <= 0) && !hasPlatform


func ToJSON():
	var dict = {
		"GlobalPosition" = GlobalPosition,
		"Position" = Position,
		"IsWall" = IsWall,
		"Health" = Health,
		"MaxHealth" = MaxHealth,
		"Killbox" = Killbox,
		"ActiveKillbox" = ActiveKillbox,
		"FireLevel" = FireLevel
	}

	if MainTileData != null:
		dict["MainTileData"] = MainTileData.resource_path

	if BGTileData != null:
		dict["BGTileData"] = BGTileData.resource_path

	if SubBGTileData != null:
		dict["SubBGTileData"] = SubBGTileData.resource_path

	return dict

static func FromJSON(_dict : Dictionary):
	var newTile = Tile.new()
	newTile.GlobalPosition =  PersistDataManager.String_To_Vector2(_dict["GlobalPosition"])
	newTile.Position = PersistDataManager.String_To_Vector2i(_dict["Position"])
	newTile.IsWall = _dict["IsWall"]
	newTile.Health = _dict["Health"]
	newTile.MaxHealth = _dict["MaxHealth"]
	newTile.Killbox = _dict["Killbox"]
	newTile.ActiveKillbox = _dict["ActiveKillbox"]

	if _dict.has("FireLevel"):
		newTile.FireLevel = _dict["FireLevel"]

	if _dict.has("MainTileData"):
		newTile.MainTileData = load(_dict["MainTileData"]) as TileMetaData

	if _dict.has("BGTileData"):
		newTile.BGTileData = load(_dict["BGTileData"]) as TileMetaData

	if _dict.has("SubBGTileData"):
		newTile.SubBGTileData = load(_dict["SubBGTileData"]) as TileMetaData

	return newTile
