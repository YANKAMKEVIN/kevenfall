shader_type canvas_item;
// Ciel d'orage animé : dégradé + nuages fbm + éclairs.
uniform float flash = 0.0;
uniform float scroll = 0.0;
uniform vec4 top_col : source_color = vec4(0.03, 0.03, 0.10, 1.0);
uniform vec4 mid_col : source_color = vec4(0.14, 0.08, 0.26, 1.0);
uniform vec4 low_col : source_color = vec4(0.10, 0.22, 0.32, 1.0);

float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1,0)), u.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), u.x), u.y);
}
float fbm(vec2 p){ float v=0.0; float a=0.5; for(int i=0;i<5;i++){ v+=a*noise(p); p*=2.03; a*=0.5;} return v; }

void fragment(){
	vec2 uv = UV;
	vec3 col = mix(top_col.rgb, mid_col.rgb, smoothstep(0.0, 0.6, uv.y));
	col = mix(col, low_col.rgb, smoothstep(0.55, 1.0, uv.y));
	vec2 p = vec2(uv.x * 3.0 + scroll * 0.0004 + TIME * 0.008, uv.y * 2.0);
	float c = fbm(p + vec2(0.0, TIME * 0.003));
	float c2 = fbm(p * 1.7 - vec2(TIME * 0.012, 0.0));
	float clouds = smoothstep(0.42, 0.85, c * 0.6 + c2 * 0.5) * (1.0 - smoothstep(0.75, 1.0, uv.y));
	vec3 cloud_col = mix(vec3(0.06, 0.05, 0.14), vec3(0.30, 0.22, 0.45), c2);
	col = mix(col, cloud_col, clouds * 0.85);
	// étoiles dans les trouées
	float st = step(0.997, hash(floor(uv * vec2(640.0, 360.0)))) * (1.0 - clouds) * (1.0 - uv.y);
	col += vec3(st) * (0.5 + 0.5 * sin(TIME * 3.0 + uv.x * 40.0));
	// éclair : illumine le bord des nuages
	col += flash * (vec3(0.55, 0.6, 0.9) * clouds + vec3(0.15, 0.15, 0.25));
	COLOR = vec4(col, 1.0);
}
