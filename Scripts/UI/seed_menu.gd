extends CanvasLayer

var plot_ref = null

@onready var seed_btn = $Panel/VBoxContainer/SeedButton
@onready var destroy_btn = $Panel/VBoxContainer/DestroyButton
@onready var cancel_btn = $Panel/VBoxContainer/CancelButton

func _ready():
    seed_btn.pressed.connect(_on_seed_pressed)
    destroy_btn.pressed.connect(_on_destroy_pressed)
    cancel_btn.pressed.connect(_on_cancel_pressed)
    
    var seeds = Global.inventory.get("seed", 0)
    if seeds <= 0:
        seed_btn.disabled = true
        seed_btn.text = "Tanam Seed (Habis)"
    else:
        seed_btn.text = "Tanam Seed (" + str(seeds) + ")"

func _on_seed_pressed():
    if plot_ref:
        plot_ref.plant_seed("seed")
    queue_free()

func _on_destroy_pressed():
    if plot_ref:
        plot_ref.destroy_plot()
    queue_free()

func _on_cancel_pressed():
    queue_free()
