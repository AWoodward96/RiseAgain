extends Node2D

@export var Tilemap : TileMap
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
var Pathfinding : AStarGrid2D
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
	DoCalc()

func DoCalc():
	var gotpoint = Pathfinding.get_point_path(origin.position / CellSize, destination.position / CellSize)
	line.clear_points()
	for p in gotpoint:
		line.add_point(Vector2(p.x, p.y) + Vector2(CellSize / 2, CellSize / 2))
	pass

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
	Pathfinding = AStarGrid2D.new()
	Pathfinding.region = Rect2i(0, 0, Width, Height)
	Pathfinding.cell_size = Vector2(CellSize, CellSize)
	Pathfinding.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	Pathfinding.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	Pathfinding.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	Pathfinding.update() # NOTE: calling update clears all solid data. DO NOT CALL THIS AGAIN

	for x in Width:
		for y in Height:
			var data = Tilemap.get_cell_tile_data(0,Vector2i(x,y))
			if data:
				if data.get_collision_polygons_count(0) > 0 :
					Pathfinding.set_point_solid(Vector2i(x,y), true)

	for ob in Obstacles:
		if ObstaclesAreSolid:
			Pathfinding.set_point_solid(ob, true)
		else:
			Pathfinding.set_point_weight_scale(ob, ObstaclesAreWeight)
