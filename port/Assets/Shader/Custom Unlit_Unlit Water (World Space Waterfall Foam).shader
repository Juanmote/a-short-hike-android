// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Water (World Space Waterfall Foam)" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_AlphaCutoffRamp ("Alpha Cutoff", 2D) = "gray" {}
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_ScrollSpeed ("Scroll Speed", Float) = 0.1
		_DistortTex ("Distortion Normals", 2D) = "white" {}
		_DistortStrength ("Distortion Strength", Range(-1, 1)) = 0
		_RippleSpeed ("Ripple Speed", Float) = 0.1
		_WaveHeight ("Wave Height", Float) = 0.05
		_WaveSpeed ("Wave Speed", Float) = 20
		_WaveLengthX ("Wave Length X", Float) = 1
		_WaveLengthY ("Wave Length Y", Float) = 1
	}
	SubShader {
		Tags { "IgnoreProjectors"="true" "Queue"="Transparent" "RenderType"="Transparent" }
		LOD 200
		Cull Back
		ZWrite Off
		ZTest LEqual
		ColorMask RGB
		Offset -1, -1

		CGPROGRAM
		// Blend SrcAlpha OneMinusSrcAlpha (base) / SrcAlpha One (add), ZWrite Off, Offset -1,-1 => decal:blend
		#pragma surface surf ASHToon vertex:vert decal:blend exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma target 3.0
		#include "ASHToonLighting.cginc"

		sampler2D _MainTex;
		sampler2D _AlphaCutoffRamp;
		sampler2D _DistortTex;
		float4 _DistortTex_ST;
		fixed4 _Color;
		float _ScrollSpeed;
		float _DistortStrength;
		float _RippleSpeed;
		float _WaveHeight;
		float _WaveSpeed;
		float _WaveLengthX;
		float _WaveLengthY;

		struct Input {
			float2 uv_MainTex;
			float2 uv_AlphaCutoffRamp;
			float3 worldPos;
		};

		// Ola senoidal en Y calculada en espacio de mundo.
		void vert (inout appdata_full v) {
			float4 wp = mul(unity_ObjectToWorld, v.vertex);
			wp.y += _WaveHeight * sin(dot(wp.xz, float2(_WaveLengthX, _WaveLengthY)) + _Time.x * _WaveSpeed);
			v.vertex = mul(unity_WorldToObject, wp);
		}

		void surf (Input IN, inout SurfaceOutput o) {
			float4 d = tex2D(_DistortTex, IN.worldPos.xz * _DistortTex_ST.xy + _DistortTex_ST.zw + _Time.xy * _RippleSpeed);
			d.x *= d.w;
			float2 distort = d.xy * 2.0 - 1.0;

			// La espuma cae: scroll vertical de la textura principal.
			float2 uv = IN.uv_MainTex + distort * _DistortStrength + float2(0.0, _Time.x * _ScrollSpeed);
			fixed4 c = tex2D(_MainTex, uv) * _Color;
			fixed ramp = tex2D(_AlphaCutoffRamp, IN.uv_AlphaCutoffRamp).r;
			o.Albedo = c.rgb;
			o.Alpha = (c.a >= ramp) ? 1.0 : 0.0;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
