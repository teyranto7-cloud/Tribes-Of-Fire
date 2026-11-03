shader_type spatial;
render_mode cull_disabled;
uniform vec4 water_color : source_color = vec4(0.18, 0.43, 0.48, 0.84);
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float rain = 0.0;
uniform int detail = 1;
varying vec2 world_uv;
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_uv = world.xz;
	VERTEX.y += sin(world.x * 0.34 + TIME * 0.8) * cos(world.z * 0.25 + TIME * 0.6) * (detail > 0 ? 0.035 : 0.0);
}
void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec4 ground = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
	ground.xyz /= max(abs(ground.w), 0.0001);
	float thickness = max(0.0, -ground.z + VERTEX.z);
	float deep = smoothstep(0.0, 5.0, thickness);
	float foam = (1.0 - smoothstep(0.04, 0.35, thickness)) * (0.5 + 0.5 * sin(world_uv.x * 2.1 + world_uv.y * 1.8 + TIME * 1.5));
	ALBEDO = mix(mix(vec3(0.30, 0.57, 0.50), water_color.rgb * 0.75, deep), vec3(0.72, 0.83, 0.72), foam * 0.45);
	METALLIC = 0.35;
	ROUGHNESS = mix(0.12, 0.29, rain);
	vec2 wave = vec2(sin(world_uv.x * 1.3 + TIME * 1.2), cos(world_uv.y * 1.1 + TIME));
	NORMAL_MAP = vec3(wave * (0.04 + rain * 0.035) + 0.5, 1.0);
	NORMAL_MAP_DEPTH = detail == 0 ? 0.0 : (detail == 1 ? 0.3 : 0.55);
	ALPHA = mix(0.25, water_color.a, deep);
}
