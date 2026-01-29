extends Resource
class_name PackedResourceDef

# ResourceDef but it's a resource file, so that you can define an expense that's shared
#  in multiple ares of that

@export var cost : Array[ResourceDef]
