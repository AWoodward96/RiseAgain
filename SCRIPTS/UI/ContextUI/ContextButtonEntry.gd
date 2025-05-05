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
@export var focus_cost_parent : Control
@export var focus_cost_label : Label
@export var usage_parent : Control
@export var usage_label : Label

@export_category("SFX")
@export var OnFocus : FmodEventEmitter2D
@export var OnSelect : FmodEventEmitter2D

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
	focus_cost_parent.visible = false
	fast_speed_parent.visible = false

func AddAbility(_ability : Ability):
	match (_ability.type):
		Ability.AbilityType.Standard:
			bg_color_fill.color = ability_color
		Ability.AbilityType.Tactical:
			bg_color_fill.color = tactical_color
		Ability.AbilityType.Weapon:
			bg_color_fill.color = weapon_color

	AddCost(_ability.focusCost)
	# Gotta do this manually
	if _ability.isXFocusCost:
		focus_cost_label.text = "X"
		focus_cost_parent.visible = true

	if _ability.limitedUsage != -1:
		AddUsage(_ability.remainingUsages)

	fast_speed_parent.visible = _ability.ability_speed == Ability.AbilitySpeed.Fast

func AddCost(_focusCost : int):
	focus_cost_parent.visible = _focusCost > 0
	focus_cost_label.text = str(_focusCost)

func AddUsage(_usagesRemaining : int):
	usage_parent.visible = true
	usage_label.text = str(_usagesRemaining)

func _process(_delta: float) -> void:
	if InputManager.selectDown && enabled && focus_parent.visible == true:
		if callback != null:
			if OnSelect != null:
				OnSelect.play()
			callback.call()
			OnSelectedCallback.emit()

func OnFocusEnter():
	focus_parent.visible = true
	focused = true
	if OnFocus != null:
		OnFocus.play()

func OnFocusExit():
	focus_parent.visible = false
	focused = false
