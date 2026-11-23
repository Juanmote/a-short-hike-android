// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit (Double Sided, Backface Color)" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_BackColor ("Back Face Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull Off

		CGPROGRAM
		#pragma surface surf ASHToonDS fullforwardshadows alphatest:_Cutoff addshadow exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma target 3.0
		#include "ASHToonLighting.cginc"
		
		sampler2D _MainTex;
		fixed4 _Color;
		fixed4 _BackColor;

		// Igual que ASHToon, pero renormaliza la normal (la normal de doble cara llega interpolada desde el espacio tangente).
		inline half4 LightingASHToonDS (SurfaceOutput s, half3 lightDir, half atten)
		{
		    s.Normal = normalize(s.Normal);
		    return LightingASHToon(s, lightDir, atten);
		}

		struct Input {
		    float2 uv_MainTex;
		    fixed facing : VFACE;
		};

		void surf (Input IN, inout SurfaceOutput o) {
		    // VFACE: +1 cara frontal, -1 cara trasera. La normal se invierte en la trasera (como en el original).
		    float faceSign = (IN.facing > 0.0) ? 1.0 : -1.0;
		#ifdef UNITY_PASS_SHADOWCASTER
		    fixed4 tint = _Color;
		#else
		    fixed4 tint = (faceSign > 0.0) ? _Color : _BackColor;
		#endif
		    fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * tint;
		    o.Albedo = c.rgb;
		    o.Alpha = c.a;
		    o.Normal = float3(0, 0, faceSign);
		}
		ENDCG
	}
	Fallback "Diffuse"
}
