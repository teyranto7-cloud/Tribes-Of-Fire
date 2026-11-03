shader_type spatial;
render_mode cull_disabled;
uniform vec2 focus = vec2(0.0);
uniform sampler2D loaded_chunks : filter_nearest, repeat_disable;
uniform float world_extent = 768.0;
varying vec2 location;
void vertex() { location = (MODEL_MATRIX * vec4(VERTEX,1.0)).xz; }
void fragment() {
	vec2 uv = location / (world_extent * 2.0) + vec2(0.5);
	// Only hide fallback terrain after the corresponding playable chunk exists.
	if (texture(loaded_chunks, uv).r > 0.5) discard;
	ALBEDO=COLOR.rgb;
	ROUGHNESS=1.0;
}
