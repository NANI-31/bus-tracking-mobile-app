#include <flutter/runtime_effect.glsl>

// Uniforms from Flutter
uniform vec2 uResolution;    // logical width/height of the nav bar widget
uniform vec2 uMouse;         // center point (width/2, height/2)
uniform float uEffectSize;   // lens envelope size – use 10.0 for full-bar coverage
uniform float uBlurIntensity;      // 0.0 = sharp refractive glass, >0 = frosted
uniform float uDispersionStrength; // chromatic aberration strength

uniform sampler2D uTexture;  // cropped background image (exact nav-bar region)

out vec4 fragColor;

void main() {
    // Fragment position in logical pixels (0 → resolution)
    vec2 fragCoord = FlutterFragCoord();

    // UV coordinates 0→1 across the widget (screen space: y=0 at top)
    vec2 uv = fragCoord / uResolution.xy;

    // ── Y-axis flip for texture sampling ─────────────────────────────────────
    // dart:ui.Image has (0,0) at TOP-LEFT (screen convention).
    // OpenGL sampler2D has (0,0) at BOTTOM-LEFT (GL convention).
    // On Impeller backends (most modern devices), Flutter corrects this
    // automatically. On Skia backends (older Android), it does NOT, causing
    // the captured background to appear Y-flipped → inverted scroll behavior.
    // We always flip uv.y before sampling so both backends render correctly.
    vec2 uvTex = vec2(uv.x, 1.0 - uv.y);

    // Signed UV offset from center  (-0.5 → +0.5)
    vec2 center = uMouse.xy / uResolution.xy;
    vec2 m2 = uv - center;

    // ── Lens envelope ─────────────────────────────────────────────────────────
    // Use a 4th-power super-ellipse (squircle) WITHOUT aspect-ratio correction.
    // With uEffectSize=10 the envelope covers the full UV space: at the bar
    // corners (m2=±0.5,±0.5) roundedBox≈0.125, baseIntensity=4 → rb1=1.0.
    float effectRadius    = uEffectSize * 0.5;
    float sizeMultiplier  = 1.0 / (effectRadius * effectRadius);
    float roundedBox      = pow(abs(m2.x), 4.0) + pow(abs(m2.y), 4.0);
    float baseIntensity   = 100.0 * sizeMultiplier;

    // Three zones used for lens body (rb1), specular rim (rb2), shadow (rb3)
    float rb1 = clamp((1.0  - roundedBox * baseIntensity)        * 8.0,  0.0, 1.0);
    float rb2 = clamp((0.95 - roundedBox * baseIntensity * 0.95) * 16.0, 0.0, 1.0)
              - clamp((0.9  - roundedBox * baseIntensity * 0.95) * 16.0, 0.0, 1.0);
    float rb3 = clamp((1.5  - roundedBox * baseIntensity * 1.1)  * 2.0,  0.0, 1.0)
              - clamp((1.0  - roundedBox * baseIntensity * 1.1)  * 2.0,  0.0, 1.0);

    fragColor = vec4(0.0);

    if (rb1 + rb2 > 0.0) {

        // ── Refractive distortion ─────────────────────────────────────────────
        // Compute lens distortion in screen UV space (y=0 top), then flip for
        // texture sampling. This keeps the lens bulge direction physically correct
        // regardless of which backend is in use.
        float distortionStrength = 50.0 * sizeMultiplier;
        vec2 lensUV = (uv - 0.5) * (1.0 - roundedBox * distortionStrength) + 0.5;
        vec2 lens   = vec2(lensUV.x, 1.0 - lensUV.y);   // flip for sampler

        // ── Chromatic aberration ──────────────────────────────────────────────
        // Guard against NaN when m2=(0,0) at the exact center pixel.
        float m2Len = length(m2);
        vec2 dir = m2Len > 0.0001 ? m2 / m2Len : vec2(0.0);
        float dispersionScale = uDispersionStrength * 0.05;

        // Dispersion is strongest at the glass edge, zero at center.
        float dispersionMask = smoothstep(0.0, 0.5, roundedBox * baseIntensity);

        // Chromatic offsets operate in screen UV space → negate y for sampler flip.
        vec2 redOff   = dir * dispersionScale * 2.0  * dispersionMask;
        vec2 greenOff = dir * dispersionScale * 1.0  * dispersionMask;
        vec2 blueOff  = dir * dispersionScale * -1.5 * dispersionMask;
        // Flip y component of offsets so they apply in sampler space correctly.
        vec2 redOffset   = vec2( redOff.x,   -redOff.y);
        vec2 greenOffset = vec2( greenOff.x, -greenOff.y);
        vec2 blueOffset  = vec2( blueOff.x,  -blueOff.y);

        vec4 colorResult = vec4(0.0);

        if (uBlurIntensity > 0.0) {
            // Frosted / blurred glass – 5×5 tap
            float blurRadius = uBlurIntensity / max(uResolution.x, uResolution.y);
            float total = 0.0;
            vec3  colorSum = vec3(0.0);
            for (float x = -2.0; x <= 2.0; x += 1.0) {
                for (float y = -2.0; y <= 2.0; y += 1.0) {
                    vec2 offset = vec2(x, y) * blurRadius;
                    colorSum.r += texture(uTexture, lens + offset + redOffset).r;
                    colorSum.g += texture(uTexture, lens + offset + greenOffset).g;
                    colorSum.b += texture(uTexture, lens + offset + blueOffset).b;
                    total += 1.0;
                }
            }
            colorResult = vec4(colorSum / total, 1.0);
        } else {
            // Sharp refractive glass – single sample with chromatic offsets
            colorResult.r = texture(uTexture, lens + redOffset).r;
            colorResult.g = texture(uTexture, lens + greenOffset).g;
            colorResult.b = texture(uTexture, lens + blueOffset).b;
            colorResult.a = 1.0;
        }

        // ── Lighting / caustic gradient ───────────────────────────────────────
        float gradient =
            clamp((clamp( m2.y, 0.0,    0.2) + 0.1) / 2.0, 0.0, 1.0) +
            clamp((clamp(-m2.y, -1000.0, 0.2) * rb3 + 0.1) / 2.0, 0.0, 1.0);

        // Blend: raw background → refracted sample, driven by lens zone
        fragColor = mix(texture(uTexture, uvTex), colorResult, rb1);
        fragColor = clamp(fragColor + vec4(rb2 * 0.3) + vec4(gradient * 0.2), 0.0, 1.0);

    } else {
        // Outside lens envelope – pass through the unmodified background
        fragColor = texture(uTexture, uvTex);
    }
}
