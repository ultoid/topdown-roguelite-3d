extends CanvasLayer

@onready var button_container = $Panel/VBoxContainer/ScrollContainer/ButtonContainer

var effects = ["poison", "burn", "freeze", "chill", "bleed", "paralyze", "sleep", "confuse", "fear", "curse", "blind", "silence"]
var player = null

func setup(p_player):
	player = p_player
	get_tree().paused = true
	
	for eff in effects:
		var btn = Button.new()
		btn.text = "Apply " + eff.capitalize()
		btn.pressed.connect(_on_effect_pressed.bind(eff))
		button_container.add_child(btn)
		
	var btn_all = Button.new()
	btn_all.text = "Apply ALL"
	btn_all.pressed.connect(_on_apply_all)
	button_container.add_child(btn_all)
	
	var btn_cancel = Button.new()
	btn_cancel.text = "Batal"
	btn_cancel.pressed.connect(close)
	button_container.add_child(btn_cancel)
	
	if button_container.get_child_count() > 0:
		button_container.get_child(0).grab_focus()

func _on_effect_pressed(eff: String):
	if is_instance_valid(player) and player.status_manager:
		player.status_manager.apply_effect(eff, 5.0, 5.0) # Durasi 5 detik, Value 5
	close()

func _on_apply_all():
	if is_instance_valid(player) and player.status_manager:
		for eff in effects:
			player.status_manager.apply_effect(eff, 5.0, 5.0)
	close()

func close():
	get_tree().paused = false
	queue_free()
