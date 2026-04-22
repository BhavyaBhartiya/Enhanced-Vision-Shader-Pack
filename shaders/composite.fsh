#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 blur(vec2 uv, float r) {
	vec2 p = r / vec2(viewWidth, viewHeight);
	vec3 c = texture(colortex0, uv).rgb;

	c += texture(colortex0, uv + vec2( p.x, 0.0)).rgb;
	c += texture(colortex0, uv + vec2(-p.x, 0.0)).rgb;
	c += texture(colortex0, uv + vec2(0.0,  p.y)).rgb;
	c += texture(colortex0, uv + vec2(0.0, -p.y)).rgb;

	return c * 0.2;
}

float edge(vec2 uv) {
	vec2 p = 1.0 / vec2(viewWidth, viewHeight);
	float d = texture(depthtex0, uv).r;
	float e = 0.0;

	e += abs(d - texture(depthtex0, uv + vec2( p.x, 0.0)).r);
	e += abs(d - texture(depthtex0, uv + vec2(-p.x, 0.0)).r);
	e += abs(d - texture(depthtex0, uv + vec2(0.0,  p.y)).r);
	e += abs(d - texture(depthtex0, uv + vec2(0.0, -p.y)).r);

	return smoothstep(0.001, 0.01, e);
}

float heatsourcemask(vec3 color) {
	float red = smoothstep(0.55, 0.95, color.r);
	float green = smoothstep(0.15, 0.55, color.g);
	float blue = 1.0 - smoothstep(0.20, 0.45, color.b);
	return red * green * blue;
}

void main() {
	const float sharpixels = 30.0;
	const float blurpixels = 300.0;
	const float bluradius = 6.0;
	const float shimmer = 3.0;

	vec2 p = 1.0 / vec2(viewWidth, viewHeight);

	float heatamount = heatsourcemask(texture(colortex0, texcoord).rgb);
	heatamount = max(heatamount, heatsourcemask(texture(colortex0, texcoord - vec2(0.0, 30.0) * p).rgb));
	heatamount = max(heatamount, heatsourcemask(texture(colortex0, texcoord - vec2(0.0, 60.0) * p).rgb));

	float wave = sin(texcoord.y * 90.0 + frameTimeCounter * 7.0) * heatamount;
	vec2 uv = texcoord + vec2(wave, wave * 0.5) * shimmer * p;

	vec4 sharp = texture(colortex0, uv);

	float dist = length((texcoord - vec2(0.5)) * vec2(viewWidth, viewHeight));
	float bluramount = clamp((dist - sharpixels) / (blurpixels - sharpixels), 0.0, 1.0);

	vec3 final = mix(sharp.rgb, blur(uv, bluradius), bluramount);

	float brightness = dot(final, vec3(0.299, 0.587, 0.114));
	float darkness = 1.0 - smoothstep(0.12, 0.35, brightness);
	float outline = edge(texcoord) * darkness;

	final = mix(final, vec3(0.85, 0.95, 1.0), outline * 0.75);
	color = vec4(final, sharp.a);
}
