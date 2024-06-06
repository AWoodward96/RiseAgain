extends Control

signal AnimationComplete

func OnAnimationComplete():
	AnimationComplete.emit()
