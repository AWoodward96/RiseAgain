extends CutsceneEventBase
class_name BlockContextMenuOptionsEvent

@export var BlockWeapons : bool
@export var BlockAbilities : bool
@export var BlockTacticals : bool
@export var BlockWait : bool

func Enter(_context : CutsceneContext):
	CutsceneManager.local_block_weapon_context = BlockWeapons
	CutsceneManager.local_block_ability_context = BlockAbilities
	CutsceneManager.local_block_tactical_context = BlockTacticals
	CutsceneManager.local_block_wait_context = BlockWait
	return true
