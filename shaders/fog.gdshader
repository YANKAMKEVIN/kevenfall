shader_type canvas_item;
// Brume qui ondule (bandes de brouillard violet/cyan).
uniform vec4 tint : source_color = vec4(0.55, 0.45, 0.85, 1.0);
uniform float density = 0.6;
uniform float speed = 0.03;
float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p){ vec2 i=floor(p); vec2 f=fract(p); vec2 u=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),u.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),u.x),u.y); }
float fbm(vec2 p){ float v=0.0; float a=0.5; for(int i=0;i<4;i++){ v+=a*noise(p); p*=2.1; a*=0.5;} return v; }
void fragment(){
	vec2 p = UV * vec2(4.0, 1.5);
	float n = fbm(p + vec2(TIME * speed, 0.0)) * 0.7 + fbm(p * 2.0 - vec2(TIME * speed * 1.7, 0.0)) * 0.4;
	float a = smoothstep(0.35, 0.9, n) * density * smoothstep(0.0, 0.35, UV.y) * smoothstep(1.0, 0.7, UV.y);
	COLOR = vec4(tint.rgb + vec3(0.1, 0.3, 0.3) * fbm(p * 3.0), a);
}
