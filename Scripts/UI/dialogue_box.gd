extends CanvasLayer

@onready var text_label = $Panel/MarginContainer/RichTextLabel
@onready var panel = $Panel
@onready var choice_box = get_node_or_null("ChoiceBox")
@onready var btn_yes = get_node_or_null("ChoiceBox/VBoxContainer/BtnYes")
@onready var btn_no = get_node_or_null("ChoiceBox/VBoxContainer/BtnNo")

var texts = []
var current_text_index = 0
var is_active = false
var is_waiting_for_choice = false
var callback_target = null
var callback_method = ""

func _ready():
	panel.hide()
	if choice_box:
		choice_box.hide()
		btn_yes.pressed.connect(_on_btn_yes_pressed)
		btn_no.pressed.connect(_on_btn_no_pressed)

func start_dialogue(dialogue_lines: Array, target = null, method = ""):
	texts = dialogue_lines
	current_text_index = 0
	callback_target = target
	callback_method = method
	
	if texts.size() > 0:
		is_active = true
		panel.show()
		show_text()
		get_tree().paused = true

func show_text():
	text_label.text = texts[current_text_index]

func _input(event):
	if is_active:
		if is_waiting_for_choice:
			if event is InputEventKey and event.pressed:
				if event.physical_keycode == KEY_Y or event.keycode == KEY_Y:
					_on_choice_made(true)
				elif event.physical_keycode == KEY_N or event.keycode == KEY_N:
					_on_choice_made(false)
		elif event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			current_text_index += 1
			if current_text_index < texts.size():
				show_text()
			else:
				if callback_method == "warp_to_dungeon":
					show_choice_box()
				else:
					end_dialogue()

func show_choice_box():
	is_waiting_for_choice = true
	if choice_box:
		choice_box.show()
		btn_yes.disabled = true
		btn_no.disabled = true
		
		# Tunggu 0.5 detik agar tombol tidak langsung tak sengaja tertekan
		await get_tree().create_timer(0.5).timeout
		
		btn_yes.disabled = false
		btn_no.disabled = false
		btn_yes.grab_focus()

func _on_btn_yes_pressed():
	_on_choice_made(true)

func _on_btn_no_pressed():
	_on_choice_made(false)

func _on_choice_made(accepted: bool):
	is_waiting_for_choice = false
	if choice_box:
		choice_box.hide()
		
	if accepted:
		end_dialogue()
	else:
		callback_target = null
		callback_method = ""
		end_dialogue()

func end_dialogue():
	is_active = false
	panel.hide()
	get_tree().paused = false
	if callback_target and callback_method != "":
		callback_target.call(callback_method)
	queue_free()
