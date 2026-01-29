extends TileMapLayer
class_name ObscurableTilemapLayer

@export var transparencyLimit : float = 0.35
@export var transparencyStep : float = 0.1

var currentMap : Map

# Dict of Vector2i to internal Tile class
var stack_enter : Dictionary
var stack_exit : Dictionary


func RegisterTile(_tile : Tile):
	if _tile != null && !stack_enter.has(_tile.Position):
		stack_enter[_tile.Position] = _tile
		notify_runtime_tile_data_update()

func DeregisterTile(_tile : Tile):
	if _tile != null && !stack_exit.has(_tile.Position):
		if stack_enter.has(_tile.Position):
			stack_enter.erase(_tile.Position)
		stack_exit[_tile.Position] = _tile
		notify_runtime_tile_data_update()

# Update tile
func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData):
	# The tile in the dictionary refers to the tile that is obstructing
	var color = Color.WHITE
	if stack_enter.has(coords):
		var currentAlpha = stack_enter[coords].ObscureAlpha
		currentAlpha -= transparencyStep
		currentAlpha = clamp(currentAlpha, transparencyLimit, 1)
		color.a = currentAlpha
		tile_data.modulate = color
		stack_enter[coords].ObscureAlpha = currentAlpha
	elif stack_exit.has(coords):
		var currentAlpha = stack_exit[coords].ObscureAlpha
		currentAlpha += transparencyStep
		currentAlpha = clamp(currentAlpha, transparencyLimit, 1)
		color.a = currentAlpha
		tile_data.modulate = color
		stack_exit[coords].ObscureAlpha = currentAlpha
		if currentAlpha == 1:
			stack_exit.erase(coords)

	notify_runtime_tile_data_update()
	pass

func _physics_process(_delta: float):
	if stack_exit.size() != 0 || stack_enter.size() != 0:
		notify_runtime_tile_data_update()

## Should tile at coords be updated?
func _use_tile_data_runtime_update(coords: Vector2i):
	return stack_enter.has(coords) || stack_exit.has(coords)
