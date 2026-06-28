extends CanvasLayer

var player: Node3D

var all_buffs = [
	{"id": "speed", "title": "Sepatu Hermes", "desc": "Lari +20%", "cost": 10},
	{"id": "damage", "title": "Otot Kawat", "desc": "Damage Dasar +2", "cost": 15},
	{"id": "health", "title": "Darah Suci", "desc": "Max HP +50", "cost": 15},
	{"id": "atk_speed", "title": "Tangan Kilat", "desc": "Atk Speed +20%", "cost": 10}
]
var shop_buffs = []

@onready var shop_btn1 = $Panel/VBox/ShopBtn1
@onready var shop_btn2 = $Panel/VBox/ShopBtn2
@onready var shop_btn3 = $Panel/VBox/ShopBtn3
@onready var lbl_coins = $Panel/VBox/LblCoins
@onready var btn_close = $Panel/BtnClose

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	self.hide() # Sembunyikan dulu
	
	btn_close.pressed.connect(_close_menu)
	shop_btn1.pressed.connect(func(): _buy_buff(0))
	shop_btn2.pressed.connect(func(): _buy_buff(1))
	shop_btn3.pressed.connect(func(): _buy_buff(2))
	
	# Beri waktu 2 detik bagi pemain untuk memungut loot Boss
	await get_tree().create_timer(2.0).timeout
	self.show()
	get_tree().paused = true

func setup(player_node: Node3D):
	player = player_node
	
	var shuffled_buffs = all_buffs.duplicate()
	shuffled_buffs.shuffle()
	shop_buffs = [shuffled_buffs[0], shuffled_buffs[1], shuffled_buffs[2]]
	
	if player and not player.coin_changed.is_connected(_update_ui_from_signal):
		player.coin_changed.connect(_update_ui_from_signal)
	
	_update_ui()

func _update_ui_from_signal(_coins: int):
	_update_ui()

func _update_ui():
	lbl_coins.text = "Koin Anda: " + str(Global.coins)
	_update_shop_button(shop_btn1, 0)
	_update_shop_button(shop_btn2, 1)
	_update_shop_button(shop_btn3, 2)

func _update_shop_button(btn: Button, index: int):
	var b = shop_buffs[index]
	btn.text = b["title"] + " (" + str(b["cost"]) + " Koin)\n" + b["desc"]
	if Global.coins < b["cost"]:
		btn.disabled = true
	else:
		btn.disabled = false

func _buy_buff(index: int):
	var b = shop_buffs[index]
	if Global.coins < b["cost"]: return
	
	Global.coins -= b["cost"]
	if player:
		player.coins = Global.coins
		player.emit_signal("coin_changed", Global.coins)
	
	# Terapkan efek ke base stats player
	if player:
		if b["id"] == "speed":
			player.walk_speed *= 1.2
			player.run_speed *= 1.2
		elif b["id"] == "damage":
			player.base_damage += 2
		elif b["id"] == "health":
			player.max_health += 50
			player.current_health = min(player.current_health + 50, player.max_health)
			player.emit_signal("health_changed", player.current_health, player.max_health)
		elif b["id"] == "atk_speed":
			player.attack_speed_multiplier *= 1.2
	
	print("Buff berhasil dibeli: ", b["title"])
	_update_ui()

func _close_menu():
	get_tree().paused = false
	queue_free()
	# Karena ini adalah hadiah boss, setelah selesai pemain pulang ke kota!
	get_tree().change_scene_to_file("res://Scenes/Maps/forest.tscn")
