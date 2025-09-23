extends AnchoredUIElement
class_name TerrainInspectPanel


@export var tile_name : Label
@export var tile_health_parent : Control
@export var tile_health : Label
@export var tile_is_killbox_parent : Control
@export var tile_is_shroud_parent : Control
@export var fire_data_parent : Control
@export var fire_level_label : Label
@export var fire_damage_label : Label

@export var grid_entity_parent : Control
@export var grid_entity_prefab : PackedScene

@export var fire_level_loc : String
@export var fire_damage_loc : String
@export var no_name_loc : String

var shouldShow : bool
var createdGridEntityInfos : Array[Control]


func Update(_tile : Tile):
	shouldShow = false
	if _tile.MainTileData != null && _tile.MaxHealth > 0 && _tile.Health > 0:
		tile_health_parent.visible = true
		tile_name.text = tr(_tile.MainTileData.loc_name)
		tile_health.text = str(_tile.Health)
		shouldShow = true
	elif _tile.MainTileData != null && _tile.MaxHealth <= 0 && !_tile.TerrainDestroyed:
		tile_health_parent.visible = false
		tile_name.text = tr(_tile.MainTileData.loc_name)
		shouldShow = true
	elif _tile.BGTileData != null:
		# Oh hoh hoh okay so now we've just got the bg
		# Only the main tile data can have health, so lets hide that
		tile_health_parent.visible = false
		tile_name.text = tr(_tile.BGTileData.loc_name)
		shouldShow = true
	elif _tile.SubBGTileData != null:
		# OKAY WE'VE GONE A BIT FAR DOWN BUT WE CAN MAKE IT WORK
		# same thing as the bg layer
		tile_health_parent.visible = false
		tile_name.text = tr(_tile.SubBGTileData.loc_name)
		tile_is_killbox_parent.visible = _tile.SubBGTileData.Killbox
		shouldShow = true

	tile_is_killbox_parent.visible = _tile.ActiveKillbox
	tile_is_shroud_parent.visible = _tile.IsShroud
	UpdateFireData(_tile)
	UpdateGridEntities(_tile)
	Disabled = !shouldShow
	return !Disabled

func UpdateFireData(_tile : Tile):
	fire_data_parent.visible = _tile.FireLevel > 0
	if _tile.FireLevel > 0:
		if !shouldShow:
			# if false at this point, then there's no other information to show besides the fire info
			# do the best you can to show the information anyway
			tile_name.text = tr(no_name_loc)
			tile_health_parent.visible = false
			tile_is_killbox_parent.visible = false
			shouldShow = true

		fire_level_label.text = tr(fire_level_loc).format({"NUM" : str(_tile.FireLevel)})
		fire_damage_label.text = tr(fire_damage_loc).format({"NUM" : str(GameManager.GameSettings.GetFireDamage(_tile.FireLevel))})

func UpdateGridEntities(_tile : Tile):
	if !shouldShow && _tile.GridEntities.size() > 0:
		for  ge in _tile.GridEntities:
			if ge != null:
				shouldShow = true
		if !shouldShow:
			return

		# if false at this point, then there's no other information to show besides the fire info
		# do the best you can to show the information anyway
		tile_name.text = tr(no_name_loc)
		tile_health_parent.visible = false
		tile_is_killbox_parent.visible = false
		shouldShow = true

	for created in createdGridEntityInfos:
		var parent = created.get_parent()
		if parent != null:
			parent.remove_child(created)
		created.queue_free()
	createdGridEntityInfos.clear()

	for ge in _tile.GridEntities:
		if ge == null:
			continue

		# If marked as invisible - then this information is not necessary to share with the player'
		if ge.ui_invisible:
			continue

		var new = grid_entity_prefab.instantiate() as GridEntityCombatHUDEntry
		if new != null:
			new.Update(ge, _tile)
			grid_entity_parent.add_child(new)
			createdGridEntityInfos.append(new)
