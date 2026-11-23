// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Ocean Water (World Space)" {
	Properties {
		_Color ("Water Color", Color) = (1,1,1,1)
		_DistortTex ("Distortion Normals", 2D) = "white" {}
		_RippleSpeed ("Distortion Scroll Speed", Float) = 0.1
		_MainTex ("Water Edge Map", 2D) = "white" {}
		_EdgeColorR ("Water Edge Color R", Color) = (1,1,1,1)
		_EdgeColorG ("Water Edge Color G", Color) = (1,1,1,1)
		_EdgeColorB ("Water Edge Color B", Color) = (1,1,1,1)
		_EdgeColorA ("Water Edge Color A", Color) = (1,1,1,1)
		_EdgeDistortStrength ("Edge Distortion Strength", Range(-1, 1)) = 0
		_FoamColor ("Foam Color", Color) = (1,1,1,1)
		_FoamThickness ("Foam Thickness", Range(-1, 8)) = 0
		_BehindFoamCutoff ("Behind Foam Cutoff", Range(-10, 10)) = 4
		_FoamDistortStrength ("Foam Distortion Strength", Range(-8, 8)) = 0
		_WhiteFoamCutoff ("White Foam Cutoff", Range(0, 1)) = 0.9
		_WhiteFoamColor ("White Foam Color", Color) = (1,1,1,1)
		_RippleTex ("Ripple Texture", 2D) = "white" {}
		_RippleAlphaCutoff ("Ripple Alpha Cutoff", Range(-1, 1)) = 0
		_DistortStrength ("Ripple Distortion Strength", Range(-1, 1)) = 0
		_WaveHeight ("Wave Height", Float) = 0.05
		_WaveSpeed ("Wave Speed", Float) = 20
		_WaveLengthX ("Wave Length X", Float) = 1
		_WaveLengthY ("Wave Length Y", Float) = 1
	}
	SubShader {
		Tags { "IgnoreProjectors"="true" "Queue"="Transparent" "RenderType"="Transparent" }
		LOD 200
		Cull Back
		ZWrite On
		ZTest LEqual
		Stencil {
			Ref 2
			ReadMask 255
			WriteMask 255
			Comp Always
			Pass Keep
			Fail Keep
			ZFail Keep
		}

		CGPROGRAM
		// Opaco (sin Blend) pero en la cola Transparent; usa la profundidad de la escena para la espuma.
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
		fixed4 _EdgeColorR;
		fixed4 _EdgeColorG;
		fixed4 _EdgeColorB;
		fixed4 _EdgeColorA;
		fixed4 _FoamColor;
		fixed4 _WhiteFoamColor;
		float _RippleSpeed;
		float _EdgeDistortStrength;
		float _FoamThickness;
		float _BehindFoamCutoff;
		float _FoamDistortStrength;
		float _WhiteFoamCutoff;
		float _RippleAlphaCutoff;
		float _DistortStrength;
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
			float2 wxz = IN.worldPos.xz;

			// Normales de distorsion (scroll con frac para no perder precision).
			float2 scroll = frac(_Time.xy * _RippleSpeed);
			float4 d = tex2D(_DistortTex, wxz * _DistortTex_ST.xy + _DistortTex_ST.zw + scroll);
			d.x *= d.w;
			float2 distort = d.xy * 2.0 - 1.0;

			// Profundidad de la escena detras del agua, con la coordenada de pantalla distorsionada.
			float2 screenUV = (IN.screenPos.xy + distort * _FoamDistortStrength) / IN.screenPos.w;
			float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV));
			float depthDiff = sceneZ - IN.eyeDepth;

			float foamGrad = max(1.0 - depthDiff / (_FoamThickness + 1.0), 0.0);
			float whiteFoam = (foamGrad * ((depthDiff >= _BehindFoamCutoff * -0.25) ? 1.0 : 0.0) >= _WhiteFoamCutoff) ? 1.0 : 0.0;
			float edgeFoam = ceil(2.0 * foamGrad * ((depthDiff >= -_BehindFoamCutoff) ? 1.0 : 0.0));

			// Ondas (ripple) distorsionadas.
			float ripple = tex2D(_RippleTex, wxz * _RippleTex_ST.xy + _RippleTex_ST.zw + distort * _DistortStrength).a;
			float foam = saturate(edgeFoam * 0.5 + ripple + _RippleAlphaCutoff);

			// Mapa de bordes: el original divide por la escala (no multiplica) => (xz + offset) / tiling.
			float2 edgeUV = (wxz + _MainTex_ST.zw) / _MainTex_ST.xy + distort * _EdgeDistortStrength;
			fixed4 edgeMap = tex2D(_MainTex, edgeUV);

			fixed3 col = _Color.rgb;
			col = lerp(col, _EdgeColorR.rgb, (edgeMap.r >= 0.5) ? 1.0 : 0.0);
			col = lerp(col, _EdgeColorG.rgb, (edgeMap.g >= 0.5) ? 1.0 : 0.0);
			col = lerp(col, _EdgeColorB.rgb, (edgeMap.b >= 0.5) ? 1.0 : 0.0);
			col = lerp(col, _EdgeColorA.rgb, (1.0 - edgeMap.a >= 0.5) ? 1.0 : 0.0);
			col = lerp(col, _FoamColor.rgb, foam);
			col = lerp(col, _WhiteFoamColor.rgb, whiteFoam);

			o.Albedo = col;
			o.Alpha = 1.0;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
