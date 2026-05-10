shader_type canvas_item;

uniform float burn_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float gray_mult : hint_range(0.0, 1.0) = 0.35;
uniform float alpha_drain : hint_range(0.0, 1.0) = 0.9;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.05) {
		discard;
	}

	float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 dark_tint = mix(vec3(0.3, 0.2, 0.15), tex.rgb, gray_mult);
	COLOR.rgb = dark_tint * gray * (1.0 - burn_intensity * 0.3);
	COLOR.rgb += vec3(0.1, 0.04, 0.0) * burn_intensity * gray;
	COLOR.a = tex.a * alpha_drain;
}
