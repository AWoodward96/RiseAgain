class_name TargetingData

enum TargetingType { Simple, ShapedFree, ShapedDirectional }

# x = min, y = max
var TargetRange : Vector2i
var TilesInRange : Array[Tile]
var Type : TargetingType

# TODO: Implement a way to do shaped targeting
var shapedPrefab : PackedScene

