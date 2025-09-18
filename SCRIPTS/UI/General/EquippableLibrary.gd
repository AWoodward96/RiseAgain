extends Control
class_name EquippableLibrary

signal OnEquippableSelected(_equippable : AbilityUnlockable)
signal OnUnequipSelected()

const NOT_FOUND_LIBRARY = "ui_no_weapons_in_library"
const NOT_FOUND_CONVOY = "ui_no_weapons_in_convoy"
const SWAP_WEAPON = "ui_swap_weapon_prompt"

@export var preInitializeMatchingULKs : bool = false
@export var swapHeaderLabel : RichTextLabel
@export var entryParent : EntryList
@export var entryPrefab : PackedScene
@export var makeUnequipEntry : bool = false
@export var unequipEntryPrefab : PackedScene
@export var tabBar : TabBar
@export var noEntriesFoundLabel : RichTextLabel
@export var tabs : Array[DescriptorTemplate]


## This element will grab all ULK's based on this descriptor. Then it will be filtered down by the subfilter called in the Refresh
@export var baseFilter : DescriptorTemplate
var subFilter : Array[DescriptorTemplate]

var currentMode : TeamManagementUI.UIMode
var allULKsMatchingBaseFilter : Array[UnlockableContentTemplate]
var subfilteredULKs : Array[UnlockableContentTemplate]
var instancedAbilities : Array[Ability]
var acceptInput : bool
var currentTabIndex : int = 0
var lastFocusedElement : Control

func _ready():
	# We do this no matter what - I'm not sure if that's a good thing or not
	if preInitializeMatchingULKs:
		allULKsMatchingBaseFilter =  PersistDataManager.universeData.GetListOfUnlockData(true, [baseFilter] as Array[DescriptorTemplate])

	UIManager.FocusChanged.connect(OnFocusChanged)

	pass

func _process(_delta: float) -> void:
	if acceptInput:
		if InputManager.inputDown[1]:
			currentTabIndex += 1
			Refresh()
			pass
		if InputManager.inputDown[3]:
			currentTabIndex -= 1
			Refresh()
			pass

func Initialize(_tabs : Array[DescriptorTemplate], _mode : TeamManagementUI.UIMode, _ability : Ability = null):
	tabs = _tabs
	currentTabIndex = 0
	currentMode = _mode

	if !preInitializeMatchingULKs:
		allULKsMatchingBaseFilter =  PersistDataManager.universeData.GetListOfUnlockData(true, [baseFilter])

	if swapHeaderLabel != null:
		if _ability != null:
			swapHeaderLabel.visible = true
			var format = {}
			if _ability.icon != null:
				format["WEAPONICON"] = _ability.icon.resource_path
			format["NAME"] = tr(_ability.loc_displayName)
			swapHeaderLabel.text = tr(SWAP_WEAPON).format(format)
		else:
			swapHeaderLabel.visible = false

	RefreshTabs()
	Refresh()
	pass

func RefreshTabs():
	if tabs.size() < 1:
		if tabBar != null:
			tabBar.visible = false
	else:
		tabBar.visible = true
		tabBar.clear_tabs()
		for des in tabs:
			tabBar.add_tab(des.loc_name, des.icon)

func Refresh():
	if currentTabIndex < 0:
		currentTabIndex = tabs.size() - 1
	elif currentTabIndex >= tabs.size():
		currentTabIndex = 0

	if tabBar != null && tabs.size() > 0:
		tabBar.current_tab = currentTabIndex
		pass

	if currentMode == TeamManagementUI.UIMode.OutOfRun:
		CreateEntriesFromULKs()
	else:
		CreateEntriesFromConvoy()

