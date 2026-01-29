@tool
extends Control
class_name RADataimporter

@export var Panels : Array[RADataImporterPanel]

var httpRequester : HTTPRequest
var parent : RADataImporterEditor

func Initialize(_parent : RADataImporterEditor, _httpRequester : HTTPRequest):
	# this has to be passed from the root level script
	# the HTTPRequester won't work otherwise, and I'm not sure why
	httpRequester = _httpRequester
	parent = _parent

	for p in Panels:
		p.Initialize(_parent, _httpRequester)
