shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float density = 0.25;
uniform vec4 tint : source_color = vec4(0.84, 0.87, 0.81, 1.0);
float clouds(vec2 p) {
	float a = sin(p.x * 0.14 + sin(p.y * 0.09)) * cos(p.y * 0.11);
	float b = sin(p.x * 0.31 + p.y * 0.2) * cos(p.y * 0.27 - p.x * 0.13);
	return a * 0.34 + b * 0.13 + 0.5;
}
void fragment() {
	vec2 p = UV * 300.0 + vec2(TIME * 0.32, TIME * 0.12);
	float coverage = smoothstep(0.72 - density * 0.45, 0.86 - density * 0.35, clouds(p));
	float border = 1.0 - smoothstep(0.28, 0.5, length(UV - vec2(0.5)));
	ALBEDO = tint.rgb;
	ALPHA = coverage * border * clamp(density * 1.8, 0.0, 0.88);
}
