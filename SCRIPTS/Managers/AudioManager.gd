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
var ambienceDT : float

var musicFadeOutTween : Tween
var ambienceFadeOutTween : Tween



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

	# MusicPlayer is an FModEventEmitter2D that loads and unloads different FMod Events
	# depending on the game state
	if MusicPlayer != null:
		localIntensity = lerp(localIntensity, CurrentIntensity, IntensityLerp * delta)

		# The below code never triggers unless Intensity is set before this happens.
		# but if a track doesn't have an Intensity parameter, the console gets flooded.
		# I could program around this by not having this in process, but I'd rather just
		#   have the flexibility of checking if a parameter exists first
		MusicPlayer.set_parameter("Intensity", localIntensity)

	if localFalloff > 0:
		localFalloff -= delta

	if currentBiome.AmbienceNoise != null:
		ambienceDT += delta * currentBiome.AmbienceSpeed
		var ambienceRandom = currentBiome.AmbienceNoise.get_noise_1d(ambienceDT)
		AmbiencePlayer.volume = 1 + ambienceRandom


func UpdateBiomeData(_biomeData : BiomeData):
	currentBiome = _biomeData
	if _biomeData == null:
		return

	ambienceDT = 0

	if _biomeData.AmbienceID != "{00000000-0000-0000-0000-000000000000}":
		if AmbiencePlayer.event_guid != _biomeData.AmbienceID:
			AmbiencePlayer.event_guid = _biomeData.AmbienceID
			AmbiencePlayer.volume = 1
			AudioManager.AmbiencePlayer.play()
	else:
		FadeOutAmbience()

	if _biomeData.MusicID != "{00000000-0000-0000-0000-000000000000}":
		if MusicPlayer.event_guid != _biomeData.MusicID:
			if musicFadeOutTween != null:
				musicFadeOutTween.stop()
				musicFadeOutTween = null

			MusicPlayer.volume = 1
			MusicPlayer.event_guid = _biomeData.MusicID
			MusicPlayer.play()
	else:
		FadeOutMusic()


func PlayVictoryStinger():
	if currentBiome == null:
		return

	if currentBiome.VictoryStinger !=  "{00000000-0000-0000-0000-000000000000}":
		MusicPlayer.event_guid = currentBiome.VictoryStinger
		MusicPlayer.play()
		CurrentIntensity = 0

func PlayLossStinger():
	if currentBiome == null:
		return

	if currentBiome.LossStinger !=  "{00000000-0000-0000-0000-000000000000}":
		MusicPlayer.event_guid = currentBiome.LossStinger
		MusicPlayer.play()
		CurrentIntensity = 0

func ClearTracks(_fadeOut : bool = true):
	if !_fadeOut:
		MusicPlayer.stop()
		AmbiencePlayer.stop()
	else:
		FadeOutMusic()
		FadeOutAmbience()

func FadeOutMusic(_duration : float = 2):
	if MusicPlayer == null:
		return

	musicFadeOutTween = create_tween()
	musicFadeOutTween.tween_property(MusicPlayer, "volume", 0, _duration)

func FadeOutAmbience(_duration : float = 2):
	if AmbiencePlayer != null:
		return

	ambienceFadeOutTween = create_tween()
	ambienceFadeOutTween.tween_property(AmbiencePlayer, "volume", 0, _duration)
	pass

#func MarkerCallback(_dict : Dictionary):
	#print("Marker Hit")
#
	#if localFalloff <= 0:
		#DecrementIntensity()
	#pass
