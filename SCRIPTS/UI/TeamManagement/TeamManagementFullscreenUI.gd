extends FullscreenUI
class_name TeamManagementUI

enum UIMode { OutOfRun, InRun }
@export var animator : AnimationPlayer
@export var shortInspectPanel : ShortInspectPanel
@export var inspectPanelVignette : Control
@export var gridPanel : TeamGridPanel
@export var weaponLibrary : EquippableLibrary
@export var tacticalLibrary : EquippableLibrary
@export var heldItemsLibrary : EquippableLibrary

var currentSelectedUnit : UnitTemplate
var swapAbility : Ability
var inWeaponSwap : bool = false
var inTacticalSwap : bool = false
var inItemSwap : bool = false
var currentUIMode : TeamManagementUI.UIMode
var itemSlotIndex : int = -1


func _ready():
	super()
	currentUIMode = TeamManagementUI.UIMode.OutOfRun
	if GameManager.CurrentCampaign != null:
		currentUIMode = TeamManagementUI.UIMode.InRun
	UIManager.FocusChanged.connect(FocusChanged)
	gridPanel.OnUnitSelected.connect(OnUnitSelected)
	weaponLibrary.OnEquippableSelected.connect(OnWeaponSwapSelected)
	weaponLibrary.OnUnequipSelected.connect(OnWeaponUnequipped)
	tacticalLibrary.OnEquippableSelected.connect(OnTacticalSwapSelected)
	tacticalLibrary.OnUnequipSelected.connect(OnTacticalUnequipped)
	heldItemsLibrary.OnEquippableSelected.connect(OnItemSwapSelected)
	heldItemsLibrary.OnUnequipSelected.connect(OnItemUnequipped)

	shortInspectPanel.WeaponSelectedForSwap.connect(OnWeaponSelected)
	shortInspectPanel.TacticalSelectedForSwap.connect(OnTacticalSelected)
	shortInspectPanel.ItemSelectedForSwap.connect(OnItemSlotSelected)
	shortInspectPanel.EnableFocus(false)

	gridPanel.panelType = currentUIMode
	gridPanel.Refresh()
	pass

func _process(_delta):
	if !visible || UIManager.HighestLevelUI != self:
		return

	if IsInDetailState:
		return

	if InputManager.cancelDown:
		InputManager.ReleaseCancel()
		if currentSelectedUnit != null:
			if !inWeaponSwap && !inTacticalSwap && !inItemSwap:
				# Need to see if we're in context selection too before we do this but for now I'm holding this here
				ExitInspectSelection()
			else:
				ExitAbilitySwap()
		else:
			queue_free()


func ReturnFocus():
	if currentSelectedUnit == null:
		gridPanel.ReturnFocus()
	elif !inWeaponSwap && !inTacticalSwap:
		shortInspectPanel.ReturnFocus()
	else:
		if inWeaponSwap:
			weaponLibrary.ReturnFocus()
		elif inTacticalSwap:
			tacticalLibrary.ReturnFocus()
		elif inItemSwap:
			heldItemsLibrary.ReturnFocus()

func OnUnitSelected(_unitTemplate : UnitTemplate):
	currentSelectedUnit = _unitTemplate
	EnterInspectSelection()
	pass

func OnWeaponSelected(_ability : Ability):
	EnterWeaponSwap(_ability)
	pass

func OnTacticalSelected(_ability : Ability):
	EnterTacticalSwap(_ability)
	pass

func OnItemSlotSelected(_index : int):
	EnterItemSwap(_index)
	pass

func OnWeaponUnequipped():
	if currentUIMode == UIMode.OutOfRun:
		var unitPersist = PersistDataManager.universeData.GetUnitPersistence(currentSelectedUnit) as UnitPersistBase
		if unitPersist != null:
			unitPersist.UnEquipStartingWeapon()
	else:
		# If we're in run, this is an ability to add to convoy
		var campaign = GameManager.CurrentCampaign
		if campaign == null:
			return

		var unitInstance = campaign.GetUnitFromTemplate(currentSelectedUnit) as UnitInstance
		if unitInstance != null:
			unitInstance.UnEquipWeapon()

	shortInspectPanel.RefreshTemplate(currentSelectedUnit)
	shortInspectPanel.PlayEquipWeapon()
	ExitAbilitySwap()

func OnTacticalUnequipped():
	if currentUIMode == UIMode.OutOfRun:
		var unitPersist = PersistDataManager.universeData.GetUnitPersistence(currentSelectedUnit) as UnitPersistBase
		if unitPersist != null:
			unitPersist.UnEquipStartingTactical()
	else:
		# If we're in run, this is an ability to add to convoy
		var campaign = GameManager.CurrentCampaign
		if campaign == null:
			return

		var unitInstance = campaign.GetUnitFromTemplate(currentSelectedUnit) as UnitInstance
		if unitInstance != null:
			unitInstance.UnEquipTactical()

	shortInspectPanel.RefreshTemplate(currentSelectedUnit)
	shortInspectPanel.PlayEquipTactical()
	ExitAbilitySwap()

func OnItemUnequipped():
	if currentUIMode == UIMode.OutOfRun:
		# being very deliberate here on functionality
		return
	else:
		# If we're in run, this is an ability to add to convoy
		var campaign = GameManager.CurrentCampaign
		if campaign == null:
			return

		var unitInstance = campaign.GetUnitFromTemplate(currentSelectedUnit) as UnitInstance
		if unitInstance != null:
			unitInstance.EquipItem(itemSlotIndex, null)

	shortInspectPanel.RefreshTemplate(currentSelectedUnit)
	ExitAbilitySwap()

