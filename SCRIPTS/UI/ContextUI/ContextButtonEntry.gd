extends Control
class_name ContextButtonEntry

signal OnSelectedCallback

@export var action_label : Label
@export var bg_color_fill : ColorRect
@export var disabled_parent : Control
@export var focus_parent : Control
@export var default_color : Color
@export var weapon_color : Color
@export var ability_color : Color
@export var tactical_color : Color

@export var fast_speed_parent : Control
@export var cooldown_parent : Control
@export var cooldown_label : Label
@export var usage_parent : Control
@export var usage_label : Label

@export_category("SFX")
@export var OnFocus : FmodEventEmitter2D
@export var OnSelect : FmodEventEmitter2D
@export var OnSelectDeny : FmodEventEmitter2D

var callback : Callable
var enabled : bool
var focused : bool

func Initialize(_locTitle : String, _enabled : bool, _callback : Callable):
	action_label.text = _locTitle
	callback = _callback
	enabled = _enabled
	disabled_parent.visible = !_enabled
	bg_color_fill.color = default_color

	# default to false on these
	usage_parent.visible = false
	cooldown_parent.visible = false
	fast_speed_parent.visible = false

func AddAbility(_ability : Ability):
	match (_ability.type):
		Ability.EAbilityType.Standard:
			bg_color_fill.color = ability_color
		Ability.EAbilityType.Tactical:
			bg_color_fill.color = tactical_color
		Ability.EAbilityType.Weapon:
			bg_color_fill.color = weapon_color

	AddCooldown(_ability.abilityCooldown, _ability.remainingCooldown)

	if _ability.limitedUsage != -1:
		AddUsage(_ability.remainingUsages)

	fast_speed_parent.visible = _ability.ability_speed == Ability.EAbilitySpeed.Fast

func AddCooldown(_cooldown : int, _remainingCooldown : int):
	cooldown_parent.visible = _cooldown > 0

	if _remainingCooldown > 0:
		cooldown_label.text = str(_remainingCooldown)
	else:
		cooldown_label.text = str(_cooldown)



func AddUsage(_usagesRemaining : int):
	usage_parent.visible = true
	usage_label.text = str(_usagesRemaining)

func _process(_delta: float) -> void:
	if InputManager.selectDown && focus_parent.visible == true:
		if enabled:
			if callback != null:
				if OnSelect != null:
					OnSelect.play()
				callback.call()
				OnSelectedCallback.emit()
		else:
			if OnSelectDeny != null:
				OnSelectDeny.play()

func OnFocusEnter():
	focus_parent.visible = true
	focused = true
	if OnFocus != null:
		OnFocus.play()

func OnFocusExit():
	focus_parent.visible = false
	focused = false
