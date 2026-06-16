// shimmer.frag
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uColor;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;

  // Diagonal shimmer sweep
  float sweep = uv.x + uv.y;
  float shimmer = smoothstep(0.0, 0.05,
    sin(sweep * 3.0 - uTime * 2.5) * 0.5 + 0.5);
  shimmer *= 0.12; // keep it subtle

  fragColor = vec4(uColor.rgb, shimmer);
}
