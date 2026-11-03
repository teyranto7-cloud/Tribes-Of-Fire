shader_type spatial;
render_mode cull_disabled;
uniform vec2 focus = vec2(0.0);
varying vec2 location;
void vertex() { location = (MODEL_MATRIX * vec4(VERTEX,1.0)).xz; }
void fragment() {
	if (distance(location,focus)<43.0) discard;
	ALBEDO=COLOR.rgb;
	ROUGHNESS=1.0;
}
