extends Control
class_name TavernCharacterEntry

@export var characterIcon : TextureRect
@export var characterName : Label
@export var characterStatus : Label
@export var characterRoom : Label
@export var characterInParty : CheckBox
@export var selectedParent : Control

@export_category("Localization")
@export var inCampsiteLoc : String = "ui_unit_in_campsite"
@export var inTavernLoc : String = "ui_unit_in_tavern"

var template : UnitTemplate
var inParty : bool
var unitIsInCampsite : bool
var parent : Tavern

func Initialize(_unitTemplate : UnitTemplate, _tavern : Tavern):
	template = _unitTemplate
	parent = _tavern

	Refresh()

	pass

func _process(_delta: float) -> void:
	if InputManager.selectDown && selectedParent.visible:
		if inParty:
			PersistDataManager.universeData.bastionData.TryRemoveUnitFromRoster(template)
		else:
			PersistDataManager.universeData.bastionData.TryAddUnitToRoster(template)
		parent.RefreshLoadout()
		Refresh()

func Refresh():
	unitIsInCampsite = PersistDataManager.universeData.bastionData.UnitsInCampsite.has(template)
	inParty = PersistDataManager.universeData.bastionData.SelectedRoster.has(template)

	if characterIcon != null: characterIcon.texture = template.icon
	if characterName != null: characterName.text = template.loc_DisplayName

	if characterRoom != null:
		if unitIsInCampsite:
			characterRoom.text = tr(inCampsiteLoc)
		else:
			var roomIndex = PersistDataManager.universeData.bastionData.UnitsInTavern.find(template)
			var roomNum = PersistDataManager.universeData.bastionData.TavernRoomNumbers[roomIndex]
			characterRoom.text = tr(inTavernLoc).format({"NUM" : roomNum})

	if characterInParty != null: characterInParty.button_pressed = inParty

func _on_focus_entered() -> void:
	selectedParent.visible = true
	pass # Replace with function body.


func _on_focus_exited() -> void:
	selectedParent.visible = false
	pass # Replace with function body.
