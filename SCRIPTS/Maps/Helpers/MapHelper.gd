@tool
extends Sprite2D
class_name MapHelper

@export var Position: Vector2i
@export var map : Map

func _process(_delta):
	if Engine.is_editor_hint():
		if map != null :
			self.show()
			UpdatePosition()

func UpdatePosition():
	if !("TileSize" in map) || !("GridSize" in map):
		return

	global_position = Position * map.TileSize
