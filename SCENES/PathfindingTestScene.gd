extends Node2D

@export var Tilemap : TileMapLayer
@export var origin : Sprite2D
@export var originStart : Vector2i
@export var destination : Sprite2D
@export var destinationStart : Vector2i

@export var size : Vector2i
@export var CellSize = 64
@export var line : Line2D

@export var ObstacleParent : Node2D
@export var Obstacles : Array[Vector2i]
@export var obstacleTex : Texture2D

@export var ObstaclesAreSolid : bool
@export var ObstaclesAreWeight = 10

var createdObstacles : Array[Sprite2D]
var Width
var Height

func _ready():
	Refresh()


func Refresh():
	Width = size.x
	Height = size.y
	origin.position = originStart * CellSize
	destination.position = destinationStart * CellSize

	CreateObstacles()
	CreateGrid()

func CreateObstacles():
	for o in createdObstacles:
		ObstacleParent.remove_child	(o)
		o.queue_free()

	createdObstacles.clear()

	for obpos in Obstacles:
		var n = Sprite2D.new()
		n.texture = obstacleTex
		n.position = obpos * CellSize
		n.centered = false
		ObstacleParent.add_child(n)
		createdObstacles.append(n)

func CreateGrid():
	for x in Width:
		for y in Height:
			pass
