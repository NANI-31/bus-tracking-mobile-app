// liquid_glass.frag
#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;     // scene behind the glass
uniform vec2 uResolution;
uniform float uTime;
uniform float uBlurStrength;    // 0.0 – 1.0
uniform vec4 uTintColor;        // rgba tint

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;

  // Refraction wobble — simulates liquid surface
  float wobble = sin(uv.x * 12.0 + uTime) * 0.003
               + cos(uv.y * 10.0 + uTime * 0.8) * 0.003;
  vec2 distortedUV = uv + vec2(wobble);

  // Sample background with distortion
  vec4 bg = texture(uTexture, distortedUV);

  // Chromatic aberration for glass refraction feel
  float r = texture(uTexture, distortedUV + vec2(0.003, 0.0)).r;
  float g = texture(uTexture, distortedUV).g;
  float b = texture(uTexture, distortedUV - vec2(0.003, 0.0)).b;
  bg = vec4(r, g, b, bg.a);

  // Apply tint
  fragColor = mix(bg, uTintColor, uTintColor.a * 0.18);
}