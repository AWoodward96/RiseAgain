extends Node2D

@onready var death_indicator = $DeathIndicator
@onready var damage_being_dealt = $DamageBeingDealt
@onready var hp_listener = $HPListener
@onready var hide_timer = $HideTimer


var currentHP	# Units current HP
var previewedHP # The hp value visible to the player. Gets ticked down over the course of the preview
var resultingHP # The hp value that this unit will have if the ability hits. PreviewedHP ticks down to this value
var damageBeingDealt : int
var myUnit : UnitInstance
var maxHealth

var previewHPTween : Tween

func Initialize(_unit : UnitInstance):
	myUnit = _unit

func PreviewDamage(_unitUsable : UnitUsable, _attackingUnit : UnitInstance, _targetedTileData : TileTargetedData):
	var damageContext = _unitUsable.UsableDamageData

	currentHP = myUnit.currentHealth
	maxHealth = myUnit.maxHealth

	damageBeingDealt = 0
	if _unitUsable is Ability:
		var asAbility = _unitUsable as Ability
		for step in asAbility.executionStack:
			var asDamageStep = step as DealDamageStep
			if asDamageStep != null:
				damageBeingDealt += asDamageStep.GetDamageBeingDealt(_unitUsable, _attackingUnit, myUnit, _targetedTileData)
	else:
		damageBeingDealt = -GameManager.GameSettings.UnitDamageCalculation(_attackingUnit, myUnit, damageContext, _targetedTileData.AOEMultiplier)


	damage_being_dealt.text = str(damageBeingDealt)
	hp_listener.text = str("%02d/%02d" % [currentHP, maxHealth])
	resultingHP = clamp(myUnit.currentHealth + damageBeingDealt, 0, myUnit.maxHealth)

	death_indicator.visible = resultingHP <= 0

	CreateTween()
	pass

func PreviewHeal(_unitUsable : UnitUsable, _sourceUnit : UnitInstance, _targetedTileData: TileTargetedData):
	var healData = _unitUsable.HealData

	currentHP = myUnit.currentHealth
	maxHealth = myUnit.maxHealth
	death_indicator.visible = false

	var healAmount = GameManager.GameSettings.UnitHealCalculation(healData, _sourceUnit, _targetedTileData.AOEMultiplier)

	damage_being_dealt.text = str(healAmount)
	resultingHP = clamp(myUnit.currentHealth + healAmount, 0, myUnit.maxHealth)
	CreateTween()
	pass

func CreateTween():
	previewHPTween = get_tree().create_tween()
	previewHPTween.tween_method(UpdatePreviewLabel, currentHP, resultingHP, Juice.damagePreviewTickDuration).set_delay(Juice.damagePreviewDelayTime)

func UpdatePreviewLabel(value : int):
	hp_listener.text = str("%02d/%02d" % [max(value, 0), maxHealth])

func PreviewCanceled():
	if previewHPTween != null:
		previewHPTween.stop()
