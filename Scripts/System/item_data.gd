extends Sprite2D
class_name ItemData

@export var item_name: String = ""
@export_multiline var description: String = ""
@export_enum("material", "consumable", "equipment", "upgrade_item", "key_item") var type: String = "consumable"
@export_enum("common", "rare", "epic", "legendary", "mythic") var rarity: String = "common"
@export var price: int = 0

@export_group("Consumable Effect")
@export_enum("None", "heal_hp", "heal_mp", "heal_ep", "unlock_recipe") var effect_type: String = "None"
@export var effect_amount: int = 0
@export var recipe_id: String = ""

@export_group("Equipment Stats")
@export_enum("None", "main_weapon", "secondary_weapon", "helm", "armor", "boots", "accessory", "artifact") var equipment_slot: String = "None"
@export_enum("None", "long_sword", "sword", "gloves", "lance", "staff", "rune", "long_bow", "crossbow", "dagger") var weapon_type: String = "None"
@export_file("*.tscn") var weapon_scene_path: String = ""
@export var bonus_p_atk: int = 0
@export var bonus_p_def: int = 0
@export var bonus_str: int = 0
@export var bonus_int: int = 0
@export var bonus_max_hp: int = 0
@export var bonus_max_mp: int = 0

@export_group("Elemental Attributes")
@export_enum("netral", "api", "air", "tanah", "udara", "listrik", "es", "besi", "suara", "cahaya", "kegelapan") var weapon_element: String = "netral"
@export_enum("netral", "api", "air", "tanah", "udara", "listrik", "es", "besi", "suara", "cahaya", "kegelapan") var defense_element: String = "netral"

@export_group("Elemental Resistances (%)")
@export var resist_api: float = 0.0
@export var resist_air: float = 0.0
@export var resist_tanah: float = 0.0
@export var resist_udara: float = 0.0
@export var resist_listrik: float = 0.0
@export var resist_es: float = 0.0
@export var resist_besi: float = 0.0
@export var resist_suara: float = 0.0
@export var resist_cahaya: float = 0.0
@export var resist_kegelapan: float = 0.0

@export_group("Elemental Damage Bonus (%)")
@export var bonus_dmg_api: float = 0.0
@export var bonus_dmg_air: float = 0.0
@export var bonus_dmg_tanah: float = 0.0
@export var bonus_dmg_udara: float = 0.0
@export var bonus_dmg_listrik: float = 0.0
@export var bonus_dmg_es: float = 0.0
@export var bonus_dmg_besi: float = 0.0
@export var bonus_dmg_suara: float = 0.0
@export var bonus_dmg_cahaya: float = 0.0
@export var bonus_dmg_kegelapan: float = 0.0

@export_group("Crafting Recipe")
@export var is_craftable: bool = false
@export var craft_time: float = 2.0
@export var req_mat_1: String = ""
@export var req_amount_1: int = 0
@export var req_mat_2: String = ""
@export var req_amount_2: int = 0
@export var req_mat_3: String = ""
@export var req_amount_3: int = 0
