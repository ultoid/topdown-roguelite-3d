extends Node
class_name PlayerCombat

@onready var player: CharacterBody3D = get_parent()

func _execute_skill(skill_id: String, data: Dictionary, t_pos: Vector3, indicator: Node = null):
	var skill_db = player.get_node_or_null("/root/SkillDB")
	if not skill_db: return
	var cur_lvl = Global.unlocked_skills.get(skill_id, 0)
	var dmg = skill_db.get_skill_val(skill_id, "damages", cur_lvl)
	var dur = skill_db.get_skill_val(skill_id, "effect_durations", cur_lvl)
	var aoe = skill_db.get_skill_val(skill_id, "aoe_radiuses", cur_lvl)
	var crit = skill_db.get_skill_val(skill_id, "crit_chances", cur_lvl)
	
	var el_multiplier = 1.0 + player.elemental_mastery_bonus_pct
	
	var manual_anim_skills = ["aqua_blast", "cyclone_sweep", "fatal_blow", "impact_wave", "fatal_smash", "implosion"]
	if not skill_id in manual_anim_skills:
		player.is_animating_skill = true
		var anim_time = 0.3
		if skill_id == "seismic_fissure":
			anim_time = 0.6
		player.get_tree().create_timer(anim_time).timeout.connect(func(): player.is_animating_skill = false)
	
	var c_name = Global.current_class
	if c_name == "apprentice":
		ApprenticeSkills.execute(self, skill_id, data, t_pos, indicator, cur_lvl, dmg, dur, aoe, crit, el_multiplier)
	elif c_name == "fighter":
		FighterSkills.execute(self, skill_id, data, t_pos, indicator, cur_lvl, dmg, dur, aoe, crit, el_multiplier)
	elif c_name == "scout":
		ScoutSkills.execute(self, skill_id, data, t_pos, indicator, cur_lvl, dmg, dur, aoe, crit, el_multiplier)

func level_up():
	player.player_stats.level_up()

