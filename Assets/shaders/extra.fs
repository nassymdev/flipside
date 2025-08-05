#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
    #define PRECISION highp
#else
    #define PRECISION mediump
#endif


extern PRECISION vec2 extra;
extern PRECISION number dissolve;
extern PRECISION number time;
extern PRECISION vec4 texture_details;
extern PRECISION vec2 image_details;
extern bool shadow;
extern PRECISION vec4 burn_colour_1;
extern PRECISION vec4 burn_colour_2;


vec4 dissolve_mask(vec4 tex, vec2 texture_coords, vec2 uv);




vec3 rgbShift(Image tex, vec2 uv, vec3 color, float intensity) {
    float shift = 0.01 * intensity * (0.5 + 0.5 * sin(time * 2.0));
    vec3 r = Texel(tex, uv + vec2(shift, 0.0)).rgb;
    vec3 g = Texel(tex, uv).rgb;
    vec3 b = Texel(tex, uv - vec2(shift, 0.0)).rgb;
    return vec3(r.r, g.g, b.b);
}


vec3 applyNeonGlow(vec3 color, vec2 uv, float t) {
    float glowIntensity = 0.5 + 0.5 * sin(t * 1.5 + uv.x * 10.0);
    vec3 neonColor = mix(
        vec3(0.3, 0.8, 1.0),  
        vec3(1.0, 0.2, 0.8),  
        sin(t * 0.7) * 0.5 + 0.5
    );
    return color + neonColor * glowIntensity * extra.r * 0.5;
}


vec3 applyScanlines(vec3 color, vec2 uv, float t) {
    
    float scanline = sin(uv.y * 800.0 + t * 5.0) * 0.1;
    
    float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453 + t);
    noise = noise * 0.1;
    return color * (1.0 - scanline) + noise * 0.05;
}


vec2 distortUV(vec2 uv, float t) {
    float distortion = 0.02 * extra.g;
    uv.x += sin(t + uv.y * 5.0) * distortion;
    uv.y += cos(t + uv.x * 5.0) * distortion;
    return uv;
}


vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = (((texture_coords)*(image_details)) - texture_details.xy*texture_details.ba)/texture_details.ba;
    uv = distortUV(uv, time * 2.0); 
    
    vec4 tex = Texel(texture, texture_coords);
    if (tex.a == 0.0) return vec4(0.0);

    
    vec3 color = tex.rgb;
    float t = time * 2.0 + extra.g * 10.0;
    
    
    color = rgbShift(texture, texture_coords, color, extra.r);
    color = applyNeonGlow(color, uv, t);
    color = applyScanlines(color, uv, t);
    
    
    float edge = smoothstep(0.8, 1.0, length(uv - 0.5));
    color += edge * vec3(0.5, 0.7, 1.0) * (0.5 + 0.5 * sin(t));

    
    tex.rgb = mix(tex.rgb, color, 0.7 + 0.3 * extra.r);

    
    return dissolve_mask(tex * colour, texture_coords, uv);
}


vec4 dissolve_mask(vec4 tex, vec2 texture_coords, vec2 uv) {
    if (dissolve < 0.001) {
        return vec4(shadow ? vec3(0.,0.,0.) : tex.xyz, shadow ? tex.a*0.3: tex.a);
    }

    float adjusted_dissolve = (dissolve*dissolve*(3.-2.*dissolve))*1.02 - 0.01;
    float t = time * 10.0 + 2003.;
    vec2 floored_uv = (floor((uv*texture_details.ba)))/max(texture_details.b, texture_details.a);
    vec2 uv_scaled_centered = (floored_uv - 0.5) * 2.3 * max(texture_details.b, texture_details.a);
    
    vec2 field_part1 = uv_scaled_centered + 50.*vec2(sin(-t / 143.6340), cos(-t / 99.4324));
    vec2 field_part2 = uv_scaled_centered + 50.*vec2(cos( t / 53.1532),  cos( t / 61.4532));
    vec2 field_part3 = uv_scaled_centered + 50.*vec2(sin(-t / 87.53218), sin(-t / 49.0000));

    float field = (1.+ (
        cos(length(field_part1) / 19.483) + sin(length(field_part2) / 33.155) * cos(field_part2.y / 15.73) +
        cos(length(field_part3) / 27.193) * sin(field_part3.x / 21.92) ))/2.;
    vec2 borders = vec2(0.2, 0.8);

    float res = (.5 + .5* cos( (adjusted_dissolve) / 82.612 + ( field + -.5 ) *3.14))
    - (floored_uv.x > borders.y ? (floored_uv.x - borders.y)*(5. + 5.*dissolve) : 0.)*(dissolve)
    - (floored_uv.y > borders.y ? (floored_uv.y - borders.y)*(5. + 5.*dissolve) : 0.)*(dissolve)
    - (floored_uv.x < borders.x ? (borders.x - floored_uv.x)*(5. + 5.*dissolve) : 0.)*(dissolve)
    - (floored_uv.y < borders.x ? (borders.x - floored_uv.y)*(5. + 5.*dissolve) : 0.)*(dissolve);

    if (tex.a > 0.01 && burn_colour_1.a > 0.01 && !shadow && res < adjusted_dissolve + 0.8*(0.5-abs(adjusted_dissolve-0.5)) && res > adjusted_dissolve) {
        if (!shadow && res < adjusted_dissolve + 0.5*(0.5-abs(adjusted_dissolve-0.5)) && res > adjusted_dissolve) {
            tex.rgba = burn_colour_1.rgba;
        } else if (burn_colour_2.a > 0.01) {
            tex.rgba = burn_colour_2.rgba;
        }
    }

    return vec4(shadow ? vec3(0.,0.,0.) : tex.xyz, res > adjusted_dissolve ? (shadow ? tex.a*0.3: tex.a) : .0);
}


#ifdef VERTEX
extern PRECISION vec2 mouse_screen_pos;
extern PRECISION float hovering;
extern PRECISION float screen_scale;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    if (hovering <= 0.){
        return transform_projection * vertex_position;
    }
    float mid_dist = length(vertex_position.xy - 0.5*love_ScreenSize.xy)/length(love_ScreenSize.xy);
    vec2 mouse_offset = (vertex_position.xy - mouse_screen_pos.xy)/screen_scale;
    float scale = 0.2*(-0.03 - 0.3*max(0., 0.3-mid_dist))
                *hovering*(length(mouse_offset)*length(mouse_offset))/(2. -mid_dist);

    return transform_projection * vertex_position + vec4(0,0,0,scale);
}
#endif