extends CanvasLayer
class_name GlobalUIHelper

static var IsShowingResourceUI : bool = false


@export_category("Resource UI")
@export var ResourceParent : Control
@export var ResourceAnimator : AnimationPlayer

@export var PrimaryCurrenciesParent : Control
@export var SecondaryCurrenciesParent : Control

@export var GoldLabel : Label
@export var FoodLabel : Label
@export var OreLabel : Label
@export var WoodLabel : Label

@export var ConcoctionsLabel : Label
@export var GemstonesLabel : Label

@export var BurstSpritesParent : Control

@export_category("Juice")
@export var maxAquisitionBurstAmount : int = 15
@export var maxPurchaseBurstAmount : int = 5
@export var burstAreaMin : int = 0
@export var burstAreaMax : int = 32
@export var burstSpreadMin : int = 32
@export var burstSpreadMax : int = 64

var ShowResourceCount : int :
	set(_val):
		var prev = ShowResourceCount
		ShowResourceCount = _val
		if ShowResourceCount > 0:
			if prev <= 0:
				ResourceAnimator.play("show")
		else:
			if prev > 0:
				ResourceAnimator.play("hide")


func SetPrimaryEnabled(_visible : bool):
	PrimaryCurrenciesParent.visible = _visible

func SetSecondaryEnabled(_visible : bool):
	SecondaryCurrenciesParent.visible = _visible

func RefreshResourceLabels(_useLastSeen : bool):
	for persist in PersistDataManager.universeData.resourceData:
		var correctLabel = GetLabelFromResource(persist.template)
		if correctLabel != null:
			correctLabel.text = str(persist.lastSeenAmount) if _useLastSeen else str(persist.amount)

func ShowResources(_refreshLabels = true):
	if _refreshLabels:
		RefreshResourceLabels(false)
	ShowResourceCount += 1

func HideResources():
	ShowResourceCount -= 1

func GetLabelFromResource(_resourceTemplate : ResourceTemplate):
	var correctLabel = null
	match _resourceTemplate:
		GameManager.GameSettings.GoldResource:
			correctLabel = GoldLabel
		GameManager.GameSettings.OreResource:
			correctLabel = OreLabel
		GameManager.GameSettings.WoodResource:
			correctLabel = WoodLabel
		GameManager.GameSettings.FoodResource:
			correctLabel = FoodLabel
		GameManager.GameSettings.ConcoctionResource:
			correctLabel = ConcoctionsLabel
		GameManager.GameSettings.GemstoneResource:
			correctLabel = GemstonesLabel
	return correctLabel

func ShowResourcePayment(_cost : Array[ResourceDef]):
	if _cost.size() == 0:
		return

	var hasPrimaryToShow = false
	var hasSecondaryToShow = false
	for resource in _cost:
		if resource.ItemResource == GameManager.GameSettings.GoldResource || resource.ItemResource == GameManager.GameSettings.WoodResource || resource.ItemResource == GameManager.GameSettings.OreResource || resource.ItemResource == GameManager.GameSettings.FoodResource:
			hasPrimaryToShow = true
		elif resource.ItemResource == GameManager.GameSettings.GemstoneResource || resource.ItemResource == GameManager.GameSettings.ConcoctionResource:
			hasSecondaryToShow = true

		#tbd set this up or something
		var burstTween = create_tween()
		burstTween.set_trans(Tween.TRANS_SINE)
		burstTween.set_parallel(true)

		var createdBurst : Array[TextureRect]
		var label = GetLabelFromResource(resource.ItemResource)

		for i in range(0, min(resource.Amount, maxPurchaseBurstAmount)):
			var sprite = TextureRect.new()
			sprite.texture = resource.ItemResource.loc_icon
			sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sprite.size = Vector2(24, 24)
			BurstSpritesParent.add_child(sprite)
			sprite.position = label.global_position + Vector2(randf_range(-1, 1), randf_range(0, 1)) * randf_range(burstAreaMin, burstAreaMax)

			var burst = Vector2(randf_range(-1, 1), randf_range(0, 1)) * randf_range(burstSpreadMin, burstSpreadMax)
			burstTween.set_ease(Tween.EASE_OUT)
			burstTween.tween_property(sprite, "position", sprite.position + burst, 0.5)
			burstTween.tween_property(sprite, "rotation", sprite.rotation + randf_range(-1, 1), 0.5)
			createdBurst.append(sprite)
			pass

		burstTween.chain()
		burstTween.set_ease(Tween.EASE_OUT)
		for burst in createdBurst:
			# hacky but I'm tired
			burstTween.tween_property(burst, "scale", Vector2(0.1, 0.1), 1)
			burstTween.tween_property(burst, "modulate", Color(0,0,0,0), 1)

		var persist = PersistDataManager.universeData.GetResourceData(resource.ItemResource) as ResourcePersistence
		burstTween.tween_method(UpdateLabelText.bind(label), persist.lastSeenAmount, persist.amount, 1)
		burstTween.tween_interval(0.5)
		burstTween.chain()
		burstTween.tween_callback(ClearCreatedBursts.bind(createdBurst))
		persist.UpdateLastSeen()

	SetPrimaryEnabled(hasPrimaryToShow)
	SetSecondaryEnabled(hasSecondaryToShow)
	ShowResources(false)
	pass


