shader_type spatial;
render_mode cull_disabled;
uniform vec2 focus=vec2(0.0);
uniform float far_limit=430.0;
varying vec2 tree_position;
void vertex(){ tree_position=(MODEL_MATRIX*vec4(0.0,0.0,0.0,1.0)).xz; }
void fragment(){
	float d=distance(tree_position,focus);
	if(d<40.0 || d>far_limit)discard;
	ALBEDO=COLOR.rgb;
	ROUGHNESS=1.0;
}