func CreateEntriesFromConvoy():
	entryParent.ClearEntries()
	var list : Array[Ability] = []
	match baseFilter:
		GameManager.GameSettings.TacticalDescriptor:
			list = GameManager.CurrentCampaign.Convoy.TacticalInventory
		GameManager.GameSettings.WeaponDescriptor:
			list = GameManager.CurrentCampaign.Convoy.GetWeaponsThatMatchDescriptor(tabs[currentTabIndex])
		GameManager.GameSettings.HeldItemsDescriptor:
			list = GameManager.CurrentCampaign.Convoy.ItemInventory

	#if list.size() == 0:
		#noEntriesFoundLabel.visible = true
		#var formatDict = {}
		#if tabs.size() > 0:
			#formatDict["ICON"] = tabs[currentTabIndex].icon.resource_path
		#elif baseFilter != null:
			#formatDict["ICON"] = baseFilter.icon.resource_path
		#noEntriesFoundLabel.text = tr(NOT_FOUND_CONVOY).format(formatDict)
		#return
#
	#noEntriesFoundLabel.visible = false
	for e in list:
		var entry = entryParent.CreateEntry(entryPrefab)
		entry.Initialize(e)
		entry.OnPressed.connect(OnEntrySelected)


	if makeUnequipEntry:
		CreateUnequipEntry()
	entryParent.FocusFirst()


	pass

func CreateEntriesFromULKs():
	if tabs.size() > 0:
		UpdateSubfilter(tabs[currentTabIndex])
	else:
		subfilteredULKs = allULKsMatchingBaseFilter

	#if subfilteredULKs.size() == 0:
		#noEntriesFoundLabel.visible = true
#
		#var formatDict = {}
		#if tabs.size() > 0:
			#formatDict["ICON"] = tabs[currentTabIndex].icon.resource_path
		#elif baseFilter != null:
			#formatDict["ICON"] = baseFilter.icon.resource_path
#
		#noEntriesFoundLabel.text = tr(NOT_FOUND_LIBRARY).format(formatDict)
		#return
#
	#noEntriesFoundLabel.visible = false

	ClearInstancedAbilities()
	entryParent.ClearEntries()
	for ulk : AbilityUnlockable in subfilteredULKs:
		if ulk is not AbilityUnlockable:
			continue

		var packedAbility = load(ulk.AbilityPath)
		if packedAbility == null:
			push_error("Could not load packed ability from packed ability {0}. AbilityPath: {1}".format([ulk.resource_path, ulk.AbilityPath]))
			continue

		var ability = packedAbility.instantiate()
		instancedAbilities.append(ability)

		var entry = entryParent.CreateEntry(entryPrefab)
		entry.Initialize(ability, ulk)
		entry.OnPressed.connect(OnEntrySelected)

	if makeUnequipEntry:
		CreateUnequipEntry()
	entryParent.FocusFirst()

	pass

func ClearInstancedAbilities():
	for a in instancedAbilities:
		a.queue_free()

	instancedAbilities.clear()

func ReturnFocus():
	if lastFocusedElement != null:
		lastFocusedElement.grab_focus()
	else:
		entryParent.FocusFirst()
	pass

func OnFocusChanged(_element : Control):
	if !acceptInput:
		return

	var index = entryParent.createdEntries.find(_element)
	if index != -1:
		lastFocusedElement = _element

func Enable(_enabled : bool):
	acceptInput = _enabled
	for e in entryParent.createdEntries:
		if _enabled:
			e.focus_mode = Control.FOCUS_ALL
		else:
			e.focus_mode = Control.FOCUS_NONE

func OnEntrySelected(_abilityEntry : NewAbilityEntryUI):
	OnEquippableSelected.emit(_abilityEntry)
	pass

func CreateUnequipEntry():
	if unequipEntryPrefab != null:
		var entry = entryParent.CreateEntry(unequipEntryPrefab) as Button
		entry.pressed.connect(UnequipButtonPressed)

func UnequipButtonPressed():
	OnUnequipSelected.emit()
	pass

func UpdateSubfilter(_filter : DescriptorTemplate):
	# we have all the base filter, now we filter out based on the subfilter (probably like, Bow, or Sword, etc)
	subfilteredULKs.clear()
	for ulk in allULKsMatchingBaseFilter:
		var passesFilter = true

		if !ulk.Descriptors.has(_filter):
			passesFilter = false
			continue

		if passesFilter:
			subfilteredULKs.append(ulk)
