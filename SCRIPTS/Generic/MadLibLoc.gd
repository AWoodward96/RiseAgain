extends Resource
class_name MadLibLoc

@export var loc_string : String
@export var mad_libs : Array[MadLib]


func GetString(_context):
	var str = tr(loc_string)
	for lib in mad_libs:
		str = lib.ApplyMadLib(str, _context)

	return str
