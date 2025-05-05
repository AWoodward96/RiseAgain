extends Resource
class_name BiomeData
  

@export var AmbienceID : String = "{00000000-0000-0000-0000-000000000000}"
@export var MusicID : String = "{00000000-0000-0000-0000-000000000000}"


func UpdateBiomeAudio():
	if AmbienceID != "{00000000-0000-0000-0000-000000000000}":
		if AudioManager.AmbiencePlayer.event_guid != AmbienceID:
			AudioManager.AmbiencePlayer.event_guid = AmbienceID
			AudioManager.AmbiencePlayer.play()
	else:
		AudioManager.AmbiencePlayer.stop()
		
	if MusicID != "{00000000-0000-0000-0000-000000000000}":
		if AudioManager.MusicPlayer.event_guid != MusicID:
			AudioManager.MusicPlayer.event_guid = MusicID
			AudioManager.MusicPlayer.play()	
	else:
		AudioManager.MusicPlayer.stop()
