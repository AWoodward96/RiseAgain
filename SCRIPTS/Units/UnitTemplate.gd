extends Resource
class_name UnitTemplate

@export_group("Unit Info")
@export var VisualPrefab : PackedScene
@export var BaseStats : Array[StatDef]
@export var StatGrowths : Array[StatDef]

@export var StartingItems : Array[PackedScene]
@export var Abilities : Array[PackedScene]
@export var Descriptors : Array[DescriptorTemplate]
#@export var BaseClass : ClassTemplate

@export_group("Meta Data")
@export var DebugName : String
@export var loc_DisplayName : String
@export var loc_Description : String
@export var icon : Texture2D
