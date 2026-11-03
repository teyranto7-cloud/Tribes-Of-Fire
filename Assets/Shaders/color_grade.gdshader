shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
void fragment() {
	vec4 source = texture(screen_texture, SCREEN_UV);
	vec3 toned = mix(vec3(dot(source.rgb, vec3(0.2126, 0.7152, 0.0722))), source.rgb, 1.05);
	float edge = smoothstep(0.28, 0.82, length(SCREEN_UV - vec2(0.5)));
	COLOR = vec4(toned * (1.0 - edge * 0.09), 1.0);
}
