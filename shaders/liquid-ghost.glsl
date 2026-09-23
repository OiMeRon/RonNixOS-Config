// Ghostty custom-shader: Liquid Ghost
// Inspired by Apple's Liquid Glass and https://github.com/OverShifted/LiquidGlass
//
// A liquid-glass lens follows your cursor with goo physics:
//   - underdamped spring ease between iPreviousCursor and iCurrentCursor
//   - directional stretch along travel (metaball feel) on big jumps
//   - expanding ripple from the previous cursor on every cursor change
//   - crescent specular highlight on the upper-left rim
//   - subtle chromatic dispersion at the rim
//   - settles to a gentle breathing squircle at rest
//   - dims when the surface loses focus, pulses on refocus
//
// Apply by adding to ~/.config/ghostty/config:
//   custom-shader = liquid-ghostty.glsl

// ============================================================================
// Tuning knobs
// ============================================================================

// --- Lens shape ---
const float POWER_FACTOR     = 6.0;   // squircle roundness (2 = ellipse, large = rectangle)
const float LENS_W_CELLS     = 10.0;  // lens width  in cursor-cell widths
const float LENS_H_CELLS     = 4.0;   // lens height in cursor-cell heights

// --- Goo physics (underdamped spring) ---
// Position eases from iPreviousCursor to iCurrentCursor over ~SPRING_DURATION
// seconds with mild overshoot.
const float SPRING_DURATION  = 0.45;  // total settle time (s)
const float SPRING_OVERSHOOT = 0.18;  // overshoot amplitude (0 = critically damped)
const float SPRING_FREQ      = 12.0;  // oscillation frequency (rad/s)

// --- Stretch on travel (metaball feel) ---
// During the ease, the lens stretches along the travel direction.
const float STRETCH_GAIN     = 0.0025; // px-of-stretch per px-of-travel
const float STRETCH_MAX      = 1.8;    // hard cap on stretch multiplier

// --- Refraction ---
const float RIM_WIDTH        = 60.0;  // rim band width in pixels (where refraction lives)
const float U_A = 0.7, U_B = 2.3, U_C = 5.2, U_D = 6.9;
const float U_F_POWER        = 3.0;

// --- Looks ---
const float NOISE_AMOUNT     = 0.05;
const float GLOW_WEIGHT      = 0.35;
const float SPECULAR_POWER   = 28.0;  // crescent tightness
const float SPECULAR_GAIN    = 0.55;  // crescent brightness
const float CHROMA_OFFSET    = 1.6;   // px of R/B split at the rim

// --- Idle breathing ---
const float BREATHE_AMP      = 0.015; // fractional radius modulation at rest
const float BREATHE_HZ       = 0.6;

// --- Ripple on cursor change ---
const float RIPPLE_SPEED     = 1600.0; // px/s expansion speed
const float RIPPLE_LIFE      = 0.45;   // seconds
const float RIPPLE_WIDTH     = 40.0;   // px thickness of the ring
const float RIPPLE_STRENGTH  = 0.35;   // refraction amplitude inside the ring

// --- Focus behavior ---
const float FOCUS_DIM        = 0.35;  // lens opacity multiplier when unfocused
const float FOCUS_WAKE_TIME  = 0.5;   // duration of refocus pulse (s)
const float FOCUS_WAKE_GAIN  = 0.35;  // refocus pulse extra brightness

const float M_E   = 2.718281828459045;
const float M_PI  = 3.14159265358979;

// ============================================================================
// Helpers
// ============================================================================

// Squircle SDF (in arbitrary units; pass a pixel-space p and pixel-space r).
float sdSuperellipse(vec2 p, float n, float r) {
    vec2 pa = abs(p) + 1e-4;
    float numerator   = pow(pa.x, n) + pow(pa.y, n) - pow(r, n);
    float den_x       = pow(pa.x, 2.0 * n - 2.0);
    float den_y       = pow(pa.y, 2.0 * n - 2.0);
    float denominator = n * sqrt(den_x + den_y) + 1e-5;
    return numerator / denominator;
}

// LiquidGlass falloff: ~0 deep inside, ~1 at the rim.
float fglass(float x) {
    return 1.0 - U_B * pow(U_C * M_E, -U_D * x - U_A);
}

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

