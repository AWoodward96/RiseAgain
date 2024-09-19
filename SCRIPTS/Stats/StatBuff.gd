extends Node2D
class_name StatBuff

# This represents a change in stat value created by a StatChangeEffect
# This should be parented to whatever created it - in this case it's the StatChangeEffectInstance
# This only exists as a Node2D so you can actually see the value that's been changed

@export var Stat : StatTemplate
@export var Value : int

func Evaluate(_source : UnitInstance, _target : UnitInstance):
	pass
