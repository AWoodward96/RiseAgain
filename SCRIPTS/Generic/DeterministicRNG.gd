extends Object
class_name DeterministicRNG

var rng : RandomNumberGenerator
var randomSeed : int
var uses :  int = 0

func ToJSON():
	var returnJSON = {
		"randomSeed" = randomSeed,
		"uses" = uses
	}

static func FromJSON(_dict : Dictionary):
	var deterministicRNG = DeterministicRNG.new()
	deterministicRNG.randomSeed = _dict["randomSeed"]
	deterministicRNG.uses = _dict["uses"]
	deterministicRNG.SetUpRNG()
	return deterministicRNG

static func Construct(_seed : int = -1, _uses : int = 0):
	var deterministicRNG = DeterministicRNG.new()
	var newSeed = _seed
	if newSeed == -1:
		var random = RandomNumberGenerator.new()
		newSeed = random.randi()

	deterministicRNG.randomSeed = newSeed
	deterministicRNG.uses = _uses
	deterministicRNG.SetUpRNG()
	return deterministicRNG

func SetUpRNG():
	rng = RandomNumberGenerator.new()
	rng.seed = randomSeed
	BurnRNG(uses)

func BurnRNG(_amountToBurn : int):
	for i in _amountToBurn:
		var variable = rng.randi()
		# that rng should now be 'burnt' and we should be set up for the next sequence

func NextInt(min : int, max : int):
	uses += 1
	return rng.randi_range(min, max)

func NextFloat(min : float, max : float):
	# We do it like this because randf_range burns two rngs and fucks with determanism
	uses += 1
	var result = rng.randi_range(0, 10000) / 10000.0
	return (result * (max - min)) + min
