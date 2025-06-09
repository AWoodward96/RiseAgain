extends Node2D

const NULL_EVENT = "{00000000-0000-0000-0000-000000000000}"
const INTENSITY_CAP : float = 5.0

@export_category("Defaults")
@export var DefaultFootstepGUID : String

@export_category("Actions")
@export var GetItem : String
@export var ItemStolen : String

@export_category("Environment")
@export var AmbiencePlayer : FmodEventEmitter2D
@export var MusicPlayer : FmodEventEmitter2D
@export var CurrentIntensity : float = 0
@export var IntensityLerp : float = 3
@export var IntensityFalloffUp : float = 10
@export var IntensityFalloffDown : float = 5

var localIntensity : float = 0
var localFalloff : float = 0
var currentBiome : BiomeData

# Commenting this out bc I don't think I want this to go down anymore
# May revisit this system at a later date, but for now I'm not sure
#func _ready():
	#MusicPlayer.timeline_marker.connect(MarkerCallback)

func IncrementIntensity():
	if MusicPlayer != null:
		CurrentIntensity += 1
		if CurrentIntensity > INTENSITY_CAP:
			CurrentIntensity = INTENSITY_CAP
		localFalloff = IntensityFalloffUp


func DecrementIntensity():
	if MusicPlayer != null:
		CurrentIntensity -= 1
		if CurrentIntensity < 0:
			CurrentIntensity = 0
		localFalloff = IntensityFalloffDown

func ResetIntensityTimer():
	localFalloff = IntensityFalloffUp

func RaiseIntensity(_int : int):
	if CurrentIntensity < _int:
		CurrentIntensity = _int
	localFalloff = IntensityFalloffUp

func _process(delta: float):
	if currentBiome == null:
		return

	if MusicPlayer != null:
		localIntensity = lerp(localIntensity, CurrentIntensity, IntensityLerp * delta)
		MusicPlayer.set_parameter("Intensity", localIntensity)

	if localFalloff > 0:
		localFalloff -= delta


func UpdateBiomeData(_biomeData : BiomeData):
	currentBiome = _biomeData
	if _biomeData == null:
		return

	if _biomeData.AmbienceID != "{00000000-0000-0000-0000-000000000000}":
		if AmbiencePlayer.event_guid != _biomeData.AmbienceID:
			AmbiencePlayer.event_guid = _biomeData.AmbienceID
			AudioManager.AmbiencePlayer.play()
	else:
		AudioManager.AmbiencePlayer.stop()

	if _biomeData.MusicID != "{00000000-0000-0000-0000-000000000000}":
		if MusicPlayer.event_guid != _biomeData.MusicID:
			MusicPlayer.event_guid = _biomeData.MusicID
			MusicPlayer.play()
	else:
		MusicPlayer.stop()


#func MarkerCallback(_dict : Dictionary):
	#print("Marker Hit")
#
	#if localFalloff <= 0:
		#DecrementIntensity()
	#pass
