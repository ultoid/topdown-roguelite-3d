shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Tekstur asli karakter (T_ColorMap.png)
uniform sampler2D albedo_texture : source_color, filter_nearest;

// Pengaturan penggantian warna
uniform vec4 original_color : source_color = vec4(0.8, 0.15, 0.15, 1.0); // Warna merah bawaan (contoh)
uniform vec4 new_color : source_color = vec4(0.0, 0.5, 1.0, 1.0); // Warna biru (warna pengganti)
uniform float tolerance : hint_range(0.0, 1.0) = 0.15; // Toleransi kemiripan warna (agar warna bayangan/pinggiran juga ikut berubah)

void fragment() {
	// Ambil warna pixel dari tekstur T_ColorMap
	vec4 tex_color = texture(albedo_texture, UV);
	
	// Hitung jarak (kemiripan) antara warna di tekstur dengan warna merah asli
	float dist = distance(tex_color.rgb, original_color.rgb);
	
	// Jika warna pixel mirip dengan original_color (sesuai nilai tolerance)
	if (dist < tolerance) {
		// Ganti warnanya dengan warna baru
		ALBEDO = new_color.rgb;
	} else {
		// Jika tidak, gunakan warna aslinya
		ALBEDO = tex_color.rgb;
	}
}
