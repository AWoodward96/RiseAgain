extends Node2D
class_name VFXHelper

@export var emitOnReady : bool
@export var cpuParticles : Array[CPUParticles2D]
@export var gpuParticles : Array[GPUParticles2D]
@export var sounds : Array[FmodEventEmitter2D]

func _ready():
	if emitOnReady:
		Emit()

func Emit():
	for e in cpuParticles:
		e.emitting = true
	for e in gpuParticles:
		e.emitting = true

	for s in sounds:
		if s != null:
			s.play()
