extends NewAbilityEntryUI
class_name SmithyWeaponEntryUI


@export var costParent : EntryList
@export var costEntry : PackedScene
@export var canUseParent : EntryList
@export var alreadyUnlockedModulate : Color = Color.WHITE
@export var canAffordColor : Color = Color.WHITE
@export var cantAffordColor : Color = Color.WHITE
@export var lockedParent : Control
@export var lockedText : Control
@export var unlockedParent : Control
@export var contentModulateParent : Control

var createdUnitIcons : Array[TextureRect]
var levelReq : int
var data : SmithyWeaponUnlockDef
var lockedBySmithyLevel : bool
var alreadyUnlocked : bool

func InitWithSmithyWeaponData(_weaponData : SmithyWeaponUnlockDef, _levelReq : int):
	if _weaponData == null || _weaponData.unlockableTemplate == null:
		queue_free()
		return

	var packedScene = load(_weaponData.unlockableTemplate.AbilityPath) as PackedScene
	if packedScene == null:
		queue_free()
		return

	var local = packedScene.instantiate()
	if local is not Ability:
		queue_free()
		return

	ability = local
	levelReq = _levelReq
	data = _weaponData
	Refresh()

func Refresh():
	lockedBySmithyLevel = PersistDataManager.universeData.bastionData.CurrentTavernLevel < levelReq

	lockedParent.visible = lockedBySmithyLevel
	lockedText.text = tr(LocSettings.Level_Num).format({"NUM" = levelReq + 1})

	persistData = PersistDataManager.universeData.GetUnlockablePersist(data.unlockableTemplate)
	alreadyUnlocked = persistData.Unlocked
	if alreadyUnlocked:
		contentModulateParent.modulate = alreadyUnlockedModulate
	else:
		contentModulateParent.modulate = Color.WHITE
	unlockedParent.visible = persistData.Unlocked

	UpdateMetaData()
	AddWeaponRange()
	AddWeaponTargeting()
	AddStatChangeData()


	costParent.ClearEntries()
	for c in data.cost.cost:
		var entry = costParent.CreateEntry(costEntry)
		entry.Initialize(c, canAffordColor, cantAffordColor)
		Details.append(entry.detailEntry)

	# An argument could be made that if you have not unlocked a character that can use a weapon
	# (say the assassin, for daggers) that it shouldn't be included in here at all
	# I'm not at the point where I have to make that decision, but i'm putting this comment here for consideration
	canUseParent.ClearEntries()
	for units in GameManager.UnitSettings.AllyUnitManifest:
		var persist = PersistDataManager.universeData.GetUnitPersistence(units)
		if persist == null:
			continue

		# This should probably be commented in at some point
		#if !persist.Unlocked:
			# return


		var found = false
		for unitWeaponDescriptor in units.WeaponDescriptors:
			for itemDescriptor in data.unlockableTemplate.Descriptors:
				if itemDescriptor == unitWeaponDescriptor:
					var entry = canUseParent.CreateEntry(UIManager.Generic_32x32_Texture)
					entry.texture = units.icon

					found = true
					break

			if found:
				break



	var firstCost = costParent.GetEntry(0)
	if firstCost != null && lastAddedStatChangeEntry != null:
		firstCost.detailEntry.focus_neighbor_left = firstCost.detailEntry.get_path_to(lastAddedStatChangeEntry.detailElement)
		lastAddedStatChangeEntry.detailElement.focus_neighbor_right = lastAddedStatChangeEntry.detailElement.get_path_to(firstCost.detailEntry)

	AddWeaponSecondaryDetails()


func AddWeaponSecondaryDetails():
	weaponDetailsParent.ClearEntries()
	AddWeaponSpeed()

	var lastAdded : Control = null
	var lastStatChange = statChangeEntryParent.GetEntry(statChangeEntryParent.createdEntries.size() - 1)
	if speedEntry != null:
		speedEntry.focus_neighbor_top = speedEntry.get_path_to(nameLabel)
		speedEntry.focus_neighbor_bottom = speedEntry.get_path_to(descLabel)
		lastStatChange.detailElement.focus_neighbor_right = lastStatChange.detailElement.get_path_to(speedEntry)
		lastAdded = speedEntry

	AddWeaponTargeting()

	if targetingTypeEntry != null:
		if speedEntry != null:
			speedEntry.focus_neighbor_right = speedEntry.get_path_to(targetingTypeEntry)
			targetingTypeEntry.focus_neighbor_left = targetingTypeEntry.get_path_to(speedEntry)
		else:
			lastStatChange.detailElement.focus_neighbor_right = lastStatChange.detailElement.get_path_to(targetingTypeEntry)

		targetingTypeEntry.focus_neighbor_top = targetingTypeEntry.get_path_to(nameLabel)
		targetingTypeEntry.focus_neighbor_bottom = targetingTypeEntry.get_path_to(descLabel)
		lastAdded = targetingTypeEntry

	if lastAdded != null:
		var firstCost = costParent.GetEntry(0)
		if firstCost:
			lastAdded.focus_neighbor_right = lastAdded.get_path_to(firstCost.detailEntry)

		var lastStat = statChangeEntryParent.GetEntry(statChangeEntryParent.createdEntries.size() - 1)
		if lastStat != null:
			lastAdded.focus_neighbor_left = lastAdded.get_path_to(lastStat.detailElement)



func _exit_tree() -> void:
	# Gotta do this manually
	if ability != null:
		ability.queue_free()

func NotEnoughResourceFailed():
	if animator != null:
		animator.play("NotEnoughResources")

func AlreadyUnlockedFailed():
	if animator != null:
		animator.play("AlreadyUnlocked")
	pass

func LockedBySmithyLevelFailed():
	if animator != null:
		animator.play("LockedByLevel")
	pass
