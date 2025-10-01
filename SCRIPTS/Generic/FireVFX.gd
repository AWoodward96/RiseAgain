extends Node2D
class_name FireVFX

@export var particles : CPUParticles2D
@export var animatedSprite : AnimatedSprite2D

var myUnit : UnitInstance
var myFireDebuff : OnFireEffectInstance

func AttachToUnit(_unitInstance : UnitInstance):
	myUnit = _unitInstance

	for effect in myUnit.CombatEffects:
		if effect is OnFireEffectInstance:
			myFireDebuff = effect
			break

	if myFireDebuff == null:
		queue_free()
	else:
		myUnit.visual.add_child(self)
		myUnit.OnCombatEffectsUpdated.connect(Refresh)
		Refresh()

func Refresh():
	if myFireDebuff != null:
		match myFireDebuff.Stacks:
			1:
				if animatedSprite.animation != "level_1":
					animatedSprite.play("level_1")
				particles.amount = 8
				pass
			2:
				if animatedSprite.animation != "level_2":
					animatedSprite.play("level_2")

				particles.amount = 16
				pass
			3:
				if animatedSprite.animation != "level_3":
					animatedSprite.play("level_3")

				particles.amount = 32
				pass
