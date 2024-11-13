extends Resource
class_name AITargetingFlag


@export_flags("ALLY", "ENEMY", "NEUTRAL") var Team : int = 1
@export var SpecificUnit : UnitTemplate
@export var Descriptor : DescriptorTemplate
