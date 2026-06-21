extends CanvasLayer

@onready var btn_buy = $Panel/TopBar/BtnBuy
@onready var btn_sell = $Panel/TopBar/BtnSell
@onready var btn_cancel = $Panel/TopBar/BtnCancel

@onready var item_vbox = $Panel/HBox/LeftPanel/ScrollContainer/VBoxContainer
@onready var lbl_coins = $Panel/HBox/RightPanel/LblCoins
@onready var lbl_possession = $Panel/HBox/RightPanel/LblPossession

var current_mode = "BUY"
var shop_items: Array[String] = ["potion", "ether"]

func setup(items: Array[String]):
	if items.size() > 0:
		shop_items = items
	_update_ui()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	btn_buy.pressed.connect(func(): _set_mode("BUY"))
	btn_sell.pressed.connect(func(): _set_mode("SELL"))
	btn_cancel.pressed.connect(_close_menu)
	
	_set_mode("BUY")

func _set_mode(mode: String):
	current_mode = mode
	_update_ui()

func _update_ui():
	# Bersihkan list
	for child in item_vbox.get_children():
		child.queue_free()
		
	if not get_node_or_null("/root/ItemDB"): return
	
	for item_id in shop_items:
		var item_data = ItemDB.get_item(item_id)
		if item_data.is_empty(): continue
		
		var btn = Button.new()
		var price = item_data.get("price", 0)
		var sell_price = int(price / 2)
		var item_name = item_data.get("name", "Unknown")
		
		if current_mode == "BUY":
			btn.text = "%s - %d Koin" % [item_name, price]
			if get_node_or_null("/root/Global") and Global.coins < price:
				btn.disabled = true
			btn.pressed.connect(func(id=item_id): _on_item_pressed(id))
		elif current_mode == "SELL":
			btn.text = "Jual %s - %d Koin" % [item_name, sell_price]
			if get_node_or_null("/root/Global") and Global.inventory.get(item_id, 0) <= 0:
				btn.disabled = true
			btn.pressed.connect(func(id=item_id): _on_item_pressed(id))
			
		var tex = ItemDB.get_item_icon(item_id)
		if tex:
			btn.icon = tex
			btn.expand_icon = true
			# Assuming a horizontal layout in the shop list
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			
		var rarity_color = Color(0.2, 0.2, 0.2, 0.8)
		if item_data.has("rarity"):
			rarity_color = ItemDB.get_rarity_color(item_data["rarity"])
			
		var style = StyleBoxFlat.new()
		style.bg_color = rarity_color
		style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("disabled", style)
			
		item_vbox.add_child(btn)
	
	if get_node_or_null("/root/Global"):
		lbl_coins.text = "Koin: " + str(Global.coins) + " G"
		var possession_texts = []
		for item_id in shop_items:
			var item_data = ItemDB.get_item(item_id)
			if item_data.is_empty(): continue
			var item_name = item_data.get("name", item_id)
			var count = Global.inventory.get(item_id, 0)
			possession_texts.append("%s (%d)" % [item_name, count])
			
		lbl_possession.text = "Dimiliki: " + ", ".join(possession_texts)

func _on_item_pressed(item_id: String):
	if not get_node_or_null("/root/Global") or not get_node_or_null("/root/ItemDB"): return
	
	var item_data = ItemDB.get_item(item_id)
	var price = item_data.get("price", 0)
	var sell_price = int(price / 2)
	
	if current_mode == "BUY":
		if Global.coins >= price:
			Global.coins -= price
			Global.inventory[item_id] = Global.inventory.get(item_id, 0) + 1
			_sync_player_coins()
	elif current_mode == "SELL":
		if Global.inventory.get(item_id, 0) > 0:
			Global.inventory[item_id] -= 1
			Global.coins += sell_price
			_sync_player_coins()
			
	_update_ui()

func _sync_player_coins():
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		players[0].coins = Global.coins
		players[0].emit_signal("coin_changed", Global.coins)

func _close_menu():
	get_tree().paused = false
	queue_free()
