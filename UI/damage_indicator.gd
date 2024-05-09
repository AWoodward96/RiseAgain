extends Node2D

@onready var death_indicator = $DeathIndicator
@onready var damage_being_dealt = $DamageBeingDealt
@onready var hp_listener = $HPListener
@onready var hide_timer = $HideTimer


var currentHP	# Units current HP
var previewedHP # The hp value visible to the player. Gets ticked down over the course of the preview
var resultingHP # The hp value that this unit will have if the ability hits. PreviewedHP ticks down to this value
var damageBeingDealt
var myUnit : UnitInstance
var maxHealth

var previewHPTween : Tween

func Initialize(_unit : UnitInstance):
	myUnit = _unit

func PreviewDamage(_damageContext : SkillDamageData, _sourceUnit : UnitInstance, ):
	currentHP = myUnit.currentHealth
	maxHealth = myUnit.maxHealth

	damageBeingDealt = myUnit.CalculateDamage(_damageContext, _sourceUnit)
	damage_being_dealt.text = str(damageBeingDealt)
	hp_listener.text = str("%02d/%02d" % [currentHP, maxHealth])
	resultingHP = myUnit.currentHealth - damageBeingDealt

	death_indicator.visible = resultingHP <= 0

	previewHPTween = get_tree().create_tween()
	previewHPTween.tween_method(UpdatePreviewLabel, currentHP, resultingHP, Juice.damagePreviewTickDuration).set_delay(Juice.damagePreviewDelayTime)

	pass

func UpdatePreviewLabel(value : int):
	hp_listener.text = str("%02d/%02d" % [max(value, 0), maxHealth])

func PreviewCanceled():
	if previewHPTween != null:
		previewHPTween.stop()

