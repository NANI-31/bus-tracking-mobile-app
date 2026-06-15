#version 460 core

precision mediump float;

// Standard Flutter uniform inputs (mapped by float offset indices in Dart)
layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform float uTime;
layout(location = 2) uniform float uTraffic;
layout(location = 3) uniform vec4 uColor;

out vec4 fragColor;

void main() {
    // Generate a flowing/pulsing plasma-like glowing effect along the segment
    vec2 st = gl_FragCoord.xy / uSize;
    float pulse = sin(uTime * 4.0 + st.x * 15.0) * 0.5 + 0.5;
    float glow = exp(-pow(st.y - 0.5, 2.0) * (20.0 - uTraffic * 12.0));
    
    vec3 col = uColor.rgb * glow * (0.6 + pulse * 0.4);
    fragColor = vec4(col, glow * uColor.a);
}
