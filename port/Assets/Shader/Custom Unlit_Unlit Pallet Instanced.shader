// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Pallet Instanced" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_PalletOffset ("Pallet Offset X", Range(0, 1)) = 0
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
		_MaxDarkness ("Custom Darkness", Range(0, 1)) = 0.5
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#pragma surface surf ASHToon fullforwardshadows alphatest:_Cutoff exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma multi_compile_instancing
		#pragma target 3.0
		#include "ASHToonLighting.cginc"
		
		sampler2D _MainTex;
		fixed4 _Color;

		// _PalletOffset se fija por instancia (PropertyBlockSetter usa un MaterialPropertyBlock).
		UNITY_INSTANCING_BUFFER_START(Props)
		    UNITY_DEFINE_INSTANCED_PROP(float, _PalletOffset)
		UNITY_INSTANCING_BUFFER_END(Props)

		struct Input {
		    float2 uv_MainTex;
		};

		void surf (Input IN, inout SurfaceOutput o) {
		    float2 uv = IN.uv_MainTex;
		    uv.x += UNITY_ACCESS_INSTANCED_PROP(Props, _PalletOffset);
		    fixed4 c = tex2D(_MainTex, uv) * _Color;
		    o.Albedo = c.rgb;
		    o.Alpha = c.a;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
