// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Hidden/Custom Unlit/Unlit Terrain BasePass" {
	Properties {
		_MainTex ("Base (RGB) Smoothness (A)", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
	}
	SubShader {
		Tags { "Queue"="Geometry-100" "RenderType"="Opaque" }
		LOD 200
		Cull Back

		CGPROGRAM
		#pragma surface surf ASHToon exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma multi_compile_instancing
		#pragma target 3.0
		#include "ASHToonLighting.cginc"

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		void surf (Input IN, inout SurfaceOutput o)
		{
			// El original no multiplica por _Color (solo el basemap que genera el terreno).
			o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;
			o.Alpha = 1.0;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
