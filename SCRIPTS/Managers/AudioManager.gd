extends Node2D

const NULL_EVENT = "{00000000-0000-0000-0000-000000000000}"

@export_category("Defaults")
@export var DefaultFootstepGUID : String

@export_category("Environment")
@export var AmbiencePlayer : FmodEventEmitter2D
@export var MusicPlayer : FmodEventEmitter2D
@export var CurrentIntensity : float = 0
@export var IntensityLerp : float = 3
@export var IntensityFalloffUp : float = 10
@export var IntensityFalloffDown : float = 5

var localIntensity : float = 0
var localFalloff : float = 0

func _ready():
	MusicPlayer.timeline_marker.connect(MarkerCallback)

func IncrementIntensity():
	if MusicPlayer != null:
		CurrentIntensity += 1
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
	if MusicPlayer != null:
		localIntensity = lerp(localIntensity, CurrentIntensity, IntensityLerp * delta)
		MusicPlayer.set_parameter("Intensity", localIntensity)
	
	if localFalloff > 0:
		localFalloff -= delta
	
		
func MarkerCallback(_dict : Dictionary):
	print("Marker Hit")
	
	if localFalloff <= 0:
		DecrementIntensity()
	pass
