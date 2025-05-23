extends Node2D
class_name VFXHelper

@export var emitOnReady : Array[CPUParticles2D]

func _ready():
	for e in emitOnReady:
		e.emitting = true
