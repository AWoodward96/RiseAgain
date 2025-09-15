extends Resource
class_name UnitTemplate

@export_group("Unit Info")
@export var VisualPrefab : PackedScene
@export var BaseStats : Array[StatDef]
@export var StatGrowths : Array[StatDef]

@export var Affinity : AffinityTemplate

@export var StartingEquippedWeapon : AbilityUnlockable
@export var StartingTactical : AbilityUnlockable

@export_file("*.tscn") var Tier0Abilities : Array[String]
@export_file("*.tscn") var Tier1Abilities : Array[String]
@export var Descriptors : Array[DescriptorTemplate]
@export var WeaponDescriptors : Array[DescriptorTemplate]
@export var GridSize : int = 1

@export var ResourceDrops : Array[ResourceDef]
#@export var BaseClass : ClassTemplate


@export_group("Audio")
@export var FootstepGUID : String = ""

@export_group("Meta Data")
@export var DebugName : String
@export var loc_DisplayName : String
@export var loc_Description : String
@export var icon : Texture2D
@export var startUnlocked : bool = true
@export var startNameKnown : bool = true
@export var unitMovementPreview : Texture2D
@export var persistDataScript : Script


func GetBaseStat(_statTemplate : StatTemplate):
	for def in BaseStats:
		if def.Template == _statTemplate:
			return def.Value

	return 0
