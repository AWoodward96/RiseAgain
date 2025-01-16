extends CanvasLayer
class_name TradeUI

signal OnClose()

enum UIState { SelectUnit, SelectItem, SelectNewSlot, ConvoyState }

@export_category("General")
@export var unit2Parent : Control
@export var unitSelectionParent : Control
@export var itemSlotPrefab : PackedScene
@export var unitSelectionEntryList : EntryList
@export var unitEntryPrefab : PackedScene

@export_category("Convoy Info")
@export var convoyParent : Control
@export var convoyNoItems : Control
@export var convoyList : EntryList

@export_category("MoveWherePanel")
@export var moveWhereParent : Control
@export var moveWhereIcon : TextureRect
@export var moveWhereLabel : Label

@export_category("Unit 1")
@export var unit1Icon : TextureRect
@export var unit1Name : Label
@export var unit1ItemEntryList : EntryList

@export_category("Unit 2")
@export var unit2Icon : TextureRect
@export var unit2Name : Label
@export var unit2ItemEntryList : EntryList

var currentState : UIState
var currentUnit : UnitInstance
var otherUnit : UnitInstance

var selectedItemIsFromCurrent : bool
var selectedItemIndex : int
var convoyMode : bool

func Initialize(_unitInstance : UnitInstance, _convoyMode : bool):
	currentUnit = _unitInstance
	convoyMode = _convoyMode

func _ready():
	moveWhereParent.visible = false
	unit2Parent.visible = false

	unitSelectionParent.visible = !convoyMode
	convoyParent.visible = convoyMode


	if !convoyMode:
		UpdateUnit1Panel(false)
		UpdateUnitSelection()
	else:
		UpdateUnit1Panel(true)
		unit1ItemEntryList.FocusFirst()
		UpdateConvoy()
		currentState = UIState.ConvoyState


func _process(_delta):
	if InputManager.cancelDown:
		match(currentState):
			UIState.SelectUnit, UIState.ConvoyState:
				visible = false
				OnClose.emit()
				queue_free()
			UIState.SelectItem:
				otherUnit = null
				unit2Parent.visible = false
				unitSelectionParent.visible = true
				UpdateUnit1Panel(false)
				UpdateUnitSelection()
				currentState = UIState.SelectUnit

func UpdateUnit1Panel(_showItems : bool):
	if unit1Icon != null: unit1Icon.texture = currentUnit.Template.icon
	if unit1Name != null: unit1Name.text = currentUnit.Template.loc_DisplayName

	var index = 0
	if unit1ItemEntryList != null: unit1ItemEntryList.ClearEntries()
	if _showItems && unit1ItemEntryList != null:
		for slot in currentUnit.ItemSlots:
			var entry = unit1ItemEntryList.CreateEntry(itemSlotPrefab)
			entry.Refresh(slot)

			if !convoyMode:
				entry.OnSelected.connect(OnItemSlotSelected.bind(true, slot, index))
			else:
				entry.OnSelected.connect(OnItemSentToConvoy.bind(slot, index))
			index += 1

func UpdateUnit2Panel(_showItems : bool):
	if otherUnit == null:
		return

	if unit2Icon != null: unit2Icon.texture = otherUnit.Template.icon
	if unit2Name != null: unit2Name.text = otherUnit.Template.loc_DisplayName

	var index = 0
	if unit2ItemEntryList != null: unit2ItemEntryList.ClearEntries()
	if _showItems && unit2ItemEntryList != null:
		for slot in otherUnit.ItemSlots:
			var entry = unit2ItemEntryList.CreateEntry(itemSlotPrefab)
			entry.Refresh(slot)
			entry.OnSelected.connect(OnItemSlotSelected.bind(false, slot, index))
			index += 1

func UpdateConvoy():
	if GameManager.CurrentCampaign == null:
		return

	convoyList.ClearEntries()
	convoyNoItems.visible = GameManager.CurrentCampaign.Convoy.size() == 0
	for item in GameManager.CurrentCampaign.Convoy:
		var entry = convoyList.CreateEntry(itemSlotPrefab)
		entry.Refresh(item)
		entry.OnSelected.connect(OnItemTakenFromConvoy.bind(item))

	pass

