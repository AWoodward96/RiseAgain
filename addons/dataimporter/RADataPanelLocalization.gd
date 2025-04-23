@tool
extends RADataImporterPanel


var localizationFileLocation : String = "res://RESOURCES/Localization/RALocalization.csv"

func import_data_from_json(_data):

	var file = FileAccess.open(localizationFileLocation, FileAccess.WRITE)
	var fileString = ""

	fileString += "key,en\n"

	for line in _data:
		fileString += get_loc_content(line, "key") + ","
		fileString += get_loc_content(line, "en") # Last one doesn't need the comma?
		#fileString += get_loc_content(line, "es") + ","
		fileString += "\n"

	file.store_string(fileString)
	file.close()
	errorPanel.text = log

	var d = ConfirmationDialog.new()
	d.dialog_text = "Import Complete"
	d.title = "Alert"
	add_child(d)
	d.popup_centered()

func get_loc_content(_line, _languagecode):
	if _line.has(_languagecode):
		var str = _line[_languagecode]
		if str.contains(","):
			return "\"" + _line[_languagecode] + "\""
		else:
			return _line[_languagecode]
	return ""
