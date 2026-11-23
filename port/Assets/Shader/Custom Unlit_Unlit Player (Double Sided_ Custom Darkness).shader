// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Player (Double Sided, Custom Darkness)" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
		_MaxDarkness ("Custom Darkness", Range(0, 1)) = 0.2
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull Off

		CGPROGRAM
		#pragma surface surf ASHPlayer fullforwardshadows alphatest:_Cutoff addshadow exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma target 3.0
		#include "ASHToonLighting.cginc"
		
		sampler2D _MainTex;
		fixed4 _Color;

		// Salida propia: el shader original cambia umbral, pasos y oscuridad minima segun la zona de la UV.
		struct SurfaceOutputPlayer {
		    fixed3 Albedo;
		    fixed3 Normal;
		    fixed3 Emission;
		    half Specular;
		    fixed Gloss;
		    fixed Alpha;
		    float Threshold;   // equivale a _AttenuationThreshold
		    float BitDepth;    // equivale a _ShadowBitDepth
		    float Darkness;    // equivale a _MaxDarkness
		};

		inline half4 LightingASHPlayer (SurfaceOutputPlayer s, half3 lightDir, half atten)
		{
		    float3 n = normalize(s.Normal);
		    float v = floor(dot(n, lightDir) * atten * s.BitDepth + s.Threshold) / max(s.BitDepth, 0.01);
		    float useSteps = (s.BitDepth >= 0.01) ? 1.0 : 0.0;
		    v = useSteps * (v - 1.0) + 1.0;
		    float minLight = 1.0 - s.Darkness;
		    v = v * (1.0 - minLight) + minLight;
		    v *= (atten >= _LightCutoff) ? 1.0 : 0.0;

		    half4 c;
		    c.rgb = s.Albedo * _LightColor0.rgb * v;
		    c.a = s.Alpha;
		    return c;
		}

		struct Input {
		    float2 uv_MainTex;
		    fixed facing : VFACE;
		};

		void surf (Input IN, inout SurfaceOutputPlayer o) {
		    float2 uv = IN.uv_MainTex;
		    float left  = (uv.x <= 0.5) ? 1.0 : 0.0;   // mitad izquierda de la UV: lleva el tinte _Color
		    float right = 1.0 - left;
		    float below = (uv.y <= 0.0) ? 1.0 : 0.0;   // UV con v <= 0

		    fixed4 tint = lerp(fixed4(1, 1, 1, 1), _Color, left);
		    fixed4 c = tex2D(_MainTex, uv) * tint;

		    o.Albedo = c.rgb;
		    o.Alpha = c.a;
		    o.Threshold = lerp(_AttenuationThreshold, 0.8, left);
		    o.BitDepth = _ShadowBitDepth * (1.0 - right * below);   // derecha y v<=0: sin escalones (iluminacion plana)
		    o.Darkness = (below > 0.5) ? _MaxDarkness : lerp(_MaxDarkness, 0.2, right);
		    float faceSign = (IN.facing > 0.0) ? 1.0 : -1.0;
		    o.Normal = float3(0, 0, faceSign);
		}
		ENDCG
	}
	Fallback "Diffuse"
}
