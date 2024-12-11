extends Node2D
class_name DamageIndicator

enum DisplayStyle { Weapon, Ability}

@export var effectEntry : PackedScene

@onready var death_indicator = $DeathIndicator
@onready var hit_chance_label = $VBoxContainer/HitChance
@onready var crit_chance_label = $CritChance
@onready var delta_hp_label = $VBoxContainer/DamageBeingDealt
@onready var hp_listener = $HPListener
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effects_preview : EntryList = $EffectsPreview


var ShouldShow : bool :
	get:
		return !(normalDamage == 0 && collisionDamage == 0 && healAmount == 0) || normalDamageModified

var display_style : DisplayStyle
var currentHP : int # Units current HP
var maxHealth : int
var previewedHP # The hp value visible to the player. Gets ticked down over the course of the preview
var resultingHP # The hp value that this unit will have if the ability hits. PreviewedHP ticks down to this value
var previewHPTween : Tween

var normalDamage : int :
	set(val):
		normalDamageModified = true
		normalDamage = val
var normalDamageModified : bool = false
var collisionDamage : int
var healAmount : int
var hitChance : float
var critChance : float

var effects : Array[CombatEffectTemplate]

func ShowPreview():
	if !ShouldShow:
		return

	visible = true
	if animation_player != null:
		match(display_style):
			DisplayStyle.Weapon:
				animation_player.play("Weapon")
			DisplayStyle.Ability:
				animation_player.play("Ability")

		# This animation is advanced manually. This makes it so that there isn't a frame where it's incorrect
		animation_player.advance(0.1)

	# Weapons can miss
	# Abilities cannot
	if display_style == DisplayStyle.Weapon && hit_chance_label != null:
		hit_chance_label.text = str(clamp(hitChance, 0, 1) * 100) + "%"

	# Abilities can crit too however - so get that in there
	if crit_chance_label != null:
		crit_chance_label.text = str(clamp(critChance, 0, 1) * 100) + "%"

	if delta_hp_label != null:
		delta_hp_label.text = GameManager.LocalizationSettings.FormatForCombat(normalDamage, collisionDamage, healAmount, normalDamageModified)

	hp_listener.text = str("%02d/%02d" % [currentHP, maxHealth])
	resultingHP = clamp(currentHP + normalDamage + collisionDamage + healAmount, 0, maxHealth)

	death_indicator.visible = resultingHP <= 0

	for template in effects:
		var entry = effects_preview.CreateEntry(effectEntry)
		entry.texture.texture = template.loc_icon
		entry.label.text = template.loc_name

	CreateTween()

func AddEffect(_effectTemplate : CombatEffectTemplate):
	effects.append(_effectTemplate)


func SetDisplayStyle(_ability : Ability):
	match(_ability.type):
		Ability.AbilityType.Weapon:
			display_style = DisplayStyle.Weapon
		_:
			display_style = DisplayStyle.Ability

func SetHealthLevels(_currentHealth : int, _maxHealth : int):
	currentHP = _currentHealth
	maxHealth = _maxHealth

func CreateTween():
	previewHPTween = get_tree().create_tween()
	previewHPTween.tween_method(UpdatePreviewLabel, currentHP, resultingHP, Juice.damagePreviewTickDuration).set_delay(Juice.damagePreviewDelayTime)

func UpdatePreviewLabel(value : int):
	hp_listener.text = str("%02d/%02d" % [max(value, 0), maxHealth])

func PreviewCanceled():
	visible = false
	if previewHPTween != null:
		previewHPTween.stop()

	normalDamage = 0
	healAmount = 0
	collisionDamage = 0
	hitChance = 0
	critChance = 0
	normalDamageModified = false

	if effects_preview != null:
		effects_preview.ClearEntries()
	effects.clear()
