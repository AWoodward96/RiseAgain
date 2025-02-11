#@tool
extends Line2D

@export var map : Map

func _process(_delta):
	if Engine.is_editor_hint():
		if map == null:
			map = get_parent() as Map

		if map != null :
			self.show()
			UpdateSize()
	else:
		self.hide()


func UpdateSize():
	if map == null :
		return

	if !("TileSize" in map) || !("GridSize" in map):
		return

	clear_points()
	add_point(Vector2(0,0), 0)
	add_point(Vector2(map.TileSize * map.GridSize.x, 0), 1)
	add_point(Vector2(map.TileSize * map.GridSize.x, map.TileSize * map.GridSize.y), 2)
	add_point(Vector2(0, map.TileSize * map.GridSize.y), 3)
	add_point(Vector2(0, 0), 4)
