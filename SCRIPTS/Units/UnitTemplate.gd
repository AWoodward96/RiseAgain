extends Resource
class_name UnitTemplate

@export_group("Unit Info")
@export var VisualPrefab : PackedScene
@export var BaseStats : Array[StatDef]
@export var StatGrowths : Array[StatDef]

@export var Affinity : AffinityTemplate

@export var StartingEquippedWeapon : PackedScene
@export var StartingTactical : PackedScene

@export_file("*.tscn") var Tier0Abilities : Array[String]
@export_file("*.tscn") var Tier1Abilities : Array[String]
@export var Descriptors : Array[DescriptorTemplate]
@export var GridSize : int = 1
#@export var BaseClass : ClassTemplate

@export_group("Palettes")
@export var DefaultPalette : Texture2D
@export var AllyPalette : PaletteSwapData
@export var EnemyPalette : PaletteSwapData
@export var NeutralPalette : PaletteSwapData

@export_group("Audio")
@export var FootstepGUID : String = "{00000000-0000-0000-0000-000000000000}"

@export_group("Meta Data")
@export var DebugName : String
@export var loc_DisplayName : String
@export var loc_Description : String
@export var icon : Texture2D
@export var persistDataScript : Script


func GetBaseStat(_statTemplate : StatTemplate):
	for def in BaseStats:
		if def.Template == _statTemplate:
			return def.Value

	return 0