func ShowResourceAcquisition(_origin : Vector2):
	var hasSomethingToShow = false
	var hasPrimaryToShow = false
	var hasSecondaryToShow = false
	RefreshResourceLabels(true)

	# tweens are black magic and you can't convince me otherwise
	for resource in PersistDataManager.universeData.resourceData:
		var difference = resource.amount - resource.lastSeenAmount
		var createdBurst : Array[TextureRect]

		if difference > 0:
			hasSomethingToShow = true
			resource.UpdateLastSeen()

			var burstTween = create_tween()
			burstTween.set_trans(Tween.TRANS_SINE)
			burstTween.set_parallel(true)

			if resource.template == GameManager.GameSettings.GoldResource || resource.template == GameManager.GameSettings.WoodResource || resource.template == GameManager.GameSettings.OreResource || resource.template == GameManager.GameSettings.FoodResource:
				hasPrimaryToShow = true
			elif resource.template == GameManager.GameSettings.GemstoneResource || resource.template == GameManager.GameSettings.ConcoctionResource:
				hasSecondaryToShow = true

			for i in range(0, min(difference, maxAquisitionBurstAmount)):
				var sprite = TextureRect.new()
				sprite.texture = resource.template.loc_icon
				sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				sprite.size = Vector2(24, 24)
				BurstSpritesParent.add_child(sprite)
				sprite.position = _origin + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * randf_range(burstAreaMin, burstAreaMax)

				var burst = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * randf_range(burstSpreadMin, burstSpreadMax)
				burstTween.set_ease(Tween.EASE_OUT)
				burstTween.tween_property(sprite, "position", sprite.position + burst, 0.5)
				burstTween.tween_property(sprite, "rotation", sprite.rotation + randf_range(-1, 1), 0.5)
				createdBurst.append(sprite)
				pass

			burstTween.chain()
			burstTween.tween_interval(0.5)
			burstTween.chain()
			burstTween.set_ease(Tween.EASE_IN)

			var correctLabel = GetLabelFromResource(resource.template)
			if correctLabel != null:
				for burst in createdBurst:
					# hacky but I'm tired
					burstTween.tween_property(burst, "position", correctLabel.global_position + Vector2(0, 72), 1)

			burstTween.chain()

			burstTween.set_ease(Tween.EASE_OUT)
			burstTween.tween_method(UpdateLabelText.bind(correctLabel), resource.amount - difference, resource.amount, 1)

			burstTween.tween_callback(ClearCreatedBursts.bind(createdBurst))

	SetPrimaryEnabled(hasPrimaryToShow)
	SetSecondaryEnabled(hasSecondaryToShow)
	if hasSomethingToShow:
		ShowResources(false)

func UpdateLabelText(_value : int, _label : Label):
	_label.text = str(_value)

func ClearCreatedBursts(_createdBurst : Array[TextureRect]):
	for burst in _createdBurst:
		burst.queue_free()

	_createdBurst.clear()
	# Has a built in ~2s delay so that it sticks around and finishes the count before self hiding
	HideResources()

func UpdateIsShowing(_showing : bool):
	IsShowingResourceUI = _showing
