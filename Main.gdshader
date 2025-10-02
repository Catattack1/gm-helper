shader_type canvas_item;

// Galaxy colors
uniform vec3 galaxy_color_1 : source_color = vec3(0.1, 0.05, 0.3);
uniform vec3 galaxy_color_2 : source_color = vec3(0.3, 0.1, 0.5);
uniform vec3 galaxy_color_3 : source_color = vec3(0.05, 0.15, 0.4);
uniform vec3 star_color : source_color = vec3(1.0, 0.95, 0.9);

// Animation speed
uniform float speed : hint_range(0.1, 2.0) = 0.3;

// Noise function for procedural generation
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for complex patterns
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(int i = 0; i < 5; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    uv.x *= SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    
    float time = TIME * speed;
    
    // Create rotating spiral galaxy effect
    float angle = atan(uv.y, uv.x);
    float dist = length(uv);
    
    // Spiral arms
    vec2 spiral_uv = vec2(dist * 3.0, angle + dist * 2.0 - time * 0.5);
    float spiral = fbm(spiral_uv);
    
    // Nebula clouds
    vec2 cloud_uv = uv * 2.0 + vec2(time * 0.1, time * 0.05);
    float clouds = fbm(cloud_uv);
    
    // Rotating galaxy core
    vec2 core_uv = uv * 4.0 + vec2(cos(time * 0.3), sin(time * 0.3));
    float core = fbm(core_uv);
    
    // Combine layers
    float galaxy = spiral * 0.5 + clouds * 0.3 + core * 0.2;
    
    // Color mixing
    vec3 color = mix(galaxy_color_1, galaxy_color_2, galaxy);
    color = mix(color, galaxy_color_3, clouds * 0.5);
    
    // Add brightness gradient from center
    float brightness = 1.0 - smoothstep(0.0, 1.5, dist);
    color += galaxy_color_2 * brightness * 0.3;
    
    // Add stars
    vec2 star_uv = UV * 50.0 + vec2(time * 0.02, time * 0.03);
    float stars = hash(floor(star_uv));
    stars = pow(stars, 50.0) * smoothstep(0.99, 1.0, stars);
    
    // Twinkling effect
    float twinkle = sin(TIME * 3.0 + hash(floor(star_uv)) * 100.0) * 0.5 + 0.5;
    stars *= twinkle;
    
    color += star_color * stars;
    
    // Slight vignette
    float vignette = 1.0 - dist * 0.3;
    color *= vignette;
    
    COLOR = vec4(color, 1.0);
}