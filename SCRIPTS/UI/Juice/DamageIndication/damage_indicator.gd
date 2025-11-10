extends Node2D
class_name DamageIndicator


@export var effectEntry : PackedScene
@export var healthbar : UnitHealthBar

@export var crit_chance_label = Label
@export var affinityIcon: TextureRect
@export var positive_affinity: TextureRect
@export var negative_affinity: TextureRect

@export var death_indicator : Control
@export var effects_preview : EntryList


var ShouldShow : bool :
	get:
		return !(normalDamage == 0 && collisionDamage == 0 && healAmount == 0) || normalDamageModified || effects.size() > 0

var currentHP : int :
	get():
		if assignedUnit != null:
			return assignedUnit.currentHealth
		elif assignedTile != null:
			return assignedTile.Health
		else:
			return 0

var maxHealth : int :
	get():
		if assignedUnit != null:
			return assignedUnit.maxHealth
		elif assignedTile != null:
			return assignedTile.MaxHealth
		else:
			return 0

var previewedHP # The hp value visible to the player. Gets ticked down over the course of the preview
var resultingHP # The hp value that this unit will have if the ability hits. PreviewedHP ticks down to this value
var previewHPTween : Tween
var submerged : bool
var assignedUnit : UnitInstance
var assignedTile : Tile

var normalDamage : int :
	set(val):
		normalDamageModified = true
		normalDamage = val
var normalDamageModified : bool = false
var collisionDamage : int
var healAmount : int
var critChance : float

var effects : Array[CombatEffectTemplate]
var healthBarTweenCallable : Callable

func AssignOwner(_TileOrUnit):
	HidePreview()
	healthbar.HealthBarTweenCallback.connect(HealthbarTweenComplete)
	if _TileOrUnit is UnitInstance:
		assignedUnit = _TileOrUnit as UnitInstance
		healthbar.SetUnit(_TileOrUnit)
		affinityIcon.visible = true
		affinityIcon.texture = assignedUnit.Template.Affinity.loc_icon
	elif _TileOrUnit is Tile:
		assignedTile = _TileOrUnit
		affinityIcon.visible = false
		healthbar.SetTile(assignedTile)

func ShowPreview():
	if !ShouldShow:
		return

	healthbar.visible = true

	# Abilities can crit too however - so get that in there
	if crit_chance_label != null:
		crit_chance_label.text = str(clamp(critChance, 0, 1) * 100) + "%"

	if !submerged:
		resultingHP = clamp(currentHP + normalDamage + collisionDamage + healAmount, 0, maxHealth)

		death_indicator.visible = resultingHP <= 0
	else:
		death_indicator.visible = false

	for template in effects:
		var entry = effects_preview.CreateEntry(effectEntry)
		entry.texture.texture = template.loc_icon
		entry.label.text = template.loc_name

	if !submerged:
		ShowHealthBar(true)
		healthbar.RefreshIncomingDamageBar()
		healthbar.ModifyHealthOverTime(normalDamage + collisionDamage + healAmount)

func ShowAffinityRelations(_affinity : AffinityTemplate):
	if _affinity == null || assignedUnit == null:
		positive_affinity.visible = false
		negative_affinity.visible = false
		return

	# Chat, I love bitwise ops
	if _affinity.strongAgainst & assignedUnit.Template.Affinity.affinity:
		negative_affinity.visible = true

	if assignedUnit.Template.Affinity.strongAgainst & _affinity.affinity:
		positive_affinity.visible = true
	pass

func AddEffect(_effectTemplate : CombatEffectTemplate):
	effects.append(_effectTemplate)

func SetSubmerged(_bool : bool):
	submerged = _bool
	affinityIcon.visible = !_bool

func ShowHealthBar(_visible : bool):
	healthbar.visible = _visible
	if _visible:
		healthbar.Refresh()

func ShowCombatResult(_netHealthChange, _complete : Callable):
	ShowHealthBar(true)
	death_indicator.visible = false
	crit_chance_label.visible = false
	healthbar.ModifyHealthOverTime(_netHealthChange)
	healthBarTweenCallable = _complete

func HealthbarTweenComplete():
	if !healthBarTweenCallable.is_null():
		healthBarTweenCallable.call()

	# this is setting it to null - seeing as it can't be assigned null
	healthBarTweenCallable = Callable()
	pass

func DeathState():
	visible = false

func HideCombatClutter():
	affinityIcon.visible = false
	death_indicator.visible = false
	crit_chance_label.visible = false
	pass

func HidePreview():
	healthbar.visible = false
	PreviewCanceled()

func PreviewCanceled():
	healthbar.visible = false
	if previewHPTween != null:
		previewHPTween.stop()

	normalDamage = 0
	healAmount = 0
	collisionDamage = 0
	critChance = 0
	normalDamageModified = false

	if effects_preview != null:
		effects_preview.ClearEntries()
	effects.clear()
