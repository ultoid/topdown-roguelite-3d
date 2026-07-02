shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform float tolerance : hint_range(0.0, 1.0) = 0.15;

// Target colors (The colors in the original T_ColorMap.png that we want to replace)
uniform vec4 target_color_1 : source_color = vec4(1.0, 0.77, 0.58, 1.0); // E.g., Skin
uniform vec4 target_color_2 : source_color = vec4(0.24, 0.16, 0.12, 1.0); // E.g., Hair
uniform vec4 target_color_3 : source_color = vec4(0.8, 0.15, 0.15, 1.0); // E.g., Red/Eyes
uniform vec4 target_color_4 : source_color = vec4(0.2, 0.3, 0.8, 1.0); // E.g., Clothes

// Replacement colors (The new colors chosen by the user)
uniform vec4 new_color_1 : source_color = vec4(1.0, 0.77, 0.58, 1.0);
uniform vec4 new_color_2 : source_color = vec4(0.24, 0.16, 0.12, 1.0);
uniform vec4 new_color_3 : source_color = vec4(0.8, 0.15, 0.15, 1.0);
uniform vec4 new_color_4 : source_color = vec4(0.2, 0.3, 0.8, 1.0);

void fragment() {
	vec4 tex_color = texture(albedo_texture, UV);
	
	float dist1 = distance(tex_color.rgb, target_color_1.rgb);
	float dist2 = distance(tex_color.rgb, target_color_2.rgb);
	float dist3 = distance(tex_color.rgb, target_color_3.rgb);
	float dist4 = distance(tex_color.rgb, target_color_4.rgb);
	
	if (dist1 < tolerance) {
		ALBEDO = new_color_1.rgb;
	} else if (dist2 < tolerance) {
		ALBEDO = new_color_2.rgb;
	} else if (dist3 < tolerance) {
		ALBEDO = new_color_3.rgb;
	} else if (dist4 < tolerance) {
		ALBEDO = new_color_4.rgb;
	} else {
		ALBEDO = tex_color.rgb;
	}
}
