extends Node
class_name PlayerStats

@onready var player: CharacterBody3D = get_parent()

func get_equipment_bonuses() -> Dictionary:
	var bonuses = {
		"str": 0, "vit": 0, "int": 0, "luk": 0, "agi": 0, "dex": 0,
		"p_atk": 0, "m_atk": 0, "p_def": 0, "m_def": 0,
		"max_hp": 0, "max_mp": 0
	}
	
	if not get_node_or_null("/root/Global"): return bonuses
	var item_db = get_node_or_null("/root/ItemDB")
	if not item_db: return bonuses
	
	for slot in Global.equipment.keys():
		var item_id = Global.equipment[slot]
		if item_id != "":
			var data = item_db.get_item(item_id)
			bonuses["str"] += data.get("bonus_str", 0)
			bonuses["vit"] += data.get("bonus_vit", 0)
			bonuses["int"] += data.get("bonus_int", 0)
			bonuses["luk"] += data.get("bonus_luk", 0)
			bonuses["agi"] += data.get("bonus_agi", 0)
			bonuses["dex"] += data.get("bonus_dex", 0)
			bonuses["p_atk"] += data.get("bonus_p_atk", 0)
			bonuses["m_atk"] += data.get("bonus_m_atk", 0)
			bonuses["p_def"] += data.get("bonus_p_def", 0)
			bonuses["m_def"] += data.get("bonus_m_def", 0)
			bonuses["max_hp"] += data.get("bonus_max_hp", 0)
			bonuses["max_mp"] += data.get("bonus_max_mp", 0)
			
	return bonuses


func recalculate_stats():
	var bonuses = player.get_equipment_bonuses()
	var old_max_hp = player.max_health
	var old_max_mp = player.max_mana
	var cls = Global.current_class if get_node_or_null("/root/Global") else "fighter"
	var base_stats = {"str": 5, "agi": 5, "vit": 5, "int": 5, "dex": 5, "luk": 5}
	if get_node_or_null("/root/Global") and Global.CLASS_BASE_STATS.has(cls):
		base_stats = Global.CLASS_BASE_STATS[cls]
		
	var t_str = base_stats["str"] + player.stat_str + bonuses["str"]
	var t_vit = base_stats["vit"] + player.stat_vit + bonuses["vit"]
	var t_int = base_stats["int"] + player.stat_int + bonuses["int"]
	var t_luk = base_stats["luk"] + player.stat_luk + bonuses["luk"]
	var t_agi = base_stats["agi"] + player.stat_agi + bonuses["agi"]
	var t_dex = base_stats["dex"] + player.stat_dex + bonuses["dex"]
	
	var wp_level = Global.unlocked_skills.get("weapon_mastery", 0) if get_node_or_null("/root/Global") else 0
	var wp_bonus = SkillDB.get_skill_val("weapon_mastery", "damages", wp_level) if wp_level > 0 and get_node_or_null("/root/SkillDB") else 0
	var vit_level = Global.unlocked_skills.get("vitality_mastery", 0) if get_node_or_null("/root/Global") else 0
	var vit_bonus = SkillDB.get_skill_val("vitality_mastery", "damages", vit_level) if vit_level > 0 and get_node_or_null("/root/SkillDB") else 0

	var el_mastery_lvl = Global.unlocked_skills.get("elemental_mastery", 0) if get_node_or_null("/root/Global") else 0
	var el_mp_bonus = SkillDB.get_skill_val("elemental_mastery", "mp_costs", el_mastery_lvl) if el_mastery_lvl > 0 and get_node_or_null("/root/SkillDB") else 0
	var el_dmg_bonus = SkillDB.get_skill_val("elemental_mastery", "damages", el_mastery_lvl) if el_mastery_lvl > 0 and get_node_or_null("/root/SkillDB") else 0
	player.elemental_mastery_bonus_pct = float(el_dmg_bonus) / 100.0

	player.max_health = 50 + (t_vit * 10) + bonuses["max_hp"]
	player.max_mana = 20 + (t_int * 5) + bonuses["max_mp"] + el_mp_bonus
	player.max_energy = 50.0 + (t_str * 10.0)
	
	player.physical_defense = t_vit + bonuses["p_def"] + vit_bonus
	player.magic_defense = int(t_vit / 2.0 + t_int / 2.0) + bonuses["m_def"] + vit_bonus
	
	if player.max_health > old_max_hp:
		player.current_health += (player.max_health - old_max_hp)
	if player.max_mana > old_max_mp:
		player.current_mana += (player.max_mana - old_max_mp)
		
	player.walk_speed = (10.0 * 1000.0 / 3600.0) + (t_agi * 0.04)
	player.run_speed = player.walk_speed * 2.0
	player.attack_speed_multiplier = 1.0 + (t_dex * 0.05)
	player.energy_regen = 5.0 + (t_agi * 0.5)
	
	player.physical_attack = 10 + (t_str * 2) + bonuses["p_atk"] + wp_bonus
	player.magic_attack = 10 + (t_int * 2) + bonuses["m_atk"]
	player.casting_speed = 1.0 + (t_dex * 0.05)
	player.critical_chance = t_luk * 1.0
	player.accuracy = 1.0 + (t_dex * 0.05)
	
	if get_node_or_null("/root/Global"):
		Global.perm_stat_str = player.stat_str
		Global.perm_stat_vit = player.stat_vit
		Global.perm_stat_int = player.stat_int
		Global.perm_stat_luk = player.stat_luk
		Global.perm_stat_agi = player.stat_agi
		Global.perm_stat_dex = player.stat_dex

	player._recalculate_elemental_stats()


