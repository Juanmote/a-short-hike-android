// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Fade" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Fade ("Fade", Range(0, 1)) = 1
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
	}
	SubShader {
		Tags { "QUEUE"="Transparent" "RenderType"="Transparent" }
		LOD 200
		Cull Back
		ZWrite Off
		ZTest LEqual
		ColorMask RGB

		CGPROGRAM
		#pragma surface surf ASHToon alpha:fade noforwardadd exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma multi_compile_instancing
		#pragma target 3.0
		#include "ASHToonLighting.cginc"

		sampler2D _MainTex;
		fixed4 _Color;
		float _Fade;

		struct Input {
			float2 uv_MainTex;
		};

		void surf (Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a * _Fade;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