// Underdamped spring ease in [0,1] domain. Returns the eased value at time t
// (in [0, SPRING_DURATION]), with overshoot controlled by SPRING_OVERSHOOT.
// At t<=0 returns 0; at t>=SPRING_DURATION returns 1.
float springEase(float t) {
    if (t <= 0.0) return 0.0;
    if (t >= SPRING_DURATION) return 1.0;
    float u = t / SPRING_DURATION;
    // Critically-damped base plus a decaying sinusoid for overshoot.
    float decay = exp(-4.0 * u);
    float osc   = sin(SPRING_FREQ * t) * SPRING_OVERSHOOT * decay;
    float base  = 1.0 - decay * (1.0 + 4.0 * u);   // smooth s-curve to 1
    return base + osc * (1.0 - base);              // overshoot tapers near 1
}

// Cursor center in fragCoord space.
//   iCurrentCursor.xy = top-left of cursor (-X, +Y corner)
//   iCurrentCursor.zw = width, height
// fragCoord is (0,0) at bottom-left, Y-up. So bottom-left of cursor is
// (x, y - h). Center is (x + w/2, y - h/2).
vec2 cursorCenter(vec4 c) {
    return vec2(c.x + c.z * 0.5, c.y - c.w * 0.5);
}

// ============================================================================
// Main
// ============================================================================
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 base = texture(iChannel0, uv);

    // ---- Lens position: spring between previous and current cursor --------
    float tSinceCursor = iTime - iTimeCursorChange;
    float s = springEase(tSinceCursor);

    vec2 prevC = cursorCenter(iPreviousCursor);
    vec2 currC = cursorCenter(iCurrentCursor);
    vec2 lensC = mix(prevC, currC, s);

    // Cell metrics for lens sizing (use current cursor cell size).
    vec2 cell = max(iCurrentCursor.zw, vec2(8.0, 16.0));
    vec2 lensSize = vec2(LENS_W_CELLS * cell.x, LENS_H_CELLS * cell.y) * 0.5;
    // lensSize is the half-extent along each axis (radius-ish).

    // ---- Directional stretch along travel --------------------------------
    vec2 travel = currC - prevC;
    float travelLen = length(travel);
    vec2 travelDir = travelLen > 1e-3 ? travel / travelLen : vec2(1.0, 0.0);

    // Stretch is strongest mid-spring, tapers to 0 at start and end.
    float stretchEnv = sin(s * M_PI);                  // 0..1..0 across the ease
    float stretchAmt = clamp(travelLen * STRETCH_GAIN * stretchEnv,
                             0.0, STRETCH_MAX - 1.0);

    // Idle breathing (only fully active when settled).
    float settled = smoothstep(0.7, 1.0, s);
    float breathe = 1.0 + BREATHE_AMP * settled
                  * sin(iTime * BREATHE_HZ * 2.0 * M_PI);

    // Local coordinate: rotate so the travel direction is +X, then scale.
    vec2 q = fragCoord - lensC;
    // Build rotation that maps travelDir -> +X.
    //   R * travelDir = (1,0)  =>  R = [[ tx,  ty], [-ty, tx]]
    vec2 qR = vec2(q.x * travelDir.x + q.y * travelDir.y,
                  -q.x * travelDir.y + q.y * travelDir.x);

    // Stretched half-extents in rotated space:
    //   x is the travel-aligned axis (gets longer)
    //   y is the perpendicular axis (gets shorter; area roughly preserved)
    // Then multiplied by `breathe` for the resting in/out wobble.
    vec2 halfExt = vec2(lensSize.x * (1.0 + stretchAmt),
                        lensSize.y / sqrt(1.0 + stretchAmt)) * breathe;

    // Normalize qR so the squircle is unit-r in this local frame.
    vec2 pLocal = qR / halfExt;

    // SDF in normalized local space, then converted to a pixel-ish band by
    // scaling with the smaller half-extent.
    float dNorm = sdSuperellipse(pLocal, POWER_FACTOR, 1.0);
    float dPx   = dNorm * min(halfExt.x, halfExt.y);

    // ---- Ripple from previous cursor --------------------------------------
    // Independent of the lens. Adds a ring of refraction expanding outward.
    float rippleStrength = 0.0;
    vec2  rippleDir = vec2(0.0);
    if (tSinceCursor < RIPPLE_LIFE) {
        float r = RIPPLE_SPEED * tSinceCursor;
        vec2  rq = fragCoord - prevC;
        float rd = length(rq) - r;                 // signed distance from ring
        float ringEnv = exp(-(rd * rd) / (RIPPLE_WIDTH * RIPPLE_WIDTH));
        float lifeEnv = 1.0 - tSinceCursor / RIPPLE_LIFE;
        rippleStrength = ringEnv * lifeEnv * RIPPLE_STRENGTH;
        rippleDir = length(rq) > 1e-3 ? rq / length(rq) : vec2(0.0);
    }

    // ---- Focus state ------------------------------------------------------
    float focused = (iFocus > 0) ? 1.0 : 0.0;
    float tSinceFocus = iTime - iTimeFocus;
    float focusPulse = focused * exp(-tSinceFocus / FOCUS_WAKE_TIME)
                     * (tSinceFocus >= 0.0 ? 1.0 : 0.0);
    float lensOpacity = mix(FOCUS_DIM, 1.0, focused);

    // ---- Composite --------------------------------------------------------
    // Outside the lens AND outside any active ripple: passthrough fast path.
    if (dPx > 0.0 && rippleStrength < 0.005) {
        fragColor = base;
        return;
    }

    // Rim band weight (1 at the boundary, 0 deep inside).
    float rim = (dPx <= 0.0)
              ? 1.0 - smoothstep(0.0, RIM_WIDTH, -dPx)
              : 0.0;

    // Refraction direction: inward gradient of the SDF in pixel space.
    // We can approximate with the normalized vector from the lens center
    // toward the fragment, in the local rotated frame.
    vec2 refractDirLocal = (length(qR) > 1e-3) ? normalize(qR) : vec2(0.0);
    // Rotate back to screen space.
    vec2 refractDir = vec2(
        refractDirLocal.x * travelDir.x - refractDirLocal.y * travelDir.y,
        refractDirLocal.x * travelDir.y + refractDirLocal.y * travelDir.x
    );

    // Refraction magnitude from the LiquidGlass falloff, but only at the rim.
    float distInside = max(-dPx, 0.0);
    float refractAmt = pow(fglass(distInside / RIM_WIDTH), U_F_POWER);
    float refractMag = rim * refractAmt;

    // Add the ripple as an additional displacement (always active, even
    // outside the lens — that's the point of the ripple).
    vec2 totalDisp = -refractDir * refractMag * RIM_WIDTH * 0.6
                    - rippleDir  * rippleStrength * RIPPLE_WIDTH * 0.5;
    totalDisp *= lensOpacity; // less effect when unfocused

    // Chromatic dispersion: sample R/G/B at slightly different offsets.
    vec2 chromaOff = refractDir * CHROMA_OFFSET * rim;
    vec2 uvBase = uv + totalDisp / iResolution.xy;
    float rC = texture(iChannel0, uvBase + chromaOff / iResolution.xy).r;
    float gC = texture(iChannel0, uvBase).g;
    float bC = texture(iChannel0, uvBase - chromaOff / iResolution.xy).b;
    vec3 refracted = vec3(rC, gC, bC);

    // ---- Crescent specular highlight (upper-left of the lens) -------------
    // Light direction in *local* rotated frame, so the highlight follows the
    // pill orientation as it stretches.
    vec2 lightDir = normalize(vec2(-0.6, 0.8));
    float specDot = dot(-refractDirLocal, lightDir);
    float spec = pow(max(specDot, 0.0), SPECULAR_POWER) * rim;
    spec *= lensOpacity;

    // Subtle film grain inside the lens.
    float grain = (rand(fragCoord * 1e-3 + iTime * 0.1) - 0.5) * NOISE_AMOUNT * rim;
    refracted += grain;

    // Rim glow tinted slightly toward the cursor color when available.
    float glowEnv = rim * rim;       // concentrated near the boundary
    vec3 glowTint = mix(vec3(1.0), iCursorColor + 0.001, 0.35);
    vec3 glow = glowTint * GLOW_WEIGHT * glowEnv;

    // Specular is white-ish, with a hint of the cursor color.
    vec3 specColor = mix(vec3(1.0), iCursorColor + 0.001, 0.25);
    vec3 highlight = specColor * spec * SPECULAR_GAIN;

    // Compose lens contribution.
    vec3 lensRgb = refracted + glow + highlight;

    // Refocus pulse: brighten the rim briefly.
    lensRgb += focusPulse * FOCUS_WAKE_GAIN * rim * vec3(1.0);

    // Lens "presence" mask: full inside the lens (but only contributing via
    // rim/refraction/spec), plus any ripple bleed.
    float lensMask = max(rim, rippleStrength);
    lensMask *= lensOpacity;

    // Final blend: identity where the lens has nothing to say.
    vec3 outRgb = mix(base.rgb, lensRgb, lensMask);

    // Ensure deep interior of the lens shows the (clean) base — refraction
    // only lives at the rim, so the center stays crisp and readable.
    if (dPx < -RIM_WIDTH * 1.2 && rippleStrength < 0.005) {
        outRgb = base.rgb;
    }

    fragColor = vec4(outRgb, base.a);
}
