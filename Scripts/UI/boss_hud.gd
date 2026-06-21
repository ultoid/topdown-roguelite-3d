extends CanvasLayer

@onready var health_bar = get_node_or_null("BossHealthBar")
@onready var name_label = get_node_or_null("BossNameLabel")

var boss_ref: Node = null

func _ready():

	var bosses = get_tree().get_nodes_in_group("Boss")
	if bosses.size() > 0:
		boss_ref = bosses[0]
		if boss_ref.has_signal("health_changed"):
			boss_ref.health_changed.connect(_on_boss_health_changed)
			_on_boss_health_changed(boss_ref.current_health, boss_ref.max_health)
			
		if name_label and "boss_name" in boss_ref:
			name_label.text = boss_ref.boss_name

func _on_boss_health_changed(current: int, maximum: int):
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
