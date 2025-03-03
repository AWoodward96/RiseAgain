extends CutsceneEventBase
class_name PlayGridEntityAnimationEvent

@export var Position : Vector2i
@export var AnimString : String

func Enter(_context : CutsceneContext):
	if Map.Current == null:
		return false

	var tile = Map.Current.grid.GetTile(Position)
	for ge in tile.GridEntities:
		if ge != null:
			ge.PlayAnimation(AnimString)

	return true
