extends Sprite2D
class_name SkillData

@export var skill_name: String = ""
@export_multiline var description: String = ""
@export_enum("instant", "target_aoe", "passive", "buff") var type: String = "instant"
@export var class_owner: String = "fighter"

@export_group("Skill Progression")
@export var max_level: int = 1
@export var prerequisite_skill: String = ""
@export var prerequisite_level: int = 1

@export_group("Level Scaling (Index 0 = Lv 1)")
@export var ep_costs: Array[int] = [0]
@export var mp_costs: Array[int] = [0]
@export var cooldowns: Array[float] = [0.0]
@export var cast_times: Array[float] = [0.0]

@export_group("Effects (Index 0 = Lv 1)")
@export var damages: Array[int] = [0]
@export var effect_durations: Array[float] = [0.0]
@export var crit_chances: Array[float] = [0.0]
@export var aoe_radiuses: Array[int] = [0]
@export var ranges: Array[int] = [0]

@export_group("Visuals")
@export var icon_color: Color = Color(1, 1, 1, 1)
