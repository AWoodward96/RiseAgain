extends Control
class_name DamagePreviewUI

@onready var attacker_name: Label = %AttackerName
@onready var attacker_affinity_icon: TextureRect = %AttackerAffinityIcon
@onready var attacker_advantage: TextureRect = %Attacker_Advantage
@onready var attacker_disadvantage: TextureRect = %Attacker_Disadvantage

@onready var atk_health: Label = %AtkHealth
@onready var atk_dmg: Label = %AtkDmg
@onready var atk_hit: Label = %AtkHit
@onready var atk_crit: Label = %AtkCrit

@onready var defender_name: Label = %DefenderName
@onready var defender_affinity_icon: TextureRect = %DefenderAffinityIcon
@onready var defender_advantage: TextureRect = %Defender_Advantage
@onready var defender_disadvantage: TextureRect = %Defender_Disadvantage

@onready var def_health: Label = %DefHealth
@onready var def_dmg: Label = %DefDmg
@onready var def_hit: Label = %DefHit
@onready var def_crit: Label = %DefCrit

func ShowPreviewDamage(_attackingUnit : UnitInstance, _weaponUsed : UnitUsable, _defendingUnit : UnitInstance, _targetData : TileTargetedData):
	var damageDataFromWeapon = _weaponUsed.UsableDamageData
	if damageDataFromWeapon == null:
		push_error("Attempting to show preview damage for weapon with no damage information on it. This is a bug.")
		return

	# Do all the complicated calculations
	var finalAttackingDamage = GameManager.GameSettings.DamageCalculation(_attackingUnit, _defendingUnit, damageDataFromWeapon, _targetData)
	var hitRateVal = GameManager.GameSettings.HitRateCalculation(_attackingUnit, _weaponUsed, _defendingUnit, _targetData)

	# update the UI information
	attacker_name.text = _attackingUnit.Template.loc_DisplayName
	attacker_affinity_icon.texture = _attackingUnit.Template.Affinity.loc_icon


	atk_health.text = "%d" % _attackingUnit.currentHealth
	atk_dmg.text =  "%d" % finalAttackingDamage
	atk_hit.text =  "%d" % (hitRateVal * 100)

	# TODO: Crit chance calc and implementation
	atk_crit.text = "0"

	defender_name.text = _defendingUnit.Template.loc_DisplayName
	defender_affinity_icon.texture = _defendingUnit.Template.Affinity.loc_icon

	def_health.text =  "%d" % _defendingUnit.currentHealth

	var range = Vector2i.ZERO
	if _defendingUnit.EquippedWeapon != null:
		range = _defendingUnit.EquippedWeapon.GetRange()

	var combatDistance = _defendingUnit.map.grid.GetManhattanDistance(_attackingUnit.GridPosition, _defendingUnit.GridPosition)
	# so basically, if the weapon this unit is holding, has a max range
	if range.x <= combatDistance && range.y >= combatDistance && _defendingUnit.EquippedWeapon != null && _defendingUnit.EquippedWeapon.IsDamage():
		# NOTE: The AOE multiplier here.... should kinda never apply? This UI should only be used to show one on one combat
		# I will need a more robust system to show actual aoe damage previews - but for now showing it directly on the unit is how I'm doing that
		# The _targetDatta variable is passed through here as a formailty, but if it ever is not = 1 than this entire function will
		# need to be rewritten to support it
		finalAttackingDamage = GameManager.GameSettings.DamageCalculation(_defendingUnit, _attackingUnit, _defendingUnit.EquippedWeapon.UsableDamageData, _targetData)
		hitRateVal = GameManager.GameSettings.HitRateCalculation(_defendingUnit, _defendingUnit.EquippedWeapon, _attackingUnit, _targetData)

		def_dmg.text = "%d" % finalAttackingDamage
		def_hit.text = "%d" % (hitRateVal * 100)
		def_crit.text = "0"

	else:
		def_dmg.text = "--"
		def_hit.text = "--"
		def_crit.text = "--"

	attacker_advantage.visible = false
	defender_advantage.visible = false
	attacker_disadvantage.visible = false
	defender_disadvantage.visible = false
	if _attackingUnit.Template != null && _defendingUnit.Template != null && _attackingUnit.Template.Affinity != null && _defendingUnit.Template.Affinity != null:
		var attackAffinity = _attackingUnit.Template.Affinity
		var defendAffinity = _defendingUnit.Template.Affinity

		if defendAffinity.affinity & attackAffinity.strongAgainst:
			defender_disadvantage.visible = true
			attacker_advantage.visible = true

		if attackAffinity.affinity & defendAffinity.strongAgainst:
			defender_advantage.visible = true
			attacker_disadvantage.visible = true


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
