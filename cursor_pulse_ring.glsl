float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

// Create pulsing ring effect
float getPulseRing(vec2 center, vec2 position, float time) {
    float pulseRate = 1.0 / 3.0; // Pulse every 3 seconds
    float pulseTime = fract(time * pulseRate);
    
    // Calculate distance from cursor center
    float distance = length(position - center);
    
    // Ring expansion parameters
    float maxRadius = 0.15; // Maximum ring radius
    float ringWidth = 0.03; // Width of the ring
    float currentRadius = pulseTime * maxRadius;
    
    // Create ring shape
    float ringMask = smoothstep(currentRadius - ringWidth, currentRadius, distance) - 
                     smoothstep(currentRadius, currentRadius + ringWidth, distance);
    
    // Fade out over time with smooth easing
    float fadeOut = pow(1.0 - pulseTime, 3.0);
    
    return ringMask * fadeOut;
}

// Create cursor contraction effect during pulse start
float getCursorContraction(float time) {
    float pulseRate = 1.0 / 3.0; // Pulse every 3 seconds
    float pulseTime = fract(time * pulseRate);
    
    // Contraction happens at the start of pulse (first 0.25 seconds)
    float contractionDuration = 0.25;
    
    if (pulseTime <= contractionDuration) {
        // Normalize to 0-1 range for contraction phase
        float contractionPhase = pulseTime / contractionDuration;
        
        // Sharp recoil effect - quick contraction then bounce back
        float contraction = pow(sin(contractionPhase * 3.14159), 2.0) * 0.4; // 40% max contraction
        
        return -contraction; // Negative for shrinking
    }
    
    return 0.0; // No contraction after initial recoil
}

// Generate glow color with subtle hue shift
vec3 getPulseColor(float time) {
    float hueShift = sin(time * 0.5) * 0.1 + 0.6; // Subtle blue-cyan range
    vec3 baseColor = vec3(0.3, 0.7, 1.0); // Cyan-blue base
    
    // Add subtle hue variation
    baseColor.r += sin(time * 0.3) * 0.2;
    baseColor.g += cos(time * 0.4) * 0.1;
    
    return normalize(baseColor);
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
    
    // Calculate cursor center using ORIGINAL size (before contraction)
    vec2 cursorCenter = currentCursor.xy - (currentCursor.zw * offsetFactor);
    
    // Apply cursor contraction effect to size only
    float contraction = getCursorContraction(iTime);
    vec2 contractedSize = currentCursor.zw * (1.0 + contraction);
    
    // Calculate cursor SDF with contracted size but original center
    float sdfCursor = getSdfRectangle(vu, cursorCenter, contractedSize * 0.5);
    
    // Apply cursor rendering with contraction
    float cursorMask = 1.0 - smoothstep(0.0, normalize(vec2(1.5, 1.5), 0.).x, sdfCursor);
    
    // Get pulse ring intensity
    float pulseIntensity = getPulseRing(cursorCenter, vu, iTime);
    
    // Generate pulse color
    vec3 pulseColor = getPulseColor(iTime);
    
    // Create glow effect
    float glowRadius = 0.08;
    float distanceFromCenter = length(vu - cursorCenter);
    float glow = exp(-distanceFromCenter / glowRadius) * pulseIntensity * 0.3;
    
    // Combine ring and glow
    float totalEffect = pulseIntensity + glow;
    
    // Apply the effect
    vec4 effectColor = vec4(pulseColor * totalEffect, totalEffect * 0.7);
    
    // Enhanced cursor color during contraction
    vec4 cursorColor = vec4(0.8, 0.9, 1.0, 1.0);
    if (contraction < 0.0) {
        // Add slight glow to cursor during contraction
        cursorColor.rgb += abs(contraction) * vec3(0.2, 0.3, 0.5);
    }
    
    // Apply cursor with contraction effect
    fragColor = mix(fragColor, cursorColor, cursorMask * 0.8);
    
    // Blend with pulse effect
    fragColor = mix(fragColor, fragColor + effectColor, totalEffect);
}