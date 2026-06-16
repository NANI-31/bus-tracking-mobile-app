// refraction.frag — top-edge highlight (simulates glass bevel)
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uRadius;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;

  // Bright top-edge specular highlight
  float highlight = smoothstep(0.0, 0.06, uv.y)
                  * (1.0 - smoothstep(0.06, 0.12, uv.y));
  highlight *= smoothstep(0.0, uRadius / uResolution.x, uv.x)
             * smoothstep(0.0, uRadius / uResolution.x, 1.0 - uv.x);

  fragColor = vec4(1.0, 1.0, 1.0, highlight * 0.45);
}