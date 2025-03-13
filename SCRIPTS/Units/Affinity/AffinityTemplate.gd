extends Resource
class_name AffinityTemplate


# NOTE: OKAY
# So Godot - in all of its infinite wisdom - does not support 'cyclical references'
# And that is a problem.
# I would love for the strongAgainst and opposedWith variables to be arrays of other affinities
# BUUUUT if two affiinities are affective against each other
# (such as the intention of the 'opposedWith' section)
# then for some completely assonine reason - that's considered a cyclical reference
# SO.
# This is what I came up with. Every affinity has an int flag
# Every int-flag has something it's strong against and what it's weak against
# and then I bit-compare it to the effectivness of this affinity

# God I fucking hate this.


# Theis is the affinity this template represents
@export_flags("Fire", "Water", "Grass", "Metal", "Earth", "Light", "Dark", "Maggai") var affinity : int

# These are the affinities we deal more damage to
@export_flags("Fire", "Water", "Grass", "Metal", "Earth", "Light", "Dark", "Maggai") var strongAgainst : int

# These affinities deal 1.25% damage to each other, as opposed to the 1.5%
#@export_flags("Fire", "Water", "Earth", "Light", "Dark", "Scholar", "Maggai") var opposedWith : int

@export var loc_icon : Texture2D
@export var loc_name : String


func GetAffinityDamageMultiplier(_opponentAffinity : AffinityTemplate):
	if _opponentAffinity == null:
		return 1

	if _opponentAffinity.affinity & strongAgainst:
		return GameManager.GameSettings.StrongAffinityMultiplier

	#if _opponentAffinity.affinity & opposedWith:
		#return GameManager.GameSettings.OpposedAffinityMultiplier

	if affinity & _opponentAffinity.strongAgainst:
		return GameManager.GameSettings.WeakAffinityMultiplier

	return 1

func GetAffinityAccuracyModifier(_opponentAffinity : AffinityTemplate):
	if _opponentAffinity == null:
		return 0

	if _opponentAffinity.affinity & strongAgainst:
		return GameManager.GameSettings.AffinityAccuracyModifier

	return 0
