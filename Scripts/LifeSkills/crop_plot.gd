extends Node3D
var modulate: Color = Color(1, 1, 1) # Dummy for 3D

enum State { EMPTY, PLANTED, READY }

var plot_id: String = ""
const MAX_GROWTH_TIME: float = 120.0 # 2 minutes debug

@onready var visual_empty = $Visuals/Empty
@onready var visual_planted = $Visuals/Planted
@onready var visual_ready = $Visuals/Ready
@onready var interact_area = $InteractArea
@onready var status_ui = get_node_or_null("StatusUI")
@onready var status_label = get_node_or_null("StatusUI/VBox/Label")

var player_ref = null

func _ready():
	interact_area.add_to_group("Interactable")
	_update_visuals()

func _get_global_data() -> Dictionary:
	if plot_id != "" and get_node_or_null("/root/Global") and Global.farm_plots.has(plot_id):
		return Global.farm_plots[plot_id]
	return {}

func _update_visuals():
	if not visual_empty: return # In case nodes aren't ready yet
	
	var data = _get_global_data()
	var current_state = data.get("state", 0) if not data.is_empty() else State.EMPTY
	var watered_time_left = data.get("watered_time_left", 0.0) if not data.is_empty() else 0.0
	
	visual_empty.visible = (current_state == State.EMPTY)
	visual_planted.visible = (current_state == State.PLANTED)
	visual_ready.visible = (current_state == State.READY)
	
	if status_ui:
		status_ui.visible = (current_state != State.EMPTY)
		
	if watered_time_left > 0:
		visual_empty.modulate = Color(0.6, 0.4, 0.2) # Darker/wet look
		visual_planted.modulate = Color(0.6, 0.4, 0.2)
	else:
		visual_empty.modulate = Color(1, 1, 1)
		visual_planted.modulate = Color(1, 1, 1)
		
	visual_ready.modulate = Color(1, 1, 1)

func _process(delta):
	var data = _get_global_data()
	if data.is_empty(): return
	
	var current_state = data.get("state", 0)
	var growth_time = data.get("growth_time", 0.0)
	var watered_time_left = data.get("watered_time_left", 0.0)
	var max_time = data.get("max_growth_time", MAX_GROWTH_TIME)
	
	# Detect state change to update visuals
	if visual_planted.visible and current_state == State.READY:
		_update_visuals()
				
	if status_label and status_ui and status_ui.visible:
		if current_state == State.READY:
			status_label.text = "Siap Panen!"
			status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		else:
			var remaining_time = int(max_time - growth_time)
			if remaining_time < 0: remaining_time = 0
			var m = remaining_time / 60
			var s = remaining_time % 60
			var time_str = "%02d:%02d" % [m, s]
			var water_status = "Disiram" if watered_time_left > 0 else "Kering"
			var water_color = Color(0.4, 0.8, 1.0) if watered_time_left > 0 else Color(1.0, 0.4, 0.4)
			
			status_label.text = time_str + "\n" + water_status
			status_label.add_theme_color_override("font_color", water_color)

# This is called by the InteractArea child
func on_interact(player):
	player_ref = player
	var data = _get_global_data()
	if data.is_empty(): return
	var current_state = data.get("state", 0)
	
	if current_state == State.EMPTY:
		# Open seed menu
		var menu_scene = load("res://Scenes/UI/seed_menu.tscn")
		if menu_scene:
			var menu = menu_scene.instantiate()
			menu.plot_ref = self
			get_tree().root.add_child(menu)
			
	elif current_state == State.PLANTED:
		if Global.inventory.has("watering_can") and Global.inventory["watering_can"] > 0:
			data["watered_time_left"] += 60.0 # 1 minute debug
			player.spawn_floating_text("Disiram!", Color(0.2, 0.5, 1.0))
			_update_visuals()
		else:
			player.spawn_floating_text("Butuh Watering Can!", Color(1, 0.2, 0.2))
			
	elif current_state == State.READY:
		# Harvest
		if not Global.inventory.has("herb"):
			Global.inventory["herb"] = 0
		Global.inventory["herb"] += 2
		player.spawn_floating_text("+2 Herb", Color(0.2, 1.0, 0.2))
		data["state"] = State.EMPTY
		data["growth_time"] = 0.0
		data["watered_time_left"] = 0.0
		_update_visuals()

func _on_interact_mouse_entered():
	if status_ui:
		var data = _get_global_data()
		var current_state = data.get("state", 0) if not data.is_empty() else State.EMPTY
		if current_state != State.EMPTY:
			status_ui.show()

func _on_interact_mouse_exited():
	if status_ui:
		status_ui.hide()

func plant_seed(seed_type: String):
	if player_ref:
		player_ref.start_life_skill(self, 3, "planting")

func on_cancel():
	pass

func on_complete(player):
	# Callback after planting animation
	Global.inventory["seed"] -= 1
	var data = _get_global_data()
	if not data.is_empty():
		data["state"] = State.PLANTED
		data["growth_time"] = 0.0
	_update_visuals()

func destroy_plot():
	if plot_id != "" and get_node_or_null("/root/Global"):
		Global.farm_plots.erase(plot_id)
	queue_free()
