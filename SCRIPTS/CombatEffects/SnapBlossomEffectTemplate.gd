extends CombatEffectTemplate
class_name SnapBlossomEffectTemplate


@export var armorAmount : int = 4
@export var scalingStat : StatTemplate
@export var scalingMod : float = 1

@export var vfx : PackedScene
@export var explosionShape : TargetingShapeBase
@export var teamTargeting : SkillTargetingData.TargetingTeamFlag


func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance,  _abilitySource : Ability, _actionLog : ActionLog):
	var newEffect = SnapBlossomEffectInstance.new()
	# Stacks are handled when created in UnitInstance.Ignite
	newEffect.AffectedUnit = _affectedUnit
	newEffect.SourceUnit = _sourceUnit
	newEffect.AbilitySource = _abilitySource
	newEffect.Template = self
	newEffect.TurnsRemaining = Turns
	newEffect.ArmorValue = armorAmount + (_sourceUnit.GetWorkingStat(scalingStat) * scalingMod)
	return newEffect
