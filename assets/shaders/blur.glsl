#ifdef PIXEL
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 sum = vec4(0.0);
    vec2 tc = texture_coords;
    
    // Number of blur samples (higher = more blur but more expensive)
    const int samples = 15;
    
    // Blur radius (adjusted by resolution for consistent blur regardless of resolution)
    float blurSize = radius / resolution;
    
    // Gaussian weights
    float weight;
    float weightSum = 0.0;
    
    // Apply blur in the direction specified
    for (int i = -samples; i <= samples; i++) {
        float offset = float(i) * blurSize;
        vec2 offsetCoords = tc + direction * offset;
        
        // Gaussian weight calculation: exp(-x^2/(2*sigma^2))
        weight = exp(-(float(i) * float(i)) / (2.0 * (radius * 0.5) * (radius * 0.5)));
        weightSum += weight;
        
        sum += Texel(texture, offsetCoords) * weight;
    }
    
    // Return the blurred result, multiplied by the original color
    return sum / weightSum * color;
}
#endif

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
    return transform_projection * vertex_position;
}
#endif

uniform vec2 direction;
uniform float radius;
uniform float resolution;
