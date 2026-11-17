// The avatar seen from behind (Milestone 19, placeholder): every drawn pixel becomes the
// silhouette colour, keeping only the picture's outline (its transparency).
shader_type canvas_item;

uniform vec4 silhouette_color : source_color = vec4(0.2, 0.19, 0.24, 1.0);

void fragment() {
	COLOR = vec4(silhouette_color.rgb, COLOR.a);
}
