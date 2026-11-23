// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Water Fan" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull Off
		ZWrite On
		ZTest LEqual
		ColorMask RGB

		CGPROGRAM
		#pragma surface surf ASHToon fullforwardshadows alphatest:_Cutoff exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma target 3.0
		#include "ASHToonLighting.cginc"

		sampler2D _MainTex;
		fixed4 _Color;

		struct Input {
			float2 uv_MainTex;
		};

		void surf (Input IN, inout SurfaceOutput o) {
			// Abanico de agua: las UV se "abren" en forma de trapecio segun uv.y
			// y la textura se desplaza en X con el tiempo.
			float2 uv = IN.uv_MainTex;
			float a = 1.0 - uv.y;
			float s = (uv.x - 0.5 * a) / (1.0 - a);
			float yBase = uv.y * 0.5 + 0.5;
			float yTop = uv.y * 2.0 - 1.0;
			float2 fanUV;
			fanUV.x = _Time.y * 2.0 + uv.x;
			fanUV.y = lerp(yBase, yTop, 1.0 - s);

			fixed4 c = tex2D(_MainTex, fanUV) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