func UpdateUnitSelection():
	var map = Map.Current
	if map == null:
		return

	unitSelectionEntryList.ClearEntries()
	var allAllies = map.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY)
	for u in allAllies:
		if u == currentUnit:
			continue

		var entry = unitSelectionEntryList.CreateEntry(unitEntryPrefab)
		entry.Initialize(u)
		entry.pressed.connect(OtherUnitSelected.bind(u))

	unitSelectionEntryList.FocusFirst()

func OtherUnitSelected(_unit : UnitInstance):
	otherUnit = _unit
	currentState = UIState.SelectItem

	unit2Parent.visible = true
	unitSelectionParent.visible = false
	UpdateUnit2Panel(true)
	UpdateUnit1Panel(true)
	unit1ItemEntryList.FocusFirst()

func OnItemSentToConvoy(_item : Item, _index: int):
	if _item == null:
		# Get outa here - no null items allowed in the convoy
		return

	var campaign = GameManager.CurrentCampaign

	currentUnit.EquipItem(_index, null)
	campaign.AddItemToConvoy(_item)

	UpdateUnit1Panel(true)
	UpdateConvoy()
	unit1ItemEntryList.FocusFirst()

func OnItemTakenFromConvoy(_item : Item):
	var campaign = GameManager.CurrentCampaign
	var index = currentUnit.ItemSlots.find(null, 0) # This should work
	if index == -1:
		# there are no empty slots so it can't be taken out
		return

	campaign.RemoveItemFromConvoy(_item,currentUnit,index)
	UpdateUnit1Panel(true)
	UpdateConvoy()

	if GameManager.CurrentCampaign.Convoy.size() == 0:
		unit1ItemEntryList.FocusFirst()

func OnItemSlotSelected(_isCurrentOrOther : bool, _item : Item, _index : int):
	if currentState == UIState.SelectItem:
		if _item == null:
			return

		selectedItemIsFromCurrent = _isCurrentOrOther
		selectedItemIndex = _index
		currentState = UIState.SelectNewSlot

		moveWhereParent.visible = true
		moveWhereIcon.texture = _item.icon
		moveWhereLabel.text = tr("ui_move_item_where").format({"ITEM" : tr(_item.loc_displayName)})
	elif currentState == UIState.SelectNewSlot:
		# Case 1: Item is in the same exact slot
		if _isCurrentOrOther == selectedItemIsFromCurrent && selectedItemIndex == _index:
			# do nothing.
			return

		# Case 2: Item is moved to a slot in the same unit
		if _isCurrentOrOther == selectedItemIsFromCurrent && selectedItemIndex != _index:
			var unit = currentUnit
			if !selectedItemIsFromCurrent:
				unit = otherUnit

			var itemAtIndex = unit.ItemSlots[_index]
			unit.EquipItem(_index, unit.ItemSlots[selectedItemIndex])
			unit.EquipItem(selectedItemIndex, itemAtIndex)

		# Case 3: Item is moved from one inventory to another
		if _isCurrentOrOther != selectedItemIsFromCurrent:
			var fromUnit : UnitInstance
			var toUnit : UnitInstance
			if selectedItemIsFromCurrent:
				fromUnit = currentUnit
				toUnit = otherUnit
			else:
				fromUnit = otherUnit
				toUnit = currentUnit

			var itemAtToUnit = toUnit.ItemSlots[_index]
			toUnit.EquipItem(_index, fromUnit.ItemSlots[selectedItemIndex])
			fromUnit.EquipItem(selectedItemIndex, itemAtToUnit)

		moveWhereParent.visible = false
		currentState = UIState.SelectItem

		UpdateUnit2Panel(true)
		UpdateUnit1Panel(true)
		unit1ItemEntryList.FocusFirst()
		pass

	pass


static func ShowUI(_parent : Control, _unit : UnitInstance, _isConvoy : bool):
	var tradeUI = UIManager.TradeUIPrefab.instantiate() as TradeUI
	tradeUI.Initialize(_unit, _isConvoy)
	_parent.add_child(tradeUI)
	return tradeUI
