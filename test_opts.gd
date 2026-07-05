@tool
extends EditorScript
func _run():
	var importer = ResourceImporterScene.new()
	var options = importer.get_import_options("", 0)
	var f = FileAccess.open("res://import_options.txt", FileAccess.WRITE)
	for opt in options:
		if "rest" in opt.name.to_lower():
			f.store_line(opt.name)
	f.close()
