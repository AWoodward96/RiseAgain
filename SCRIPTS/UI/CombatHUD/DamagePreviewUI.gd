extends Control
class_name DamagePreviewUI

@onready var attacker_weapon_icon: TextureRect = %AttackerWeaponIcon
@onready var attacker_name: Label = %AttackerName

@onready var atk_health: Label = %AtkHealth
@onready var atk_dmg: Label = %AtkDmg
@onready var atk_hit: Label = %AtkHit
@onready var atk_crit: Label = %AtkCrit

@onready var defender_name: Label = %DefenderName
@onready var defender_weapon_icon: TextureRect = %DefenderWeaponIcon

@onready var def_health: Label = %DefHealth
@onready var def_dmg: Label = %DefDmg
@onready var def_hit: Label = %DefHit
@onready var def_crit: Label = %DefCrit

func ShowPreviewDamage(_attackingUnit : UnitInstance, _weaponUsed : Item, _defendingUnit : UnitInstance, _targetData : TileTargetedData):
	var damageDataFromWeapon = _weaponUsed.UsableDamageData
	if damageDataFromWeapon == null:
		push_error("Attempting to show preview damage for weapon with no damage information on it. This is a bug.")
		return

	# Do all the complicated calculations
	var finalAttackingDamage = GameManager.GameSettings.UnitDamageCalculation(_attackingUnit, _defendingUnit, damageDataFromWeapon, _targetData.AOEMultiplier)
	var hitRateVal = GameManager.GameSettings.HitRateCalculation(_attackingUnit, _weaponUsed, _defendingUnit)

	# update the UI information
	attacker_name.text = _attackingUnit.Template.loc_DisplayName
	attacker_weapon_icon.texture = _weaponUsed.icon

	atk_health.text = "%d" % _attackingUnit.currentHealth
	atk_dmg.text =  "%d" % finalAttackingDamage
	atk_hit.text =  "%d" % (hitRateVal * 100)

	# TODO: Crit chance calc and implementation
	atk_crit.text = "0"

	defender_name.text = _defendingUnit.Template.loc_DisplayName
	defender_weapon_icon.visible = _defendingUnit.EquippedItem != null
	if _defendingUnit.EquippedItem != null:
		defender_weapon_icon.texture = _defendingUnit.EquippedItem.icon

	def_health.text =  "%d" % _defendingUnit.currentHealth


	var range = _defendingUnit.EquippedItem.GetRange()
	var combatDistance = _defendingUnit.map.grid.GetManhattanDistance(_attackingUnit.GridPosition, _defendingUnit.GridPosition)
	# so basically, if the weapon this unit is holding, has a max range
	if range.x <= combatDistance && range.y >= combatDistance && _defendingUnit.EquippedItem != null && _defendingUnit.EquippedItem.IsDamage():
		# NOTE: The AOE multiplier here.... should kinda never apply? This UI should only be used to show one on one combat
		# I will need a more robust system to show actual aoe damage previews - but for now showing it directly on the unit is how I'm doing that
		# The _targetDatta variable is passed through here as a formailty, but if it ever is not = 1 than this entire function will
		# need to be rewritten to support it
		finalAttackingDamage = GameManager.GameSettings.UnitDamageCalculation(_defendingUnit, _attackingUnit, _defendingUnit.EquippedItem.UsableDamageData)
		hitRateVal = GameManager.GameSettings.HitRateCalculation(_defendingUnit, _defendingUnit.EquippedItem, _attackingUnit)

		def_dmg.text = "%d" % finalAttackingDamage
		def_hit.text = "%d" % (hitRateVal * 100)
		def_crit.text = "0"

	else:
		def_dmg.text = "--"
		def_hit.text = "--"
		def_crit.text = "--"

func GetAggressiveValFromItem(_item : Item, _attackingUnit : UnitInstance):
	if _item == null || _item.UsableDamageData == null:
		return -1

	var damageDataFromWeapon = _item.UsableDamageData
	var aggressiveStat = damageDataFromWeapon.AgressiveStat
	var agressiveVal = _attackingUnit.GetWorkingStat(aggressiveStat)
	agressiveVal = damageDataFromWeapon.DoMod(agressiveVal,damageDataFromWeapon.AgressiveMod, damageDataFromWeapon.AgressiveModType)
	return agressiveVal

func GetDefensiveValFromItem(_itemBeingAttackedWith : Item, _defendingUnit : UnitInstance):
	if _itemBeingAttackedWith == null || _itemBeingAttackedWith.UsableDamageData == null:
		return -1

	var damageDataFromWeapon = _itemBeingAttackedWith.UsableDamageData
	var defensiveStat = damageDataFromWeapon.DefensiveStat
	var defensiveVal = _defendingUnit.GetWorkingStat(defensiveStat)
	defensiveVal = damageDataFromWeapon.DoMod(defensiveVal, damageDataFromWeapon.DefensiveMod, damageDataFromWeapon.DefensiveModType)
	return defensiveVal
