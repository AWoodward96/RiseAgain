extends Resource
class_name BiomeData


@export var AmbienceID : String = "{00000000-0000-0000-0000-000000000000}"
@export var MusicID : String = "{00000000-0000-0000-0000-000000000000}"
@export var VictoryStinger : String = "{00000000-0000-0000-0000-000000000000}"
@export var LossStinger : String = "{00000000-0000-0000-0000-000000000000}"
@export var VictoryDelay : float = 0
@export var GridColor : Color = Color.BLACK

@export_category("Unit Data")
@export var UnitHue : float = 1
@export var UnitSaturation : float = 1
@export var UnitValue : float = 1
@export var GrayscaleUnitOffset : float = 0

@export_category("Environmental Effects")
@export var DirectionalLight : PackedScene
@export var UnitLight : PackedScene
@export var ReticleLight : PackedScene
@export var Particles : PackedScene

@export_category("Audio Data")
@export var AmbienceNoise : FastNoiseLite
@export var AmbienceSpeed : float = 5
