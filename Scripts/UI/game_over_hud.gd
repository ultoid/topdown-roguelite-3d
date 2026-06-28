extends CanvasLayer

@onready var panel = get_node_or_null("GameOverPanel")
@onready var sum_label = get_node_or_null("GameOverPanel/SummaryLabel")
@onready var btn_restart = get_node_or_null("GameOverPanel/Button")

var btn_resurrect: Button = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	

	if panel:
		panel.visible = false
		if btn_restart:
			btn_restart.text = "Kembali ke Kota"
			if btn_restart.is_connected("pressed", Callable(self, "_on_restart_button_pressed")):
				btn_restart.disconnect("pressed", Callable(self, "_on_restart_button_pressed"))
			btn_restart.pressed.connect(_on_town_pressed)
			
		btn_resurrect = Button.new()
		btn_resurrect.text = "Bangkit Kembali (100 G)"
		btn_resurrect.position = Vector2(250, 249)
		panel.add_child(btn_resurrect)
		btn_resurrect.pressed.connect(_on_resurrect_pressed)

func show_game_over(survival_time: float, enemies_killed: int, level: int, coins: int):
	if panel:
		panel.visible = true
		if sum_label:
			sum_label.text = "Level: %d\nWaktu: %d detik\nKoin Diperoleh: %d" % [level, int(survival_time), coins]
		get_tree().paused = true
		
		if Global.coins < 100:
			btn_resurrect.disabled = true

func _on_town_pressed():
	get_tree().paused = false
	var town_scene = "res://Scenes/Items/grinding_camp.tscn" # Default town/maincity
	if ResourceLoader.exists("res://Scenes/Maps/forest.tscn"):
		town_scene = "res://Scenes/Maps/forest.tscn"
	get_tree().change_scene_to_file(town_scene)

func _on_resurrect_pressed():
	if Global.coins >= 100:
		Global.coins -= 100
		
		# Pulihkan HP dan MP player
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			var p = players[0]
			p.current_health = p.max_health
			p.current_mana = p.max_mana
			p.current_energy = p.max_energy
			p.is_dead = false
			p.emit_signal("health_changed", p.current_health, p.max_health)
			p.emit_signal("mana_changed", p.current_mana, p.max_mana)
			p.emit_signal("energy_changed", p.current_energy, p.max_energy)
			p.emit_signal("coin_changed", Global.coins)
			if p.animation_tree: p.animation_tree.active = true
			if p.state_machine: p.state_machine.travel("Idle")
		
		get_tree().paused = false
		queue_free()
