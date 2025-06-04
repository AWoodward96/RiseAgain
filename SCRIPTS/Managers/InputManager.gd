extends Node2D

signal selectDownCallback
enum ControllerScheme { Keyboard, Controller }
static var CurrentInputSchmeme : ControllerScheme = ControllerScheme.Keyboard

@export var inputHeldThreshold = 0.5
@export var inputHeldMoveTick = 0.06


var inputDown : Array[bool] = [false, false, false, false]
var inputHeld : Array[bool] = [false, false, false, false]

var topdownVertical : float
var topdownHorizontal: float

var inputAnyDown : bool
var inputAnyHeld : bool
var inputHeldTimer : float

var selectDown : bool
var selectHeld : bool

var cancelDown : bool
var cancelHeld : bool

var startDown : bool
var startHeld : bool

var infoDown : bool
var infoHeld : bool


func _process(_delta):
	UpdateInputArrays(_delta)
	UpdateSelectAndCancel(_delta)
	UpdateStart(_delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		CurrentInputSchmeme = ControllerScheme.Keyboard
	elif event is InputEventJoypadButton or InputEventJoypadMotion:
		CurrentInputSchmeme = ControllerScheme.Controller


func UpdateInputArrays(_delta):
	inputAnyDown = false
	inputAnyHeld = false
	inputDown = [false, false, false, false]
	inputHeld = [false, false, false, false]


	if Input.is_action_pressed("up") : inputHeld[0] = true
	if Input.is_action_pressed("right") : inputHeld[1] = true
	if Input.is_action_pressed("down") : inputHeld[2] = true
	if Input.is_action_pressed("left") : inputHeld[3] = true
	if Input.is_action_just_pressed("up"): inputDown[0] = true
	if Input.is_action_just_pressed("right"): inputDown[1] = true
	if Input.is_action_just_pressed("down"): inputDown[2] = true
	if Input.is_action_just_pressed("left"): inputDown[3] = true

	topdownHorizontal =  Input.get_action_strength("right") - Input.get_action_strength("left")
	topdownVertical = Input.get_action_strength("down") - Input.get_action_strength("up")

	inputAnyDown = inputDown.any(func(v) : return v)
	inputAnyHeld = inputHeld.any(func(v) : return v)

	if inputAnyHeld :
		inputHeldTimer += _delta
	else:
		inputHeldTimer = 0

func UpdateSelectAndCancel(_delta):
	selectHeld = Input.is_action_pressed("select")
	selectDown = Input.is_action_just_pressed("select")

	if selectDown:
		selectDownCallback.emit()

	cancelHeld = Input.is_action_pressed("cancel")
	cancelDown = Input.is_action_just_pressed("cancel")

func UpdateStart(_delta):
	startHeld = Input.is_action_pressed("start")
	startDown = Input.is_action_just_pressed("start")

	infoHeld = Input.is_action_pressed("info")
	infoDown = Input.is_action_just_pressed("info")
