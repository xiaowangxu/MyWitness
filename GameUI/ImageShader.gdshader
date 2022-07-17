shader_type canvas_item;
uniform float black_range_a = -0.713;
uniform float black_range_b = 1.106;
uniform float pow_factor = 4.0;
uniform float black_factor = 0.489;
uniform sampler2D a;
uniform sampler2D b;

void fragment() {
	vec2 base_uv = UV;
	vec2 transformed_uv = (base_uv - vec2(0.5)) * 2.0;
	float _dis = pow(abs(transformed_uv.x), pow_factor) + pow(abs(transformed_uv.y), pow_factor);
	float dis = smoothstep(black_range_a, black_range_b, 1.0 - _dis) * (1.0 - black_factor) + black_factor;
	COLOR = vec4(dis, dis, dis, 1.0);
}