// Iluminación "toon" de A Short Hike, reconstruida a partir del GLSL compilado
// del juego original (Custom Unlit/Unlit y derivados).
// Uso en un surface shader:  #pragma surface surf ASHToon ...
#ifndef ASH_TOON_LIGHTING_INCLUDED
#define ASH_TOON_LIGHTING_INCLUDED

// Algunos shaders lo exponen como propiedad (Custom Darkness); en el resto lo pone el juego como global.
float _MaxDarkness;
// Global que pone el juego.
float _LightCutoff;
float _AttenuationThreshold;
float _ShadowBitDepth;

// Factor de luz cuantizado (0..1), igual que en el original.
inline float ASHToonFactor(float ndotl, float atten)
{
    float v = floor(ndotl * atten * _ShadowBitDepth + _AttenuationThreshold) / max(_ShadowBitDepth, 0.01);
    float useSteps = (_ShadowBitDepth >= 0.01) ? 1.0 : 0.0;
    v = useSteps * (v - 1.0) + 1.0;
    float minLight = 1.0 - _MaxDarkness;
    v = v * (1.0 - minLight) + minLight;
    v *= (atten >= _LightCutoff) ? 1.0 : 0.0;
    return v;
}

inline half4 LightingASHToon(SurfaceOutput s, half3 lightDir, half atten)
{
    float l = ASHToonFactor(dot(s.Normal, lightDir), atten);
    half4 c;
    c.rgb = s.Albedo * _LightColor0.rgb * l;
    c.a = s.Alpha;
    return c;
}

#endif
