#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
    #define PRECISION highp
#else
    #define PRECISION mediump
#endif

extern PRECISION vec2 sword_params; 
extern PRECISION number dissolve;
extern PRECISION number time;
extern PRECISION vec4 texture_details;
extern PRECISION vec2 image_details;
extern bool shadow;
extern PRECISION vec4 burn_colour_1;
extern PRECISION vec4 burn_colour_2;


float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}


vec3 starField(vec2 uv, float t) {
    vec3 col = vec3(0.0);
    uv *= 10.0;
    vec2 grid = floor(uv);
    vec2 gridUV = fract(uv);
    float brightness = rand(grid + vec2(t * 0.1));
    
    if (brightness > 0.95) {
        float star = smoothstep(0.5, 0.0, length(gridUV - 0.5));
        star *= 0.7 + 0.3 * sin(t * 5.0 + grid.x * 10.0 + grid.y * 7.0);
        col = vec3(star) * vec3(1.0, 0.7, 0.3);
    }
    return col * sword_params.x * 0.5;
}


float swordSDF(vec2 uv, float size) {
    uv /= size;
    float blade = max(abs(uv.x) - 0.015, uv.y - 0.5);
    float crossguard = max(abs(uv.x) - 0.1, abs(uv.y) - 0.05);
    float pommel = length(uv - vec2(0.0, -0.55)) - 0.05;
    return min(min(blade, crossguard), pommel);
}


vec3 getSwordData(float index) {
    float seed = index * 123.456;
    float xPos = rand(vec2(seed, 1.0)) * 2.0 - 1.0;
    float yPos = mod(time * 0.3 + seed, 2.0) - 0.5;
    float size = 0.3 + rand(vec2(seed, 3.0)) * 0.2;
    return vec3(xPos, yPos, size);
}


vec4 dissolve_mask(vec4 tex, vec2 texture_coords, vec2 uv) {
    if (dissolve < 0.001) {
        return vec4(shadow ? vec3(0.0) : tex.rgb, shadow ? tex.a * 0.3 : tex.a);
    }

    float adjusted = (dissolve * dissolve * (3.0 - 2.0 * dissolve)) * 1.02 - 0.01;
    float t = time * 10.0 + 2003.0;

    vec2 floored_uv = floor(uv * texture_details.ba) / max(texture_details.b, texture_details.a);
    vec2 scaled = (floored_uv - 0.5) * 2.3 * max(texture_details.b, texture_details.a);

    vec2 f1 = scaled + 50.0 * vec2(sin(-t / 143.63), cos(-t / 99.43));
    vec2 f2 = scaled + 50.0 * vec2(cos(t / 53.15), cos(t / 61.45));
    vec2 f3 = scaled + 50.0 * vec2(sin(-t / 87.53), sin(-t / 49.0));

    float field = (1.0 + (
        cos(length(f1) / 19.48) +
        sin(length(f2) / 33.15) * cos(f2.y / 15.73) +
        cos(length(f3) / 27.19) * sin(f3.x / 21.92)
    )) / 2.0;

    float borders = smoothstep(0.2, 0.8, floored_uv.x) * smoothstep(0.2, 0.8, floored_uv.y);
    float noise = 0.5 + 0.5 * cos((adjusted) / 82.61 + (field - 0.5) * 3.14);
    float res = noise * borders;

    bool burn = tex.a > 0.01 && burn_colour_1.a > 0.01 && !shadow &&
                res < adjusted + 0.8 * (0.5 - abs(adjusted - 0.5)) &&
                res > adjusted;

    if (burn) {
        tex.rgba = res < adjusted + 0.5 * (0.5 - abs(adjusted - 0.5)) ? burn_colour_1.rgba :
                  (burn_colour_2.a > 0.01 ? burn_colour_2.rgba : tex.rgba);
    }

    float finalAlpha = (res > adjusted) ? (shadow ? tex.a * 0.3 : tex.a) : 0.0;
    return vec4(shadow ? vec3(0.0) : tex.rgb, finalAlpha);
}


vec4 renderSword(vec4 tex, vec2 uv, float index) {
    if (sword_params.x < 0.01) return tex;
    
    vec3 swordData = getSwordData(index);
    vec2 swordPos = vec2(swordData.x, swordData.y);
    float swordSize = swordData.z;
    
    float dist = swordSDF(uv - swordPos, swordSize);
    float outline = smoothstep(0.03, 0.01, abs(dist));
    vec3 outlineColor = vec3(1.0, 0.5, 0.1) * outline * sword_params.x;
    
    if (outline > 0.01) {
        vec2 starUV = (uv - swordPos) * 20.0 + vec2(time * 0.5);
        outlineColor += starField(starUV, time) * 2.0;
    }
    
    tex.rgb = mix(tex.rgb, outlineColor, outline);
    return tex;
}


vec3 applyOrangeGlow(vec3 color, vec2 uv) {
    float glowIntensity = sword_params.x;
    vec2 center = vec2(0.5);
    float dist = length(uv - center);
    
    float outerGlow = smoothstep(0.6, 0.0, dist);
    float innerGlow = smoothstep(0.3, 0.0, dist);
    float pulse = 0.6 + 0.4 * sin(time * 3.0 + dist * 20.0);
    
    vec3 orange = vec3(1.0, 0.45, 0.1);
    vec3 glow = orange * (outerGlow * 0.4 + innerGlow * 0.3 * pulse) * glowIntensity;
    
    vec2 starUV = uv * 10.0 + vec2(time * 0.3, time * 0.2);
    glow += starField(starUV, time) * 0.7;
    
    return color + glow;
}


vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 tex = Texel(texture, texture_coords);
    vec2 uv = ((texture_coords * image_details) - texture_details.xy * texture_details.ba) / texture_details.ba;
    
    tex.rgb = applyOrangeGlow(tex.rgb, uv);
    
    for (float i = 0.0; i < 3.0; i++) {
        tex = renderSword(tex, uv, i);
    }
    
    return dissolve_mask(tex * colour, texture_coords, uv);
}


extern PRECISION vec2 mouse_screen_pos;
extern PRECISION float hovering;
extern PRECISION float screen_scale;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
    if (hovering <= 0.0) return transform_projection * vertex_position;

    float mid_dist = length(vertex_position.xy - 0.5 * love_ScreenSize.xy) / length(love_ScreenSize.xy);
    vec2 offset = (vertex_position.xy - mouse_screen_pos.xy) / screen_scale;
    float strength = 0.25 * (-0.03 - 0.3 * max(0.0, 0.3 - mid_dist));

    float effect = strength * hovering * length(offset) * length(offset) / (2.0 - mid_dist);
    return transform_projection * vertex_position + vec4(0.0, 0.0, 0.0, effect);
}
#endif