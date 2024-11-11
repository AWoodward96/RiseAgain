extends UnitUsable
class_name PassiveAbility



func ShowRangePreview(_sorted : bool = true):
	return

func GetAccuracy():
	return 100

func IsHeal():
	return false

func IsDamage():
	return false

func GetRange():
	return Vector2i(0, 0)

func IsWithinRange(_currentPosition : Vector2, _target : Vector2):
	return false
