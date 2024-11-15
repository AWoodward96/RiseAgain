extends Node2D
class_name DamageIndicator

enum DisplayStyle { Weapon, Ability}

@onready var death_indicator = $DeathIndicator
@onready var hit_chance_label = $VBoxContainer/HitChance
@onready var crit_chance_label = $CritChance
@onready var delta_hp_label = $VBoxContainer/DamageBeingDealt
@onready var hp_listener = $HPListener
@onready var animation_player: AnimationPlayer = $AnimationPlayer


var ShouldShow : bool :
	get:
		return !(normalDamage == 0 && collisionDamage == 0 && healAmount == 0)

var display_style : DisplayStyle
var currentHP : int # Units current HP
var maxHealth : int
var previewedHP # The hp value visible to the player. Gets ticked down over the course of the preview
var resultingHP # The hp value that this unit will have if the ability hits. PreviewedHP ticks down to this value
var previewHPTween : Tween

var normalDamage : int
var collisionDamage : int
var healAmount : int
var hitChance : float
var critChance : float


func ShowPreview(_defendingUnit : UnitInstance, _currentHealth : int = -1, _maxHealth : int = -1):
	if _defendingUnit != null:
		currentHP = _defendingUnit.currentHealth
		maxHealth = _defendingUnit.maxHealth
	else:
		currentHP = _currentHealth
		maxHealth = _maxHealth

	if animation_player != null:
		match(display_style):
			DisplayStyle.Weapon:
				animation_player.play("Weapon")
			DisplayStyle.Ability:
				animation_player.play("Ability")

	# Weapons can miss
	# Abilities cannot
	if display_style == DisplayStyle.Weapon && hit_chance_label != null:
		hit_chance_label.text = str(clamp(hitChance, 0, 1) * 100) + "%"

	# Abilities can crit too however - so get that in there
	if crit_chance_label != null:
		crit_chance_label.text = str(clamp(critChance, 0, 1) * 100) + "%"

	if delta_hp_label != null:
		delta_hp_label.text = GameManager.LocalizationSettings.FormatForCombat(normalDamage, collisionDamage, healAmount)

	hp_listener.text = str("%02d/%02d" % [currentHP, maxHealth])
	resultingHP = clamp(currentHP + normalDamage - collisionDamage, 0, maxHealth)

	death_indicator.visible = resultingHP <= 0

	CreateTween()

func SetDisplayStyle(_ability : Ability):
	match(_ability.type):
		Ability.AbilityType.Weapon:
			display_style = DisplayStyle.Weapon
		_:
			display_style = DisplayStyle.Ability


func PreviewDamage(_unitUsable : UnitUsable, _attackingUnit : UnitInstance, _targetedTileData : TileTargetedData, _defendingUnit : UnitInstance, _currentHealth : int = -1, _maxHealth : int = -1):
	#if _defendingUnit != null:
		#currentHP = _defendingUnit.currentHealth
		#maxHealth = _defendingUnit.maxHealth
	#else:
		#currentHP = _currentHealth
		#maxHealth = _maxHealth
##
	#var damageDealt = 0
	#var collisionDamage = 0
	##for result in cachedActionResults:
		##if result.Target == _defendingUnit:
			##damageDealt += result.HealthDelta
##
		##if result.TileTargetData.pushCollision != null:
			### We check the collision damage here because the target of the action may not be where we actually are - but we're still affected by pushing
			##for push in result.TileTargetData.pushStack:
				##if push.Subject == _defendingUnit && result.TileTargetData.
#
#
	#if hit_chance_label != null:
		#hit_chance_label.text = str(clamp(GameManager.GameSettings.HitRateCalculation(_attackingUnit, _unitUsable, _defendingUnit, _targetedTileData), 0, 1) * 100) + "%"
#
	#if crit_chance_label != null:
		#crit_chance_label.text = str(clamp(GameManager.GameSettings.CritRateCalculation(_attackingUnit, _unitUsable, _defendingUnit, _targetedTileData), 0, 1) * 100) + "%"
#
	#delta_hp_label.text = GameManager.LocalizationSettings.FormatAsDamage(damageDealt, -collisionDamage)
	#hp_listener.text = str("%02d/%02d" % [currentHP, maxHealth])
	#resultingHP = clamp(currentHP + damageDealt - collisionDamage, 0, maxHealth)
#
	#death_indicator.visible = resultingHP <= 0
#
	#CreateTween()
	pass


func PreviewHeal(_unitUsable : UnitUsable, _sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _targetedTileData: TileTargetedData):
	# Currently I'm assuming you cannot 'Heal' tiles. So this only works with Units
	var healData = _unitUsable.HealData

	currentHP = _affectedUnit.currentHealth
	maxHealth = _affectedUnit.maxHealth
	death_indicator.visible = false

	var healAmount = GameManager.GameSettings.HealCalculation(healData, _sourceUnit, _targetedTileData.AOEMultiplier)

	hp_listener.text = str("%02d/%02d" % [currentHP, maxHealth])
	delta_hp_label.text = GameManager.LocalizationSettings.FormatAsHeal(healAmount)
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

	normalDamage = 0
	collisionDamage = 0
	hitChance = 0
	critChance = 0
