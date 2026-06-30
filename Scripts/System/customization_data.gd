extends Node
class_name CustomizationData

@export var part_name: String = ""
@export_enum("Hair", "Beard") var part_type: String = "Hair"
@export_file("*.fbx", "*.tscn", "*.res") var mesh_path: String = ""
@export var species: String = "Humans"

@export_group("Transform Offsets")
@export var position_offset: Vector3 = Vector3.ZERO
@export var rotation_offset: Vector3 = Vector3.ZERO
@export var scale_offset: Vector3 = Vector3.ONE
