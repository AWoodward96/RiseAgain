extends UnitActionBase
class_name UnitAcquireLootAction

var loot : Item
var waitingForUI : bool = false

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)
	waitingForUI = true

	# Show the notification ui
	var notificationUI = UIManager.FullscreenNotifUI.instantiate() as FullscreenNotificationUI
	Map.Current.add_child(notificationUI)

	notificationUI.OnTimeout.connect(OnNotificationUIClear)
	notificationUI.AddAutoTimeout(3)

	if _unit.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
		# This loc reads "Got __" so format it with text first then stuff later
		notificationUI.AddTranlatedText(GameManager.LocalizationSettings.gotItemConcat)
		notificationUI.AddIcon(loot.icon, Vector2(32, 32))
		notificationUI.AddTranlatedText(loot.loc_displayName)
		notificationUI.AddSoundEffect(AudioManager.GetItem)
	else:
		# This loc reads "__ was stolen" so format it with the item first then the text after
		notificationUI.AddIcon(loot.icon, Vector2(32, 32))
		notificationUI.AddTranlatedText(loot.loc_displayName)
		notificationUI.AddTranlatedText(GameManager.LocalizationSettings.stoleItemConcat)
		notificationUI.AddSoundEffect(AudioManager.ItemStolen)

	if !unit.TryEquipItem(loot):
		map.TryAddItemToConvoy(loot)
		notificationUI.AddTranlatedText(GameManager.LocalizationSettings.butSentToConvoyConcat)

func _Execute(_unit : UnitInstance, _delta):
	if waitingForUI:
		return false

	return true

func OnNotificationUIClear():
	waitingForUI = false
