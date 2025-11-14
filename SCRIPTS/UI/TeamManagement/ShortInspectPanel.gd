extends Control
class_name ShortInspectPanel

signal WeaponSelectedForSwap(_ability : Ability)
signal TacticalSelectedForSwap(_ability : Ability)
signal ItemSelectedForSwap(_slot : int)

@export var nameLabel : Label
@export var iconTexture : TextureRect
@export var animator : AnimationPlayer

@export var shortformAbilityPrefab : PackedScene
@export var weaponParent : Control
@export var tacticalParent : Control
@export var heldItemParents : Array[Control]

@export var prestiegeParent : Control
@export var prestiegeLevel : Label
@export var prestiegeExp : Label

@export var healthLevelParent : Control
@export var levelLabel : Label
@export var healthLabel : Label



var template : UnitTemplate
var unitInstance : UnitInstance
var unitPersist : UnitPersistBase
var createdShortformEntries : Array[Control]

var referencedWeapon : Ability
var referencedTactical : Ability
# The difference between these is that the above ones already exist
# and the bottom ones need to be cleaned up after this ui closes because they don't exist
var instancedWeapon : Ability
var instancedTactical : Ability

func _ready():
	for i in range(0, GameManager.GameSettings.ItemSlotsPerUnit):
		heldItemParents[i].pressed.connect(OnItemEntrySelected.bind(i))

func RefreshTemplate(_unit : UnitTemplate):
	template = _unit
	unitPersist = PersistDataManager.universeData.GetUnitPersistence(template)
	UpdateHeader()
	CreateShortformAbilityEntries()
	pass

func RefreshInstance(_unit : UnitInstance):
	template = _unit.Template
	unitInstance = _unit
	unitPersist = PersistDataManager.universeData.GetUnitPersistence(template)
	UpdateHeader()
	CreateShortformAbilityEntries()
	pass

func UpdateHeader():
	nameLabel.text = template.loc_DisplayName
	iconTexture.texture = template.icon

	if unitInstance != null:
		prestiegeParent.visible = false
		healthLevelParent.visible = true
		levelLabel.text = tr(LocSettings.Level_Num).format({"NUM" = unitInstance.DisplayLevel})
		healthLabel.text = tr(LocSettings.Current_Max).format({"CUR" = unitInstance.currentHealth, "MAX" = "%d" %  unitInstance.maxHealth})
	elif unitPersist != null:
		prestiegeParent.visible = true
		healthLevelParent.visible = false

		var nextExpBreakpoint = GameManager.UnitSettings.GetPrestiegeBreakpoint(unitPersist.PrestiegeLevel)
		prestiegeLevel.text = tr(GameManager.LocalizationSettings.prestiegeLevelNum).format({"NUM" = unitPersist.PrestiegeDisplayLevel})
		prestiegeExp.text = tr(GameManager.LocalizationSettings.prestiegeExpValue).format({"CUR" = unitPersist.PrestiegeEXP, "MAX" = nextExpBreakpoint})
		pass

func CreateShortformAbilityEntries():
	for ent in createdShortformEntries:
		ent.queue_free()
	createdShortformEntries.clear()


	# Get the proper reference to both the weapon and the tactical depending on if we have a unit instance or not
	if unitInstance != null:
		# if it's an instance, they should already have them
		referencedWeapon = null
		referencedTactical = null
		for abl in unitInstance.Abilities:
			if abl.type == Ability.AbilityType.Weapon:
				referencedWeapon = abl
			if abl.type == Ability.AbilityType.Tactical:
				referencedTactical = abl
	else:
		# if it's not an instance, you should grab it from persistence
		if unitPersist != null:
			# if persistence is null - uhhh break. You shouldn't be able to modify any units stuff without persistence
			if unitPersist.EquippedStartingWeapon != null:
				var packedScene = load(unitPersist.EquippedStartingWeapon.AbilityPath) as PackedScene
				if packedScene != null:
					instancedWeapon = packedScene.instantiate()
					referencedWeapon = instancedWeapon

			if unitPersist.EquippedStartingTactical != null:
				var packedScene = load(unitPersist.EquippedStartingTactical.AbilityPath) as PackedScene
				if packedScene != null:
					instancedTactical = packedScene.instantiate()
					referencedTactical = instancedTactical

	# These don't matter if they're null or not, because the entry should handle a null initialize gracefully
	var weaponEntry = shortformAbilityPrefab.instantiate()
	weaponEntry.Initialize(referencedWeapon)
	weaponParent.add_child(weaponEntry)
	createdShortformEntries.append(weaponEntry)

	var tacticalEntry = shortformAbilityPrefab.instantiate()
	tacticalEntry.Initialize(referencedTactical)
	tacticalParent.add_child(tacticalEntry)
	createdShortformEntries.append(tacticalEntry)

	# now for the held items
	# pretty straight forward - if we have a template initialize ...
	# ... all of them to null because outside of a run no unit is going to hold an item
	# if we have an instance, just grab the item slots
	if unitInstance != null:
		for i in range(0, GameManager.GameSettings.ItemSlotsPerUnit):
			var item = unitInstance.ItemSlots[i]
			if i < heldItemParents.size():
				var itemEntry = shortformAbilityPrefab.instantiate()
				itemEntry.Initialize(item)
				heldItemParents[i].add_child(itemEntry)
				createdShortformEntries.append(itemEntry)

			heldItemParents[i].focus_mode = Control.FOCUS_ALL
	else:
		for parent in heldItemParents:
			var emptyEntry = shortformAbilityPrefab.instantiate()
			parent.add_child(emptyEntry)
			emptyEntry.Initialize(null)
			createdShortformEntries.append(emptyEntry)
			parent.focus_mode = Control.FOCUS_NONE
	pass

func ReturnFocus():
	weaponParent.grab_focus()

func EnableFocus(_enabled : bool):
	if _enabled:
		weaponParent.focus_mode = Control.FOCUS_ALL
		tacticalParent.focus_mode = Control.FOCUS_ALL
	else:
		weaponParent.focus_mode = Control.FOCUS_NONE
		tacticalParent.focus_mode = Control.FOCUS_NONE

	for parent in heldItemParents:
		if unitInstance != null:
			if _enabled:
				parent.focus_mode = Control.FOCUS_ALL
			else:
				parent.focus_mode = Control.FOCUS_NONE
		else:
			parent.focus_mode = Control.FOCUS_NONE

func OnWeaponSelected():
	WeaponSelectedForSwap.emit(referencedWeapon)
	pass

func OnTacticalSelected():
	TacticalSelectedForSwap.emit(referencedTactical)
	pass

func OnItemEntrySelected(_itemSlotIndex : int):
	ItemSelectedForSwap.emit(_itemSlotIndex)
	pass

func PlayEquipWeapon():
	if animator != null:
		animator.play("EquipWeapon")
	pass

func PlayEquipTactical():
	if animator != null:
		animator.play("EquipTactical")
	pass

func _exit_tree() -> void:
	if instancedTactical != null:
		instancedTactical.queue_free()

	if instancedWeapon != null:
		instancedWeapon.queue_free()
