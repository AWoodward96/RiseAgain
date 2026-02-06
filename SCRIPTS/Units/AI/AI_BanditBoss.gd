extends AISmartTarget
class_name AIBanditBoss

enum EBanditBossState { Leap, Smash, BombThrow, Explode }

@export var LeapAbilityRef : String
@export var SlamAbilityRef : String
@export var BombAbilityRef : String
@export var ExplodeAbilityRef : String
@export var MaximumBombTargets : int = 3

var HasUsedExplode = false
var BombsOnCooldown = false
var ReadyToSmash = false
var WaitingOnThrow = false
var ThrowCount = 0

var state : EBanditBossState = EBanditBossState.Leap
var leapAbility : Ability
var slamAbility : Ability
var throwBombAbility : Ability
var explodeAbility : Ability

var leapOptions : Array[EnemyAIOption]
var bombOptions : Array[EnemyAIOption]
var selectedLeapTarget : EnemyAIOption

func StartTurn(_map : Map, _unit : UnitInstance):
	CommonStartTurn(_map, _unit)
	GetReferences()
	leapOptions.clear()
	bombOptions.clear()
	selectedLeapTarget = null
	WaitingOnThrow = false
	ThrowCount = 0

	if leapAbility != null && leapAbility.remainingCooldown <= 0:
		state = EBanditBossState.Leap
		Decision_UseLeap()
	elif throwBombAbility != null && !BombsOnCooldown:
		Decision_UseBombs()
	elif explodeAbility != null:
		BombsOnCooldown = false
		Decision_Explode()
	else:
		# Leaving this behavior in just in case the flow chart breaks
		super(_map, _unit)


# Not the prettiest way to do this every turn but
func GetReferences():
	for ability in unit.Abilities:
		if ability.internalName == LeapAbilityRef:
			leapAbility = ability

		if ability.internalName == SlamAbilityRef:
			slamAbility = ability

		if ability.internalName == BombAbilityRef:
			throwBombAbility = ability

		if ability.internalName == ExplodeAbilityRef:
			explodeAbility = ability


func Decision_UseLeap():
	var filteredUnitsOnTeam = map.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY)
	filteredUnitsOnTeam = filteredUnitsOnTeam.filter(func(x : UnitInstance) : return !x.Stealthed)

	for u in filteredUnitsOnTeam:
		var newOption = leapAbility.customAITargetingBehavior.Construct(unit, u, map, leapAbility) as EnemyAIOption
		newOption.totalFlags = Flags.size()
		newOption.Update()

		if newOption.valid:
			newOption.UpdateWeight()
			leapOptions.append(newOption)

	if leapOptions.size() == 0:
		unit.QueueEndTurn()
		return

	leapOptions.sort_custom(SortOptions)

	# And what we're doing is.... the first option.
	# Because we sorted the best option to the top
	selectedLeapTarget = leapOptions[0]

	unit.MoveCharacterToNode(MovementData.Construct(selectedLeapTarget.path, selectedLeapTarget.tileToMoveTo))
	pass

func Decision_UseBombs():
	BombsOnCooldown = true
	var filteredUnitsOnTeam = map.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY)
	filteredUnitsOnTeam = filteredUnitsOnTeam.filter(func(x : UnitInstance) : return !x.Stealthed)

	for u in filteredUnitsOnTeam:
		var newOption = EnemyAIOption.Construct(unit, u, map, throwBombAbility) as EnemyAIOption
		newOption.totalFlags = Flags.size()
		newOption.Update()

		if newOption.valid:
			newOption.UpdateWeight()
			bombOptions.append(newOption)

	unit.Visual.PlayAnimation("pull_bomb", false)

	bombOptions.sort_custom(SortOptions)

	state = EBanditBossState.BombThrow

	if !throwBombAbility.AbilityActionComplete.is_connected(ThrowComplete):
		throwBombAbility.AbilityActionComplete.connect(ThrowComplete)

func Decision_Explode():
	state = EBanditBossState.Explode
	var newOption = EnemyAIOption.Construct(unit, unit, map, explodeAbility) as EnemyAIOption
	newOption.totalFlags = Flags.size()
	newOption.Update()

	selectedOption = newOption
	TryCombat()

func RunTurn():
	if unit.IsStackFree:
		match state:
			EBanditBossState.Leap:
				selectedOption = selectedLeapTarget
				state = EBanditBossState.Smash
				TryCombat()
				leapAbility.AbilityActionComplete.connect(LeapComplete)
				pass
			EBanditBossState.Smash:
				if ReadyToSmash:
					ReadyToSmash = false

					var newOption = EnemyAIOption.Construct(unit, selectedLeapTarget.targetUnit, map, slamAbility) as EnemyAIOption
					newOption.totalFlags = Flags.size()
					newOption.Update()
					selectedOption = newOption
					TryCombat()
				pass
			EBanditBossState.BombThrow:
				if !WaitingOnThrow:
					WaitingOnThrow = true
					if bombOptions.size() <= ThrowCount || ThrowCount > MaximumBombTargets:
						unit.QueueEndTurn()
						return

					selectedOption = bombOptions[ThrowCount]
					TryCombat()
				pass
			EBanditBossState.Explode:
				pass

func LeapComplete():
	if leapAbility != null && leapAbility.AbilityActionComplete.is_connected(LeapComplete):
		leapAbility.AbilityActionComplete.disconnect(LeapComplete)
	ReadyToSmash = true
	pass

func ThrowComplete():
	WaitingOnThrow = false
	ThrowCount += 1
	pass
