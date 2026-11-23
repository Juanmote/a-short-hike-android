// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Water Buoy" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
		_MaxDarkness ("Custom Darkness", Range(0, 1)) = 0.25
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
		_WaveHeight ("Wave Height", Float) = 0.05
		_WaveSpeed ("Wave Speed", Float) = 20
		_WaveLengthX ("Wave Length X", Float) = 1
		_WaveLengthY ("Wave Length Y", Float) = 1
		_WiggleSpeed ("Wiggle Speed", Float) = 1
		_WiggleRadians ("Wiggle Radians", Float) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull Back
		ZWrite On
		ZTest LEqual
		ColorMask RGB

		CGPROGRAM
		// ShadowCaster propio con el mismo balanceo/ola y el mismo recorte => addshadow.
		#pragma surface surf ASHToon vertex:vert fullforwardshadows alphatest:_Cutoff addshadow exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma multi_compile_instancing
		#pragma target 3.0
		#include "ASHToonLighting.cginc"

		sampler2D _MainTex;
		fixed4 _Color;
		float _WaveHeight;
		float _WaveSpeed;
		float _WaveLengthX;
		float _WaveLengthY;
		float _WiggleSpeed;
		float _WiggleRadians;

		struct Input {
			float2 uv_MainTex;
		};

		void vert (inout appdata_full v) {
			// Balanceo: giro en Y (espacio de objeto) con fase segun la posicion del objeto en el mundo.
			float3 origin = float3(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w);
			float angle = sin(_Time.x * _WiggleSpeed + dot(origin, float3(1.0, 1.0, 1.0))) * _WiggleRadians;
			float s = sin(angle);
			float c = cos(angle);
			float4 p = v.vertex;
			p.x = c * v.vertex.x - s * v.vertex.z;
			p.z = s * v.vertex.x + c * v.vertex.z;

			// Ola senoidal en Y calculada en espacio de mundo.
			float4 wp = mul(unity_ObjectToWorld, p);
			wp.y += _WaveHeight * sin(dot(wp.xz, float2(_WaveLengthX, _WaveLengthY)) + _Time.x * _WaveSpeed);
			v.vertex = mul(unity_WorldToObject, wp);
			// La normal no se rota (igual que en el original).
		}

		void surf (Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
