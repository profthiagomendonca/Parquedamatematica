shader_type canvas_item;

uniform float threshold : hint_range(0.0, 1.0) = 0.95;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	// Se a cor for muito próxima do branco, tornamos transparente
	if (col.r > threshold && col.g > threshold && col.b > threshold) {
		col.a = 0.0;
	}
	COLOR = col;
}
