extends Control
class_name ManageItemsPanel


signal OnClose

@export var selectedUnitIcon : TextureRect
@export var unitEntryList : EntryList
@export var unitEntryPrefab : PackedScene
@export var itemEntryList : EntryList
@export var itemEntryPrefab : PackedScene
@export var weaponPanel : WeaponPanelUI


@export_category("Buttons")

@export var tradeBtn : Button
@export var craftBtn : Button
@export var convoyBtn : Button


var hoveredUnit : UnitInstance
var hoveredEntry
var selectedUnit : UnitInstance
var map : Map
var campaign : CampaignTemplate
var selectedIndex : int = 0
var tradeUI : TradeUI


# REMOVE THIS WHEN YOU IMPLEMENT THIS
var craftingEnabled = false

func Initialize(_currentMap : Map, _campaign : CampaignTemplate):
	# Campaign CAN be null if we initialize from editor. Don't rely on it being not null
	map = _currentMap
	campaign = _campaign
	RefreshUnits()
	UpdateContextualButtons(false)
	pass

func UpdateContextualButtons(_enabled : bool):
	SetButtonEnabled(tradeBtn, _enabled)
	SetButtonEnabled(craftBtn, _enabled && craftingEnabled)
	SetButtonEnabled(convoyBtn, _enabled)

func UpdateUnitListButtons(_enabled : bool):
	for entry in unitEntryList.createdEntries:
		if entry is Button:
			SetButtonEnabled(entry, _enabled)

func SetButtonEnabled(_button : Button, _enabled : bool):
	if _enabled:
		_button.disabled = false
		_button.focus_mode = Control.FOCUS_ALL
	else:
		_button.disabled = true
		_button.focus_mode = Control.FOCUS_NONE


func _process(_delta):
	if tradeUI != null:
		return

	if InputManager.cancelDown && visible:
		if selectedUnit == null:
			OnClose.emit()
			visible = false
		else:
			selectedUnit = null
			UpdateContextualButtons(false)
			UpdateUnitListButtons(true)
			hoveredEntry.grab_focus()

	if InputManager.selectDown && visible:
		if selectedUnit == null && hoveredUnit != null:
			selectedUnit = hoveredUnit
			UpdateContextualButtons(true)
			UpdateUnitListButtons(false)
			tradeBtn.grab_focus()


func RefreshUnits():
	if map == null:
		return

	# We do it like this because we can't rely on the Campaign to be not-null right now.
	# If we want this ui to be displayed at any time
	var allyUnits = map.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY)
	unitEntryList.ClearEntries()
	for u in allyUnits:
		var entry = unitEntryList.CreateEntry(unitEntryPrefab)
		entry.Initialize(u)
		entry.focus_entered.connect(OnFocusChanged.bind(u, entry))

	unitEntryList.FocusFirst()


func OnFocusChanged(_unit : UnitInstance, _entry):
	if _unit == null || _unit.Template == null:
		return

	selectedUnitIcon.texture = _unit.Template.icon
	hoveredUnit = _unit
	hoveredEntry = _entry

	itemEntryList.ClearEntries()
	for item in _unit.ItemSlots:
		var entry = itemEntryList.CreateEntry(itemEntryPrefab)
		entry.Refresh(item)

	if weaponPanel != null:
		weaponPanel.Refresh(_unit.EquippedWeapon)
	pass

func OnTradeButton():
	if tradeUI != null:
		return

	tradeUI = TradeUI.ShowUI(self, selectedUnit, false)
	tradeUI.OnClose.connect(OnTradeUIClosed)

func OnConvoyButton():
	if tradeUI != null:
		return

	tradeUI = TradeUI.ShowUI(self, selectedUnit, true)
	tradeUI.OnClose.connect(OnTradeUIClosed)

func OnTradeUIClosed():
	if tradeUI != null:
		tradeUI.OnClose.disconnect(OnTradeUIClosed)
	tradeUI = null
	tradeBtn.grab_focus()
	OnFocusChanged(hoveredUnit, hoveredEntry)
