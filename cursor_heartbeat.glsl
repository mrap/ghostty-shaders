float ease(float x) {
    return pow(1.0 - x, 5.0);
}

float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Generate subtle color shift for idle cursor
vec4 getIdleCursorColor(float time) {
    float hue = fract(time * 0.06); // Faster color cycle (16 second full cycle)
    return vec4(hsv2rgb(vec3(hue, 0.15, 0.95)), 1.0); // Low saturation, high brightness
}

// Create smooth, contemplative breathing pattern
float getBreathingPulse(float time) {
    float breathRate = 0.2; // ~12 breaths per minute (5 second cycle)
    float breath = sin(time * breathRate * 3.14159 * 2.0);
    
    // Gentle sine squared for smooth, organic feeling
    float smoothPulse = breath * breath * (breath > 0.0 ? 1.0 : 0.3);
    
    return smoothPulse * 0.15; // Very noticeable 15% scale variation
}

// Soft brightness pulse for subtle feedback
float getBrightnessPulse(float time) {
    float breathRate = 0.2;
    float breath = sin(time * breathRate * 3.14159 * 2.0);
    return (breath * 0.5 + 0.5) * 0.1; // Gentle 10% brightness variation
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif
    
    vec2 vu = normalize(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);
    
    // Normalize cursor position and size
    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    
    // Apply gentle breathing pulse to cursor size
    float sizePulse = getBreathingPulse(iTime);
    float brightnessPulse = getBrightnessPulse(iTime);
    vec2 pulsedSize = currentCursor.zw * (1.0 + sizePulse);
    
    // Generate calm color with subtle brightness pulse
    vec4 baseColor = getIdleCursorColor(iTime);
    vec4 cursorColor = vec4(baseColor.rgb * (1.0 + brightnessPulse), baseColor.a);
    
    // Calculate cursor SDF with pulsed size
    float sdfCursor = getSdfRectangle(vu, currentCursor.xy - (pulsedSize * offsetFactor), pulsedSize * 0.5);
    
    // Apply cursor color with smooth edges
    float cursorMask = 1.0 - smoothstep(0.0, normalize(vec2(1.5, 1.5), 0.).x, sdfCursor);
    
    // Steady, contemplative blending
    fragColor = mix(fragColor, cursorColor, cursorMask * 0.8);
}