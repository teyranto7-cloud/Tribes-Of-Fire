shader_type spatial;
render_mode cull_disabled;
void fragment() {
	float streak = sin(UV.x*37.0 + sin(UV.y*14.0-TIME*6.0))*0.5+0.5;
	ALBEDO = mix(vec3(0.2,0.52,0.57),vec3(0.78,0.91,0.85),streak);
	ROUGHNESS = 0.3;
	ALPHA = 0.65 + streak*0.25;
}
