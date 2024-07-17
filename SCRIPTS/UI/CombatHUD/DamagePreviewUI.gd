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

	var aggressiveStat = damageDataFromWeapon.AgressiveStat
	var defensiveStat = damageDataFromWeapon.DefensiveStat
	if aggressiveStat == null || defensiveStat == null:
		push_error("Attempting to show preview damage for weapon that does not define its agressive or defensive stats. This is a bug.")
		return

	# Do all the complicated calculations
	var agressiveVal = _attackingUnit.GetWorkingStat(aggressiveStat)
	var defenssiveVal = _defendingUnit.GetWorkingStat(defensiveStat)

	agressiveVal = damageDataFromWeapon.DoMod(agressiveVal, damageDataFromWeapon.AgressiveMod, damageDataFromWeapon.AgressiveModType)
	defenssiveVal = damageDataFromWeapon.DoMod(defenssiveVal, damageDataFromWeapon.DefensiveMod, damageDataFromWeapon.DefensiveModType)

	var finalAttackingDamage = GameManager.GameSettings.DamageCalculation(agressiveVal, defenssiveVal) * _targetData.AOEMultiplier
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
	if _defendingUnit.IsDefending:
		pass
	else:
		def_dmg.text = "--"
		def_hit.text = "--"
		def_crit.text = "--"