func _recalculate_elemental_stats():
	player.atk_elements.clear()
	player.def_element = "netral"
	player.def_resistances.clear()
	player.element_dmg_bonus.clear()
	
	if not get_node_or_null("/root/Global"): return
	var item_db = get_node_or_null("/root/ItemDB")
	if not item_db: return
	
	# Get main weapon for player.attack element
	var main_wp_id = Global.equipment.get("main_weapon", "")
	if main_wp_id != "":
		var data = item_db.get_item(main_wp_id)
		var w_elem = data.get("weapon_element", "netral")
		if w_elem != "netral" and w_elem != "":
			player.atk_elements.append(w_elem)
	
	if player.atk_elements.is_empty():
		player.atk_elements.append("netral")
		
	# Get artifact for defense element
	var artifact_id = Global.equipment.get("artifact", "")
	if artifact_id != "":
		var data = item_db.get_item(artifact_id)
		var d_elem = data.get("defense_element", "netral")
		if d_elem != "netral" and d_elem != "":
			player.def_element = d_elem
		
	# Get resistances and dmg bonuses from ALL equipment
	for slot in Global.equipment.keys():
		var item_id = Global.equipment.get(slot, "")
		if item_id != "":
			var data = item_db.get_item(item_id)
			
			var resists = data.get("resistances", {})
			for k in resists.keys():
				if not player.def_resistances.has(k):
					if player.def_resistances.size() < 3: # Max 3 types
						player.def_resistances[k] = 0.0
				if player.def_resistances.has(k):
					player.def_resistances[k] += resists[k]
					if player.def_resistances[k] > 100.0: player.def_resistances[k] = 100.0
					
			var dmg_bonus = data.get("dmg_bonus", {})
			for k in dmg_bonus.keys():
				if not player.element_dmg_bonus.has(k): player.element_dmg_bonus[k] = 0.0
				player.element_dmg_bonus[k] += dmg_bonus[k]
	
	player.emit_signal("health_changed", player.current_health, player.max_health)



func _process(delta):
	if player.is_dead: return
	player.survival_time += delta
	var sm_lvl = Global.unlocked_skills.get("spell_mastery", 0) if get_node_or_null("/root/Global") else 0
	if sm_lvl > 0 and player.current_mana < player.max_mana:
		player.mana_regen_accumulator += float(sm_lvl) * delta
		if player.mana_regen_accumulator >= 1.0:
			var heal_mp = int(player.mana_regen_accumulator)
			player.mana_regen_accumulator -= float(heal_mp)
			player.current_mana += heal_mp
			if player.current_mana > player.max_mana: player.current_mana = player.max_mana
			player.emit_signal("mana_changed", player.current_mana, player.max_mana)
