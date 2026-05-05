shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 0.3, 0.3, 1.0);
uniform float saturation_mult : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

	vec4 tint = tint_color * saturation_mult;
	COLOR.rgb = tint.rgb * gray;
	COLOR.a = tex.a;
}
