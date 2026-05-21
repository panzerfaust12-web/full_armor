extends Node

@onready var sounds: Array[AudioStreamPlayer]
@onready var sound_names: Array[String]

func _ready() -> void:
	for sound in find_children("*"):
		if sound is AudioStreamPlayer:
			sounds.append(sound)
			sound_names.append(sound.name)

func play_sound(sound_name:String):
	var request = sound_names.find(sound_name)
	if request == -1:
		print("ERROR: Sound name "+sound_name+" not found!")
	if request != -1:
		sounds[request].play()
