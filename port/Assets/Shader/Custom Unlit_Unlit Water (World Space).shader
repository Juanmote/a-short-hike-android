// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Water (World Space)" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_FoamColor ("Foam Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_RippleTex ("Ripple Texture", 2D) = "white" {}
		_RippleAlphaCutoff ("Ripple Alpha Cutoff", Range(-1, 1)) = 0
		_DistortTex ("Distortion Normals", 2D) = "white" {}
		_DistortStrength ("Distortion Strength", Range(-1, 1)) = 0
		_RippleSpeed ("Ripple Speed", Float) = 0.1
		_WaveHeight ("Wave Height", Float) = 0.05
		_WaveSpeed ("Wave Speed", Float) = 20
		_WaveLengthX ("Wave Length X", Float) = 1
		_WaveLengthY ("Wave Length Y", Float) = 1
		_FoamThickness ("Foam Thickness", Range(-10, 10)) = 0
	}
	SubShader {
		Tags { "IgnoreProjectors"="true" "Queue"="Transparent" "RenderType"="Transparent" }
		LOD 200
		Cull Back
		ZWrite On
		ZTest LEqual

		CGPROGRAM
		// Opaco (sin Blend) pero en la cola Transparent; usa la profundidad de la escena para la espuma de orilla.
		#pragma surface surf ASHToon vertex:vert fullforwardshadows exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma target 3.0
		#include "ASHToonLighting.cginc"

		sampler2D _MainTex;
		sampler2D _RippleTex;
		sampler2D _DistortTex;
		sampler2D_float _CameraDepthTexture;
		float4 _MainTex_ST;
		float4 _RippleTex_ST;
		float4 _DistortTex_ST;
		fixed4 _Color;
		fixed4 _FoamColor;
		float _RippleAlphaCutoff;
		float _DistortStrength;
		float _RippleSpeed;
		float _FoamThickness;
		float _WaveHeight;
		float _WaveSpeed;
		float _WaveLengthX;
		float _WaveLengthY;

		struct Input {
			float3 worldPos;
			float4 screenPos;
			float eyeDepth;
		};

		// Ola senoidal en Y calculada en espacio de mundo.
		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);
			float4 wp = mul(unity_ObjectToWorld, v.vertex);
			wp.y += _WaveHeight * sin(dot(wp.xz, float2(_WaveLengthX, _WaveLengthY)) + _Time.x * _WaveSpeed);
			v.vertex = mul(unity_WorldToObject, wp);
			o.eyeDepth = -UnityObjectToViewPos(v.vertex).z;
		}

		void surf (Input IN, inout SurfaceOutput o) {
			// Espuma donde el agua toca la geometria (diferencia de profundidad), en 3 escalones (0, 0.5, 1).
			float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)));
			float edge = saturate((sceneZ - IN.eyeDepth) / (_FoamThickness + 1.0));
			float edgeFoam = ceil((1.0 - edge) * 2.0);

			float2 wxz = IN.worldPos.xz;
			float4 d = tex2D(_DistortTex, wxz * _DistortTex_ST.xy + _DistortTex_ST.zw + _Time.xy * _RippleSpeed);
			d.x *= d.w;
			float2 distort = d.xy * 2.0 - 1.0;

			float ripple = tex2D(_RippleTex, wxz * _RippleTex_ST.xy + _RippleTex_ST.zw + distort * _DistortStrength).a;
			float foam = saturate(edgeFoam * 0.5 + ripple + _RippleAlphaCutoff);

			fixed3 water = tex2D(_MainTex, wxz * _MainTex_ST.xy + _MainTex_ST.zw).rgb * _Color.rgb;
			o.Albedo = lerp(water, _FoamColor.rgb, foam);
			o.Alpha = 1.0;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
