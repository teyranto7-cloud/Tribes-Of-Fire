shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(0.22, 0.45, 0.24, 1.0);
uniform float wind = 0.2;
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float sway = sin(TIME * 1.4 + world.x * 0.9 + world.z * 0.5);
	VERTEX.x += sway * wind * clamp(VERTEX.y + 0.5, 0.0, 2.0) * 0.12;
	VERTEX.z += cos(TIME * 1.1 + world.x) * wind * 0.035;
}
void fragment() {
	ALBEDO = tint.rgb * COLOR.rgb;
	ROUGHNESS = 0.92;
}
