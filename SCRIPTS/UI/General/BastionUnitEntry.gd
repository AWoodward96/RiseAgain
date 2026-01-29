extends UnitEntryUI
class_name BastionUnitEntry

@export_category("Status Data")
@export var useStatusData : bool = false
@export var statusText : Label
@export var requiredUnitColor : Color
@export var inRosterColor : Color

var inCampsite : bool
var inTavern : bool



func Initialize(_unitTemplate : UnitTemplate):
	super(_unitTemplate)

	var showcaseMode = GameManager.GameSettings.ShowcaseMode
	var persistData = PersistDataManager.universeData.GetUnitPersistence(_unitTemplate)
	if persistData == null || (persistData != null && !persistData.Unlocked):
		# Shade the entire sprite black to show that we haven't unlocked this unit yet
		# We also should probably, like, rename the entry so that it says unknown but I'll get to that in a sec
		if createdVisual != null && !showcaseMode:
			createdVisual.visual.material.set_shader_parameter("use_color_override", true)
			createdVisual.visual.material.set_shader_parameter("color_override", Color.BLACK)

		var format = {
			"STATUS" = tr(LocSettings.Status_Unknown),
			"LOCATION" = tr(LocSettings.Status_Unknown)
		}
		statusText.text = tr("ui_unit_bastion_status").format(format)

		if !showcaseMode:
			if button != null: button.disabled = true

	else:
		inCampsite = PersistDataManager.universeData.bastionData.UnitsInCampsite.has(_unitTemplate)
		inTavern = PersistDataManager.universeData.bastionData.UnitsInTavern.has(_unitTemplate)

		# if we're not in showcase mode, set the visual to greyscale to indicate usage
		if !showcaseMode:
			if !inCampsite && !inTavern && createdVisual != null:
				createdVisual.SetActivated(false)

		var format = {}
		if inTavern:
			format["LOCATION"] = tr(LocSettings.Location_Tavern)
		elif inCampsite:
			format["LOCATION"] = tr(LocSettings.Location_Campsite)
		else:
			format["LOCATION"] = tr(LocSettings.Status_Unknown)

		if persistData.Injured:
			format["STATUS"] = tr(LocSettings.Status_Injured)
		else:
			format["STATUS"] = tr(LocSettings.Status_Healthy)


		if button != null:
			if showcaseMode:
				button.disabled = false
			else:
				button.disabled = !(inCampsite || inTavern)

		statusText.text = tr("ui_unit_bastion_status").format(format)
		pass


	pass

func SetRequired(_bool : bool):
	if _bool:
		nameLabel.label_settings.font_color = requiredUnitColor
	else:
		nameLabel.label_settings.font_color = Color.WHITE

func SetInRoster(_bool : bool):
	if _bool:
		modulate = inRosterColor
	else:
		modulate = Color.WHITE
