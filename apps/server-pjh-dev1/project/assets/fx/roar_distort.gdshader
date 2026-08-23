shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0);
uniform float strength = 0.09;
uniform vec4 ring_color : source_color = vec4(1.0, 0.78, 0.18, 1.0);
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

void fragment() {
	vec2 from = UV - vec2(0.5);
	float d = length(from) * 2.0;
	float front = clamp(progress, 0.0, 1.0);
	vec2 dir = from / max(length(from), 0.0001);
	float rim = smoothstep(front - 0.07, front, d) * (1.0 - smoothstep(front, front + 0.05, d));
	float inside = 1.0 - smoothstep(front - 0.02, front + 0.01, d);
	float rip = sin((d - front) * 48.0 - progress * 10.0) * strength * rim * 1.6;
	vec4 scene = texture(screen_tex, SCREEN_UV + dir * rip);
	vec3 col = scene.rgb;
	col = mix(col, ring_color.rgb, inside * 0.18 * (1.0 - progress * 0.35));
	col = mix(col, vec3(1.0, 0.93, 0.45), rim * 0.92);
	float a = max(inside * 0.22, rim);
	if (d > 1.02) {
		discard;
	}
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
