#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
    #define PRECISION highp
#else
    #define PRECISION mediump
#endif

// Inherit all extern variables
extern PRECISION vec2 cloud;
extern PRECISION number dissolve;
extern PRECISION number time;
extern PRECISION vec4 texture_details;
extern PRECISION vec2 image_details;
extern bool shadow;
extern PRECISION vec4 burn_colour_1;
extern PRECISION vec4 burn_colour_2;

// Required function
vec4 dissolve_mask(vec4 tex, vec2 texture_coords, vec2 uv);

// --- CUSTOM FUNCTIONS ---

// Simple noise function for clouds
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Fractional Brownian Motion (fBm) for cloud-like patterns
float fbm(vec2 uv, int octaves) {
    float total = 0.0;
    float frequency = 1.0;
    float amplitude = 0.5;
    
    for (int i = 0; i < octaves; i++) {
        total += noise(uv * frequency) * amplitude;
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return total;
}

// Cloud generation
vec3 applyClouds(vec2 uv, float t) {
    // Animate UVs for drifting clouds
    vec2 cloudUV = uv * 3.0 + vec2(t * 0.1, t * 0.05);
    
    // Generate layered noise for clouds
    float clouds = fbm(cloudUV, 4);
    clouds = smoothstep(0.3, 0.9, clouds); // Soften edges
    
    // Color the clouds (soft white with blue/pink tint)
    vec3 cloudColor = mix(
        vec3(0.9, 0.95, 1.0),  // Soft blue-white
        vec3(1.0, 0.9, 0.95),   // Soft pink
        sin(t * 0.5) * 0.5 + 0.5
    );
    
    return cloudColor * clouds * cloud.r * 0.5;
}

// Soft glow effect
vec3 applyGlow(vec3 color, vec2 uv, float t) {
    float glow = 0.5 + 0.5 * sin(t + uv.x * 5.0);
    return color + glow * 0.2 * vec3(0.7, 0.8, 1.0);
}

// Gentle UV distortion (like heat haze)
vec2 distortUV(vec2 uv, float t) {
    float distortion = 0.01 * cloud.g;
    uv.x += sin(t * 0.7 + uv.y * 5.0) * distortion;
    uv.y += cos(t * 0.8 + uv.x * 4.0) * distortion;
    return uv;
}

// --- MAIN EFFECT ---
vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = (((texture_coords)*(image_details)) - texture_details.xy*texture_details.ba)/texture_details.ba;
    uv = distortUV(uv, time * 0.5); // Gentle distortion
    
    vec4 tex = Texel(texture, texture_coords);
    if (tex.a == 0.0) return vec4(0.0);

    // Base color processing
    vec3 color = tex.rgb;
    float t = time * 0.5; // Slower animation for clouds
    
    // Apply effects
    vec3 clouds = applyClouds(uv, t);
    color = mix(color, clouds, clouds.r * 0.5); // Blend clouds
    color = applyGlow(color, uv, t);
    
    // Edge light
    float edge = smoothstep(0.7, 1.0, length(uv - 0.5));
    color += edge * vec3(0.8, 0.9, 1.0) * 0.3;

    // Preserve original texture
    tex.rgb = mix(tex.rgb, color, 0.6 + 0.4 * cloud.r);

    // Apply dissolve mask
    return dissolve_mask(tex * colour, texture_coords, uv);
}

// --- DISSOLVE MASK (unchanged) ---
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