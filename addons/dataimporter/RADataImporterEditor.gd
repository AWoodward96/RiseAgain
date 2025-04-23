@tool
extends EditorPlugin
class_name RADataImporterEditor

const scene = preload("res://addons/dataimporter/importer.tscn")
const icon =  preload("res://addons/dataimporter/database.png")

signal OnJSONParsed(_json)
var importer_instance
var httpRequest

func _enter_tree():
	importer_instance = scene.instantiate() as RADataimporter
	EditorInterface.get_editor_main_screen().add_child(importer_instance)
	_make_visible(false)
	ConnectHTTPRequest()
	importer_instance.Initialize(self, httpRequest)
	pass


func ConnectHTTPRequest():
	httpRequest = HTTPRequest.new()
	add_child(httpRequest)
	httpRequest.connect("request_completed", _on_http_request_request_completed)

func _exit_tree():
	if importer_instance:
		importer_instance.queue_free()
	pass

func _has_main_screen():
	return true

func _make_visible(visible):
	if importer_instance:
		importer_instance.visible = visible
	pass

func _get_plugin_name():
	return "Import"

func _get_plugin_icon():
	return icon

func _on_http_request_request_completed(result, response_code, headers, body):
	var bodyStr = body.get_string_from_utf8()
	var json = JSON.parse_string(bodyStr)
	OnJSONParsed.emit(json)
