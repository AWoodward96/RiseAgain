extends Resource
class_name UnitSettingsTemplate


enum MovementAnimationStyle { Normal, Jump, Teleport }

static var ANIM_IDLE = "idle"
static var ANIM_SELECTED = "selected"
static var ANIM_MOVE_DOWN = "run_down"
static var ANIM_MOVE_UP = "run_up"
static var ANIM_MOVE_LEFT = "run_left"
static var ANIM_MOVE_RIGHT = "run_right"
static var ANIM_PREP_UP = "prep_up"
static var ANIM_PREP_RIGHT = "prep_right"
static var ANIM_PREP_DOWN = "prep_down"
static var ANIM_PREP_LEFT = "prep_left"
static var ANIM_ATTACK_DOWN = "attack_down"
static var ANIM_ATTACK_RIGHT = "attack_right"
static var ANIM_ATTACK_UP = "attack_up"
static var ANIM_ATTACK_LEFT = "attack_left"
static var ANIM_TAKE_DAMAGE = "take_damage"
static var ANIM_JUMP_FRONT_UP = "jump_front_up"
static var ANIM_JUMP_FRONT_DOWN = "jump_front_down"
static var ANIM_JUMP_BACK_UP = "jump_back_up"
static var ANIM_JUMP_BACK_DOWN = "jump_back_down"

@export var UnitInstancePrefab : PackedScene
@export var AllyUnitManifest : Array[UnitTemplate]

@export var BaseUnitPrestiegeCost : int = 100
@export var AdditionalUnitPrestiegeCost : int = 10
@export var PrestiegeGrantedPerMap : int = 10



func GetPrestiegeBreakpoint(_currentLevel : int):
	return BaseUnitPrestiegeCost + (_currentLevel * AdditionalUnitPrestiegeCost)

func ValidateUnitTemplates():
	for template in AllyUnitManifest:
		if template.StartingEquippedWeapon != null:
			var weaponPath = template.StartingEquippedWeapon.resource_path
			if weaponPath.contains("PackedScene_"):
				push_error("PACKED SCENE ERROR: UNIT '" + template.DebugName + "' HAS AN INVALID STARTING WEAPON")

		if template.StartingTactical != null:
			var tacticalPath = template.StartingTactical.resource_path
			if tacticalPath.contains("PackedScene_"):
				push_error("PACKED SCENE ERROR: UNIT '" + template.DebugName + "' HAS AN INVALID STARTING TACTICAL")

	pass

static func GetMovementAnimationFromVector(_movement : Vector2):
	var angle = rad_to_deg(_movement.angle())
	if angle < 0:
		angle += 360

	if angle > 315 || angle < 45:
		return ANIM_MOVE_RIGHT
	elif angle > 45 && angle < 135:
		return ANIM_MOVE_DOWN
	elif angle > 135 && angle < 215:
		return ANIM_MOVE_LEFT
	elif angle > 215 && angle < 315:
		return ANIM_MOVE_UP
	return ANIM_IDLE
