extends Node2D
class_name ConvoyInstance

var ItemInventory : Array[Ability]
var WeaponInventory : Array[Ability]
var TacticalInventory : Array[Ability]

func _ready():
	# Should not be visible - should just hold all our items
	visible = false


func AddToConvoy(_unitUsable : Ability):
	if _unitUsable == null:
		return

	if _unitUsable is Item:
		ItemInventory.append(_unitUsable as Item)
	elif _unitUsable.type == Ability.EAbilityType.Weapon:
		WeaponInventory.append(_unitUsable)
	elif _unitUsable.type == Ability.EAbilityType.Tactical:
		TacticalInventory.append(_unitUsable)
	else:
		push_error("Could not add usable to Convoy: ", _unitUsable.internalName)
		return

	add_child(_unitUsable)


func GetWeaponsThatMatchDescriptor(_descriptorTemplate : DescriptorTemplate):
	var returnArray : Array[Ability] = []
	for abl in WeaponInventory:
		if abl.descriptors.has(_descriptorTemplate):
			returnArray.append(abl)

	return returnArray


func EquipWeaponFromConvoy(_unit : UnitInstance, _weapon : Ability):
	var weaponIndex = WeaponInventory.find(_weapon)
	if weaponIndex == -1:
		push_error("Trying to equip a weapon from convoy that isn't in the convoy? That's super illegal.")
		return

	if _weapon.type != Ability.EAbilityType.Weapon:
		return

	if _unit.Template.CanUseWeapon(_weapon):
		# This AddAbilityInstance automatically moves their equipped weapon to convoy
		# Has to be removed first before it can be re-added or else we're gonna throw an error
		WeaponInventory.remove_at(weaponIndex)
		remove_child(_weapon)
		_unit.AddAbilityInstance(_weapon)

func EquipTacticalFromConvoy(_unit : UnitInstance, _tactical : Ability):
	var tacIndex = TacticalInventory.find(_tactical)
	if tacIndex == -1:
		push_error("Trying to equip a tactical from convoy that isn't in the convoy? That's super illegal.")
		return

	if _tactical.type != Ability.EAbilityType.Tactical:
		return

	TacticalInventory.remove_at(tacIndex)
	remove_child(_tactical)
	_unit.AddAbilityInstance(_tactical)


func EquipItemFromConvoy(_unit : UnitInstance, _item : Item, _inventorySlot : int):
	var index = ItemInventory.find(_item)
	if index == -1:
		return

	if _unit == null || _inventorySlot < 0 || _inventorySlot >= GameManager.GameSettings.ItemSlotsPerUnit:
		return

	var item = ItemInventory[index]
	ItemInventory.remove_at(index)
	remove_child(item)
	_unit.EquipItem(_inventorySlot, item)


func ToJSON():
	var dict = {
		"ItemInventory" = PersistDataManager.ArrayToJSON(ItemInventory),
		"WeaponInventory" = PersistDataManager.ArrayToJSON(WeaponInventory)
	}
	return dict

func FromJSON(_dict):
	for element in _dict["ItemInventory"]:
		if element == "NULL":
			continue

		var elementAsDict = JSON.parse_string(element)
		if elementAsDict == null:
			continue

		var prefab = load(elementAsDict["prefab"]) as PackedScene
		if prefab == null:
			continue

		var newInstance = prefab.instantiate() as Item
		newInstance.FromJSON(elementAsDict)
		add_child(newInstance)
		ItemInventory.append(newInstance)

	for element in _dict["WeaponInventory"]:
		var elementAsDict = JSON.parse_string(element)
		var prefab = load(elementAsDict["prefab"]) as PackedScene
		var newInstance = prefab.instantiate()
		if newInstance != null:
			newInstance.FromJSON(elementAsDict)
			add_child(newInstance)
			WeaponInventory.append(newInstance)

	if _dict.has("TacticalInventory"):
		for element in _dict["TacticalInventory"]:
			var elementAsDict = JSON.parse_string(element)
			var prefab = load(elementAsDict["prefab"]) as PackedScene
			var newInstance = prefab.instantiate()
			if newInstance != null:
				newInstance.FromJSON(elementAsDict)
				add_child(newInstance)
				TacticalInventory.append(newInstance)
