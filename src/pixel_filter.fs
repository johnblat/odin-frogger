// #version 330

// in vec2 fragTexCoord;
// in vec4 fragColor;
// uniform sampler2D texture0;
// out vec4 finalColor;

// vec2 uv_aa_smoothstep(vec2 uv, vec2 res, float width) {
//     vec2 pixels = uv * res;
    
//     vec2 pixels_floor = floor(pixels + 0.5);
//     vec2 pixels_fract = fract(pixels + 0.5);
//     vec2 pixels_aa = fwidth(pixels) * width * 0.5;
//     pixels_fract = smoothstep( vec2(0.5) - pixels_aa, vec2(0.5) + pixels_aa, pixels_fract );
    
//     return (pixels_floor + pixels_fract - 0.5) / res;
// }

// void main()
// {
//     finalColor = fragColor * texture(texture0, uv_aa_smoothstep(fragTexCoord, ivec2(textureSize(texture0, 0)), 1.5));
// }



// #version 330 core


// uniform sampler2D texture0;


// in vec2 fragTexCoord;
// in vec4 fragColor;


// out vec4 finalColor;

// const float PI = 3.14159265359;

// float curveDistance(float x, float sharp) {
//     float xStep = step(0.5, x);
//     float curve = 0.5 - sqrt(0.25 - (x - xStep) * (x - xStep)) * sign(0.5 - x);
//     return mix(x, curve, sharp);
// }

// vec4 dilate(vec4 col) {
//     vec4 x = mix(vec4(1.0), col, 1.0);
//     return col * x;
// }

// mat4 getColorMatrix(sampler2D tex, vec2 co, vec2 dx) {
//     return mat4(
//         dilate(texture(tex, co - dx)),
//         dilate(texture(tex, co)),
//         dilate(texture(tex, co + dx)),
//         dilate(texture(tex, co + 2.0 * dx))
//     );
// }

// vec3 filterLanczos(vec4 coeffs, mat4 colorMatrix) {
//     vec4 col = coeffs * colorMatrix;
//     vec4 sampleMin = min(colorMatrix[1], colorMatrix[2]);
//     vec4 sampleMax = max(colorMatrix[1], colorMatrix[2]);
//     col = clamp(col, sampleMin, sampleMax);
//     return col.rgb;
// }

// void main() {
//     vec2 dx = vec2(1.0 / vec2(320.0, 240.0).x, 0.0);
//     vec2 dy = vec2(0.0, 1.0 / vec2(320.0, 240.0).y);
//     vec2 pixCo = fragTexCoord * vec2(320.0, 240.0) - vec2(0.5);
//     vec2 texCo = (floor(pixCo) + vec2(0.5)) / vec2(320.0, 240.0);
//     vec2 dist = fract(pixCo);

//     float curveX = curveDistance(dist.x, 0.5 * 0.5);
//     vec4 coeffs = PI * vec4(1.0 + curveX, curveX, 1.0 - curveX, 2.0 - curveX);
//     coeffs = 2.0 * sin(coeffs) * sin(coeffs / 2.0) / (coeffs * coeffs);
//     coeffs /= dot(coeffs, vec4(1.0));

//     vec3 col = filterLanczos(coeffs, getColorMatrix(texture0, texCo, dx));
//     vec3 col2 = filterLanczos(coeffs, getColorMatrix(texture0, texCo + dy, dx));

//     col = mix(col, col2, curveDistance(dist.y, 1.0));
//     col = pow(col, vec3(2.0 / (1.0 + 1.0)));

//     float luma = dot(vec3(0.2126, 0.7152, 0.0722), col);
//     float bright = (max(max(col.r, col.g), col.b) + luma) / 1.8;
//     float scanBright = clamp(bright, 0.35, 0.65);
//     float scanBeam = clamp(bright * 1.5, 1.5, 1.5);
//     float scanWeight = 1.0 - pow(cos(fragTexCoord.y * 2.0 * PI * vec2(320.0, 240.0).y) * 0.5 + 0.5, scanBeam) * 1.0;

//     float mask = 1.0 - 0.3;
//     vec2 modFac = floor(fragTexCoord * vec2(640.0, 480.0) * vec2(320.0, 240.0) / (vec2(320.0, 240.0) * vec2(1.0, 1.0 * 1.0)));
//     int dotNo = int(mod((modFac.x + mod(modFac.y, 2.0) * 0.0) / 1.0, 3.0));

//     vec3 maskWeight = (dotNo == 0) ? vec3(1.0, mask, mask) :
//                       (dotNo == 1) ? vec3(mask, 1.0, mask) :
//                                      vec3(mask, mask, 1.0);

//     if (vec2(320.0, 240.0).y >= 400.0) scanWeight = 1.0;

//     vec3 colOriginal = col;
//     col *= vec3(scanWeight);
//     col = mix(col, colOriginal, scanBright);
//     col *= maskWeight;
//     col = pow(col, vec3(1.0 / 1.8));
//     col *= 1.2;

//     finalColor = vec4(col, 1.0) * fragColor;
// }

#version 330 core

uniform sampler2D texture0;

in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;

const float PI = 3.14159265359;

void main() {
    vec2 texSize = vec2(320.0, 240.0); // your internal resolution
    vec2 texel = 1.0 / texSize;

    // Mild chromatic aberration offsets (leaky edges)
    float offset = 0.1 * texel.x;

    // Channel-separated slight blur
    float blurSize = 0.75 * texel.x;

    float r = (
        texture(texture0, fragTexCoord - vec2(blurSize, 0.0)).r +
        texture(texture0, fragTexCoord + vec2(offset, 0.0)).r
    ) * 0.5;

    float g = (
        texture(texture0, fragTexCoord - vec2(blurSize * 0.5, 0.0)).g +
        texture(texture0, fragTexCoord + vec2(blurSize * 0.5, 0.0)).g
    ) * 0.5;

    float b = (
        texture(texture0, fragTexCoord + vec2(blurSize, 0.0)).b +
        texture(texture0, fragTexCoord - vec2(offset, 0.0)).b
    ) * 0.5;

    vec3 color = vec3(r, g, b);

    // Very subtle scanline brightness modulation
    float scan = 0.985 + 0.015 * sin(fragTexCoord.y * texSize.y * PI);
    color *= scan;

    // Gentle gamma warmth
    color = pow(color, vec3(0.96)); // gentle lift

    finalColor = vec4(color, 1.0) * fragColor;
}
