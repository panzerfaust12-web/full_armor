shader_type canvas_item;

uniform vec4 color: source_color;
uniform sampler2D fast_noise: repeat_enable;
uniform sampler2D screen_content: hint_screen_texture;
uniform vec2 speed = vec2(0.03,0.07);
uniform float wave_strength = 2.0;

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 uv = UV + speed * TIME;
	vec2 noise = texture(fast_noise, uv).rg * 2.0 - 1.0;
	vec3 noise_dist = texture(fast_noise, uv).rgb * 2.0 - 1.0;
	
	vec2 distortion = noise * (wave_strength / 100.0);
	
	vec2 adj_uv = clamp(SCREEN_UV + distortion, vec2(0.0), vec2(1.0));
	
	adj_uv -= 0.5;
	adj_uv *= 0.98;
	adj_uv += 0.5;
	
	COLOR = vec4(color.r,color.g,color.b, 1.0); //+ vec4(noise.y / 2.0, noise.x / 2.0, noise_dist.z / 2.0,1.0);
	COLOR *= texture(screen_content, adj_uv + noise * (wave_strength / 100.0));
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
