shader_type spatial;
render_mode cull_disabled;
uniform int style = 0;
void fragment() {
	vec2 p = UV * vec2(4.0, 5.0);
	vec2 cell = floor(p);
	float seed = fract(sin(dot(cell, vec2(127.1,311.7))) * 43758.5453);
	float spot = length(fract(p) - vec2(0.35 + seed * 0.25, 0.4));
	vec3 base = vec3(0.40,0.28,0.17);
	if (style == 1) base = vec3(0.32,0.36,0.34);
	if (style == 2) base = vec3(0.29,0.19,0.12);
	if (style == 3) base = vec3(0.48,0.31,0.17);
	if (style == 4) base = vec3(0.43,0.47,0.22);
	if (style == 5) base = vec3(0.33,0.23,0.15);
	float marking = style == 0 ? smoothstep(0.25,0.14,spot)*0.35 : 0.0;
	ALBEDO = mix(base * (0.92 + seed * 0.12), vec3(0.13,0.085,0.045), marking);
	ROUGHNESS = 0.92;
}
