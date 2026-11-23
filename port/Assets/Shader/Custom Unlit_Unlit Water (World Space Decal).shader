// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Water (World Space Decal)" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_TextureAlphaCutoff ("Alpha Cutoff", Range(0, 1)) = 1
		_Alpha ("Alpha", Float) = 1
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
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
		sampler2D _DistortTex;
		float4 _DistortTex_ST;
		fixed4 _Color;
		float _TextureAlphaCutoff;
		float _Alpha;
		float _DistortStrength;
		float _RippleSpeed;
		float _WaveHeight;
		float _WaveSpeed;
		float _WaveLengthX;
		float _WaveLengthY;

		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
			float4 color : COLOR;
		};

		// Ola senoidal en Y calculada en espacio de mundo.
		void vert (inout appdata_full v) {
			float4 wp = mul(unity_ObjectToWorld, v.vertex);
			wp.y += _WaveHeight * sin(dot(wp.xz, float2(_WaveLengthX, _WaveLengthY)) + _Time.x * _WaveSpeed);
			v.vertex = mul(unity_WorldToObject, wp);
		}

		void surf (Input IN, inout SurfaceOutput o) {
			// Normales de distorsion muestreadas en XZ de mundo, desplazadas con el tiempo.
			float4 d = tex2D(_DistortTex, IN.worldPos.xz * _DistortTex_ST.xy + _DistortTex_ST.zw + _Time.xy * _RippleSpeed);
			d.x *= d.w;
			float2 distort = d.xy * 2.0 - 1.0;

			fixed4 c = tex2D(_MainTex, IN.uv_MainTex + distort * _DistortStrength) * _Color;
			o.Albedo = c.rgb;
			float visible = (c.a * IN.color.a >= _TextureAlphaCutoff) ? 1.0 : 0.0;
			o.Alpha = visible * _Alpha * IN.color.r;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
