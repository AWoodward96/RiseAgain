extends Node2D


@export var damagePopup : PackedScene
@export var damagePreview : PackedScene
@export var effectPopup : PackedScene
@export var abilityPopup : PackedScene
@export var critPopup : PackedScene

@export_category("Emotes")
@export var AlertEmote : PackedScene
@export var ShockEmote : PackedScene

@export_category("Camera Settings")
@export var cameraMoveSpeed = 10

@export_category("Health Bar Settings")
@export var HealthBarLossTime : float = 0.5

@export_category("Combat Settings")
@export var combatSequenceWarmupTimer = 0.5
@export var combatSequenceTimeBetweenAttackAndDefense = 0.2
@export var combatSequenceCooloffTimer = 0.1
@export var combatSequenceAttackOffset : float = 0.5
@export var combatSequenceDefenseOffset : float = 1
@export var combatSequenceReturnToOriginLerp = 4
@export var combatSequenceResetDistance = 0.1
@export var combatPopupCooldown : float = 0.5

@export var enemyTurnWarmup = 0.5

@export_category("Screen Shake Settings")
@export var SimpleCombatShakeStrength = 4
@export var SimpleCombatShakeDuration = 0.33
@export var CritCombatShakeStrength = 8
@export var CritCombatShakeDuration = 0.55

@export_category("Damage Preview Settings")
@export var damagePreviewDelayTime = 0.5
@export var damagePreviewTickDuration = 0.5


@export_category("Common VFX")
@export var SplashVFX : PackedScene


func CreateHealPopup(_healVal, _tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetHealValue(_healVal)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)

func CreateDamagePopup(_damageVal, _tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetDamageValue(_damageVal)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)

func CreateArmorPopup(_armorVal, _tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetArmorValue(_armorVal)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)

func CreateMissPopup(_tile : Tile):
	var popup = damagePopup.instantiate()
	popup.SetMiss()
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)
	pass

func CreateEffectPopup(_tile : Tile, _effectInstance : CombatEffectInstance):
	var popup = effectPopup.instantiate()
	popup.SetEffect(_effectInstance)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)
	pass

func CreateAbilityPopup(_tile : Tile, _ability : Ability):
	var popup = abilityPopup.instantiate()
	popup.SetAbility(_ability)
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)
	pass

func CreateCritPopup(_tile : Tile):
	var popup = critPopup.instantiate()
	popup.global_position = _tile.GlobalPosition
	add_child(popup)
	_tile.QueuePopup(popup)
	pass

func CreateDamageIndicator(_tile : Tile):
	var indicator = damagePreview.instantiate()
	indicator.global_position = _tile.GlobalPosition
	add_child(indicator)
	return indicator

func PlayShortRumble():
	Input.start_joy_vibration(0, 0.1, 0.25, 0.1)

func PlayHitRumble():
	Input.start_joy_vibration(0, 0.3, 0.6, 0.25)

func CreateAlertEmote(_unit : UnitInstance):
	var popup = AlertEmote.instantiate()
	popup.global_position = _unit.global_position
	add_child(popup)
	pass

func CreateShockEmote(_unit : UnitInstance):
	var popup = ShockEmote.instantiate()
	popup.global_position = _unit.global_position
	add_child(popup)
	pass

func ScreenShakeCombatStandard():
	if Map.Current != null:
		Map.Current.playercontroller.StartScreenShake(SimpleCombatShakeStrength, SimpleCombatShakeDuration)

func ScreenShakeCombatCrit():
	if Map.Current != null:
		Map.Current.playercontroller.StartScreenShake(CritCombatShakeStrength, CritCombatShakeDuration)