func OnWeaponSwapSelected(_entry : NewAbilityEntryUI):
	if currentUIMode == UIMode.OutOfRun:
		var unitPersist = PersistDataManager.universeData.GetUnitPersistence(currentSelectedUnit)
		if unitPersist != null:
			unitPersist.ChangeEquippedStartingWeapon(_entry.unlockable)
	else:
		# If we're in run, this is an ability to add to convoy
		var campaign = GameManager.CurrentCampaign
		if campaign == null:
			return

		var unitInstance = campaign.GetUnitFromTemplate(currentSelectedUnit)
		if unitInstance != null:
			campaign.Convoy.EquipWeaponFromConvoy(unitInstance, _entry.ability)

	shortInspectPanel.RefreshTemplate(currentSelectedUnit)
	shortInspectPanel.PlayEquipWeapon()
	ExitAbilitySwap()

	pass


func OnTacticalSwapSelected(_entry : NewAbilityEntryUI):
	if currentUIMode == UIMode.OutOfRun:
		var unitPersist = PersistDataManager.universeData.GetUnitPersistence(currentSelectedUnit)
		if unitPersist != null:
			unitPersist.ChangeEquippedStartingTactical(_entry.unlockable)

	else:
		var campaign = GameManager.CurrentCampaign
		if campaign == null:
			return

		var unitInstance = campaign.GetUnitFromTemplate(currentSelectedUnit)
		if unitInstance != null:
			campaign.Convoy.EquipTacticalFromConvoy(unitInstance, _entry.ability)

	shortInspectPanel.RefreshTemplate(currentSelectedUnit)
	shortInspectPanel.PlayEquipTactical()
	ExitAbilitySwap()
	pass


func OnItemSwapSelected(_entry : NewAbilityEntryUI):
	if currentUIMode == UIMode.OutOfRun:
		return
	else:
		var campaign = GameManager.CurrentCampaign
		if campaign == null:
			return

		var unitInstance = campaign.GetUnitFromTemplate(currentSelectedUnit)
		if unitInstance != null:
			campaign.Convoy.EquipItemFromConvoy(unitInstance, _entry.ability, itemSlotIndex)

	shortInspectPanel.RefreshTemplate(currentSelectedUnit)
	ExitAbilitySwap()

func EnterInspectSelection():
	shortInspectPanel.EnableFocus(true)
	shortInspectPanel.ReturnFocus()
	gridPanel.EnableFocus(false)
	inspectPanelVignette.visible = true
	animator.play("Inspect")

func ExitInspectSelection():
	shortInspectPanel.EnableFocus(false)
	gridPanel.EnableFocus(true)
	gridPanel.ReturnFocus()
	inspectPanelVignette.visible = false
	animator.play("RESET")
	currentSelectedUnit = null

func EnterSwapCommon():
	animator.play("Swap")
	shortInspectPanel.EnableFocus(false)


func EnterWeaponSwap(_ability : Ability):
	EnterSwapCommon()
	inWeaponSwap = true
	weaponLibrary.visible = true
	tacticalLibrary.visible = false
	heldItemsLibrary.visible = false

	weaponLibrary.Initialize(currentSelectedUnit.WeaponDescriptors, currentUIMode, _ability)
	weaponLibrary.Enable(true)

func EnterTacticalSwap(_ability : Ability):
	EnterSwapCommon()
	inTacticalSwap = true
	weaponLibrary.visible = false
	tacticalLibrary.visible = true
	heldItemsLibrary.visible = false

	tacticalLibrary.Initialize([], currentUIMode,_ability)
	tacticalLibrary.Enable(true)

func EnterItemSwap(_int : int):
	if GameManager.CurrentCampaign == null:
		return

	var unitInstance = GameManager.CurrentCampaign.GetUnitFromTemplate(currentSelectedUnit) as UnitInstance
	if unitInstance == null:
		return

	itemSlotIndex = _int
	EnterSwapCommon()
	inItemSwap = true
	weaponLibrary.visible = false
	tacticalLibrary.visible = false
	heldItemsLibrary.visible = true

	heldItemsLibrary.Initialize([], currentUIMode, unitInstance.ItemSlots[itemSlotIndex])
	heldItemsLibrary.Enable(true)


# Can handle any library exit
func ExitAbilitySwap():
	animator.play("Unswap")
	shortInspectPanel.EnableFocus(true)
	shortInspectPanel.ReturnFocus()
	weaponLibrary.Enable(false)
	tacticalLibrary.Enable(false)
	heldItemsLibrary.Enable(false)
	inWeaponSwap = false
	inTacticalSwap = false
	inItemSwap = false


func StartShowDetails():
	super()
	if inWeaponSwap: weaponLibrary.Enable(false)
	if inTacticalSwap : tacticalLibrary.Enable(false)

func EndShowDetails():
	super()
	if inWeaponSwap: weaponLibrary.Enable(true)
	if inTacticalSwap: tacticalLibrary.Enable(true)

func FocusChanged(_control : Control):
	if currentSelectedUnit == null:
		if _control.get("template") != null:
			var template = _control.get("template")
			if template is UnitTemplate && shortInspectPanel != null:
				if currentUIMode == UIMode.OutOfRun:
					shortInspectPanel.RefreshTemplate(template)
				elif currentUIMode == UIMode.InRun:
					var unitInstance = GameManager.CurrentCampaign.GetUnitFromTemplate(template)
					if unitInstance != null:
						shortInspectPanel.RefreshInstance(unitInstance)

	pass
