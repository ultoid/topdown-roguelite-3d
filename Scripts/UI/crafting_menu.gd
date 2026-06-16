extends CanvasLayer

@onready var recipes_container = $MainPanel/LeftPanel/ScrollContainer/VBoxContainer
@onready var details_container = $MainPanel/RightPanel/DetailsContainer
@onready var recipe_title = $MainPanel/RightPanel/RecipeTitle
@onready var result_icon = $MainPanel/RightPanel/DetailsContainer/ResultIcon
@onready var materials_hbox = $MainPanel/RightPanel/DetailsContainer/MaterialsHBox
@onready var progress_bar = $MainPanel/RightPanel/DetailsContainer/ProgressBar
@onready var craft_btn = $MainPanel/RightPanel/DetailsContainer/CraftButton
@onready var close_btn = $MainPanel/CloseButton

var selected_recipe_id: String = ""
var was_crafting_last_frame: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_btn.pressed.connect(_close_menu)
	craft_btn.pressed.connect(_on_craft_pressed)
	_populate_recipes()
	get_tree().paused = true

func _unhandled_input(event):
	if event.is_action_pressed("open_crafting"):
		_close_menu()
		get_viewport().set_input_as_handled()

func _populate_recipes():
	# Clear existing
	for child in recipes_container.get_children():
		child.queue_free()
		
	var has_recipes = false
	if get_node_or_null("/root/Global"):
		for recipe_id in Global.unlocked_recipes:
			if Global.CRAFTING_RECIPES.has(recipe_id):
				has_recipes = true
				var recipe_data = Global.CRAFTING_RECIPES[recipe_id]
				var btn = Button.new()
				
				# Get item name from ItemDB
				var item_name = recipe_id.capitalize()
				var item_db = get_node_or_null("/root/ItemDB")
				if item_db:
					var db_data = item_db.get_item(recipe_id)
					if db_data.has("name"):
						item_name = db_data["name"]
					var tex = item_db.get_item_icon(recipe_id)
					if tex:
						btn.icon = tex
						btn.expand_icon = true
						
				btn.text = " " + item_name
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.custom_minimum_size = Vector2(0, 40)
				btn.pressed.connect(func(): _select_recipe(recipe_id))
				recipes_container.add_child(btn)
				
	if not has_recipes:
		recipe_title.text = "Belum ada resep yang dipelajari."

func _select_recipe(recipe_id: String):
	if Global.is_crafting: return
	
	selected_recipe_id = recipe_id
	var recipe_data = Global.CRAFTING_RECIPES[recipe_id]
	
	# Setup Title & Icon
	var item_name = recipe_id.capitalize()
	var item_db = get_node_or_null("/root/ItemDB")
	if item_db:
		var db_data = item_db.get_item(recipe_id)
		if db_data.has("name"): item_name = db_data["name"]
		var tex = item_db.get_item_icon(recipe_id)
		if tex: result_icon.texture = tex
		
	recipe_title.text = item_name
	details_container.show()
	
	_update_materials_ui()
	progress_bar.value = 0
	
func _update_materials_ui():
	if selected_recipe_id == "": return
	var recipe_data = Global.CRAFTING_RECIPES[selected_recipe_id]
	
	# Clear materials
	for child in materials_hbox.get_children():
		child.queue_free()
		
	var can_craft = true
	var materials = recipe_data.get("materials", {})
	var item_db = get_node_or_null("/root/ItemDB")
	
	for mat_id in materials.keys():
		var required_amt = materials[mat_id]
		var current_amt = Global.inventory.get(mat_id, 0) if get_node_or_null("/root/Global") else 0
		
		var vbox = VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var mat_icon = TextureRect.new()
		mat_icon.custom_minimum_size = Vector2(40, 40)
		if item_db:
			var tex = item_db.get_item_icon(mat_id)
			if tex: mat_icon.texture = tex
			
			var db_data = item_db.get_item(mat_id)
			if not db_data.is_empty():
				var t_name = db_data.get("name", mat_id.capitalize())
				var t_desc = db_data.get("description", "")
				vbox.tooltip_text = t_name + "\n" + t_desc
				
		mat_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mat_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var lbl = Label.new()
		lbl.text = str(current_amt) + "/" + str(required_amt)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.theme_type_variation = "HeaderSmall"
		lbl.add_theme_font_size_override("font_size", 12)
		
		if current_amt >= required_amt:
			lbl.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		else:
			lbl.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
			can_craft = false
			
		vbox.add_child(mat_icon)
		vbox.add_child(lbl)
		materials_hbox.add_child(vbox)
		
	craft_btn.disabled = not can_craft or Global.is_crafting
	
func _on_craft_pressed():
	if selected_recipe_id == "" or Global.is_crafting: return
	
	var recipe_data = Global.CRAFTING_RECIPES[selected_recipe_id]
	
	# Deduct materials
	var materials = recipe_data.get("materials", {})
	for mat_id in materials.keys():
		Global.inventory[mat_id] -= materials[mat_id]
		if Global.inventory[mat_id] <= 0:
			Global.inventory.erase(mat_id)
			
	Global.craft_duration = recipe_data.get("time", 2.0)
	Global.craft_timer = 0.0
	Global.craft_recipe_id = selected_recipe_id
	Global.is_crafting = true
	
	_update_materials_ui()

func _process(delta):
	if Global.is_crafting:
		was_crafting_last_frame = true
		if Global.craft_recipe_id == selected_recipe_id:
			progress_bar.value = (Global.craft_timer / Global.craft_duration) * 100.0
			craft_btn.disabled = true
	else:
		if was_crafting_last_frame:
			was_crafting_last_frame = false
			progress_bar.value = 100.0
			_update_materials_ui()
			_show_success_btn()

func _show_success_btn():
	craft_btn.text = "Berhasil!"
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(craft_btn):
		craft_btn.text = "Craft"
		progress_bar.value = 0.0

func _close_menu():
	get_tree().paused = false
	queue_free()
