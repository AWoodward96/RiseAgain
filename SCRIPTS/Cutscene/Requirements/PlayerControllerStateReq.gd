extends RequirementBase
class_name PlayerControllerStateReq

enum CtrlStateEnum { Selection, Movement, Targeting, Context }

@export var State : CtrlStateEnum

func CheckRequirement(_genericData):
	if Map.Current == null || Map.Current.playercontroller == null:
		return false

	match State:
		CtrlStateEnum.Selection:
			return Map.Current.playercontroller.ControllerState is SelectionControllerState
		CtrlStateEnum.Movement:
			return Map.Current.playercontroller.ControllerState is UnitMoveControllerState
		CtrlStateEnum.Targeting:
			return Map.Current.playercontroller.ControllerState is TargetingControllerState
		CtrlStateEnum.Context:
			return Map.Current.playercontroller.ControllerState is ContextControllerState

	return false
