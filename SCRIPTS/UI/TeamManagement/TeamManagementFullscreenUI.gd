extends FullscreenUI
class_name TeamManagementUI

enum UIMode { OutOfRun, InRun }
@export var animator : AnimationPlayer
@export var shortInspectPanel : ShortInspectPanel
@export var inspectPanelVignette : Control
@export var gridPanel : TeamGridPanel
@export var weaponLibrary : EquippableLibrary
@export var tacticalLibrary : EquippableLibrary

var currentSelectedUnit : UnitTemplate
var swapAbility : Ability
var inWeaponSwap : bool = false
var inTacticalSwap : bool = false
var currentUIMode : TeamManagementUI.UIMode

# well, if you cancel out of an inspect there will be one frame
# where inspectstate will be false, but cancelDown is also true, so use
# this variable to block backing out of the UI when canceling an inspectstate
var blockone : bool = false

func _ready():
	super()
	currentUIMode = TeamManagementUI.UIMode.OutOfRun
	if GameManager.CurrentCampaign != null:
		currentUIMode = TeamManagementUI.UIMode.InRun
	UIManager.FocusChanged.connect(FocusChanged)
	gridPanel.OnUnitSelected.connect(OnUnitSelected)
	weaponLibrary.OnEquippableSelected.connect(OnWeaponSwapSelected)
	tacticalLibrary.OnEquippableSelected.connect(OnTacticalSwapSelected)
	shortInspectPanel.WeaponSelectedForSwap.connect(OnWeaponSelected)
	shortInspectPanel.TacticalSelectedForSwap.connect(OnTacticalSelected)
	shortInspectPanel.EnableFocus(false)
	pass

func _process(_delta):
	if !visible || UIManager.HighestLevelUI != self:
		return

	if IsInDetailState:
		return
	elif blockone:
		blockone = false
		return

	if InputManager.cancelDown:
		if currentSelectedUnit != null:
			if !inWeaponSwap && !inTacticalSwap:
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

func OnWeaponSwapSelected(_abilityULK : AbilityUnlockable):
	var unitPersist = PersistDataManager.universeData.GetUnitPersistence(currentSelectedUnit)
	if unitPersist != null:
		unitPersist.ChangeEquippedStartingWeapon(_abilityULK)
	shortInspectPanel.RefreshTemplate(currentSelectedUnit)
	shortInspectPanel.PlayEquipWeapon()
	ExitAbilitySwap()

	pass

func OnTacticalSwapSelected(_abilityULK : AbilityUnlockable):
	var unitPersist = PersistDataManager.universeData.GetUnitPersistence(currentSelectedUnit)
	if unitPersist != null:
		unitPersist.ChangeEquippedStartingTactical(_abilityULK)
	shortInspectPanel.RefreshTemplate(currentSelectedUnit)
	shortInspectPanel.PlayEquipTactical()
	ExitAbilitySwap()

	pass

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

func EnterWeaponSwap(_ability : Ability):
	animator.play("Swap")
	shortInspectPanel.EnableFocus(false)
	inWeaponSwap = true
	weaponLibrary.visible = true
	tacticalLibrary.visible = false

	weaponLibrary.Initialize(currentSelectedUnit.WeaponDescriptors, currentUIMode, _ability)
	weaponLibrary.Enable(true)

func EnterTacticalSwap(_ability : Ability):
	animator.play("Swap")
	shortInspectPanel.EnableFocus(false)
	inTacticalSwap = true
	weaponLibrary.visible = false
	tacticalLibrary.visible = true

	tacticalLibrary.Initialize([], currentUIMode,_ability)
	tacticalLibrary.Enable(true)

# Can handle both weapon and tactical swap
func ExitAbilitySwap():
	animator.play("Unswap")
	shortInspectPanel.EnableFocus(true)
	shortInspectPanel.ReturnFocus()
	weaponLibrary.Enable(false)
	tacticalLibrary.Enable(false)
	inWeaponSwap = false
	inTacticalSwap = false


func StartShowDetails():
	super()
	if inWeaponSwap: weaponLibrary.Enable(false)
	if inTacticalSwap : tacticalLibrary.Enable(false)

func EndShowDetails():
	super()
	if inWeaponSwap: weaponLibrary.Enable(true)
	if inTacticalSwap: tacticalLibrary.Enable(true)
	blockone = true

func FocusChanged(_control : Control):
	if currentSelectedUnit == null:
		if _control.get("template") != null:
			var template = _control.get("template")
			if template is UnitTemplate && shortInspectPanel != null:
				shortInspectPanel.RefreshTemplate(template)
	pass
