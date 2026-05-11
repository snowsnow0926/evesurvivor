shader_type canvas_item;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(gray * 0.6, gray * 0.6, gray * 0.7, tex_color.a);
}
