shader_type spatial;
render_mode cull_back;

uniform float u_rotation_speed;
uniform float u_time;
uniform float u_cube_size;
uniform float u_N;

vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289_4(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289_4(((x * 34.0) + 1.0) * x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) {
	const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
	const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

	vec3 i = floor(v + dot(v, C.yyy));
	vec3 x0 = v - i + dot(i, C.xxx);

	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min(g.xyz, l.zxy);
	vec3 i2 = max(g.xyz, l.zxy);

	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy;
	vec3 x3 = x0 - D.yyy;

	i = mod289(i);
	vec4 p = permute(permute(permute(
			 i.z + vec4(0.0, i1.z, i2.z, 1.0))
		   + i.y + vec4(0.0, i1.y, i2.y, 1.0))
		   + i.x + vec4(0.0, i1.x, i2.x, 1.0));

	float n_ = 0.142857142857;
	vec3 ns = n_ * D.wyz - D.xzx;

	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_);

	vec4 x = x_ * ns.x + ns.yyyy;
	vec4 y = y_ * ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);

	vec4 b0 = vec4(x.xy, y.xy);
	vec4 b1 = vec4(x.zw, y.zw);

	vec4 s0 = floor(b0) * 2.0 + 1.0;
	vec4 s1 = floor(b1) * 2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));

	vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
	vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

	vec3 p0 = vec3(a0.xy, h.x);
	vec3 p1 = vec3(a0.zw, h.y);
	vec3 p2 = vec3(a1.xy, h.z);
	vec3 p3 = vec3(a1.zw, h.w);

	vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;

	vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
	m = m * m;
	return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

varying vec3 v_world_pos;
varying float v_displacement;

void vertex() {
	vec3 v = VERTEX;
	vec3 n = NORMAL;
	float s = 0.5 / u_N;

	float ix = floor(v.x * s + n.y * 0.5);
	float iy = floor(v.y * s + n.z * 0.5);
	float iz = floor(v.z * s + n.x * 0.5);

	vec3 noise_coord = vec3(ix, iy, iz);
	float time_scale = u_time * 0.5;

	float k1 = 2.0 * snoise(noise_coord + vec3(0.0, 0.0, time_scale));
	float k = (4.0 * abs(k1) - 0.5);

	float CUTY = 1.5 * u_N - 1.0;
	float CUTXZ = 1.5 * u_N - 1.0;

	if (abs(n.x) > 0.5 && (abs(v.y) > CUTY || abs(v.z) > CUTXZ)) k = 0.0;
	if (abs(n.y) > 0.5 && (abs(v.x) > CUTXZ || abs(v.z) > CUTXZ)) k = 0.0;
	if (abs(n.z) > 0.5 && (abs(v.x) > CUTXZ || abs(v.y) > CUTY)) k = 0.0;

	VERTEX += NORMAL * (5.0 * k);
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_displacement = k;
}

void fragment() {
	vec3 pos = v_world_pos * 0.05;
	float noise_val = snoise(pos + vec3(0.0, 0.0, u_time * u_rotation_speed));
	float raw_pattern = cos(pos.y * 1.0 + noise_val * 9.0);
	float marble_pattern = raw_pattern * 0.3 + 0.6;

	vec3 color_navy = vec3(0.0, 0.0, 0.5);
	vec3 color_white = vec3(1.0, 1.0, 1.0);

	float mix_factor = smoothstep(0.2, 0.7, marble_pattern);
	ALBEDO = mix(color_navy, color_white, mix_factor);
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}