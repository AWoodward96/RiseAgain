extends CombatEffectInstance
class_name TauntEffectInstance

# Handled by the enemy behavior
# As long as source isn't null we're good
func IsExpired():
	if TurnsRemaining == 0:
		return true

	if SourceUnit == null:
		return true

	return false


func ToJSON():
	var dict = super()
	dict["type"] = "TauntEffectInstance"
	return dict
