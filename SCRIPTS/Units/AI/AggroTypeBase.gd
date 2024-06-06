extends Resource
class_name AlwaysAggro

# -----------------------
# AggroBase can also be used as 'Always Aggro'd'
# -----------------------
func Check(_self : UnitInstance, _map : Map) -> bool:
	return true
