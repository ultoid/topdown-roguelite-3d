extends CanvasLayer

var color_rect: ColorRect
var target: Node3D

func _ready():
	print("--- BLIND OVERLAY CREATED AND READY ---")
	layer = 0
	color_rect = ColorRect.new()
	add_child(color_rect)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.15;
uniform float feather = 0.1;
uniform float aspect = 1.777;
uniform vec4 base_color : source_color = vec4(0.0, 0.0, 0.0, 0.98);

void fragment() {
	vec2 uv = UV;
	uv.x *= aspect;
	vec2 c = center;
	c.x *= aspect;
	
	float dist = distance(uv, c);
	float alpha = smoothstep(radius, radius + feather, dist);
	COLOR = vec4(base_color.rgb, base_color.a * alpha);
}
"""
	mat.shader = shader
	color_rect.material = mat

func setup(t: Node3D):
	target = t

func _process(_delta):
	if not is_instance_valid(target):
		queue_free()
		return
		
	var cam = target.get_viewport().get_camera_3d()
	if cam:
		var screen_pos = cam.unproject_position(target.global_position)
		var viewport_size = target.get_viewport_rect().size
		var normalized_pos = screen_pos / viewport_size
		var aspect_ratio = viewport_size.x / viewport_size.y
		
		color_rect.position = Vector2.ZERO
		color_rect.size = viewport_size
		
		if color_rect.material:
			color_rect.material.set_shader_parameter("center", normalized_pos)
			color_rect.material.set_shader_parameter("aspect", aspect_ratio)
