extends Node2D
class_name DamageIndicator

@onready var death_indicator = $DeathIndicator
@onready var damage_being_dealt = $DamageBeingDealt
@onready var hp_listener = $HPListener

var currentHP : int # Units current HP
var maxHealth : int
var previewedHP # The hp value visible to the player. Gets ticked down over the course of the preview
var resultingHP # The hp value that this unit will have if the ability hits. PreviewedHP ticks down to this value
var damageBeingDealt : int

var previewHPTween : Tween

func PreviewDamage(_unitUsable : UnitUsable, _attackingUnit : UnitInstance, _targetedTileData : TileTargetedData, _defendingUnit : UnitInstance, _currentHealth : int = -1, _maxHealth : int = -1):
	var damageContext = _unitUsable.UsableDamageData

	if _defendingUnit != null:
		currentHP = _defendingUnit.currentHealth
		maxHealth = _defendingUnit.maxHealth
	else:
		currentHP = _currentHealth
		maxHealth = _maxHealth

	damageBeingDealt = 0
	if _unitUsable is Ability:
		var asAbility = _unitUsable as Ability
		for step in asAbility.executionStack:
			var asDamageStep = step as DealDamageStep
			if asDamageStep != null:
				damageBeingDealt += asDamageStep.GetDamageBeingDealt(_unitUsable, _attackingUnit, _defendingUnit, _targetedTileData)
	else:
		damageBeingDealt = -GameManager.GameSettings.DamageCalculation(_attackingUnit, _defendingUnit, damageContext, _targetedTileData.AOEMultiplier)


	damage_being_dealt.text = str(damageBeingDealt)
	hp_listener.text = str("%02d/%02d" % [currentHP, maxHealth])
	resultingHP = clamp(currentHP + damageBeingDealt, 0, maxHealth)

	death_indicator.visible = resultingHP <= 0

	CreateTween()
	pass

func PreviewHeal(_unitUsable : UnitUsable, _sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _targetedTileData: TileTargetedData):
	# Currently I'm assuming you cannot 'Heal' tiles. So this only works with Units
	var healData = _unitUsable.HealData

	currentHP = _affectedUnit.currentHealth
	maxHealth = _affectedUnit.maxHealth
	death_indicator.visible = false

	var healAmount = GameManager.GameSettings.HealCalculation(healData, _sourceUnit, _targetedTileData.AOEMultiplier)

	damage_being_dealt.text = str(healAmount)
	resultingHP = clamp(_affectedUnit.currentHealth + healAmount, 0, _affectedUnit.maxHealth)
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
