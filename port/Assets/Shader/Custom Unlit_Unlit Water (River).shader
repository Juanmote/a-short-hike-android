// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Water (River)" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Main Texture", 2D) = "white" {}
		_MainTexSpeed ("Main Texture Scroll Speed", Range(-50, 50)) = 1
		_AlphaCutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
		_FoamColor ("Foam Color", Color) = (1,1,1,1)
		_FoamDetailTex ("Foam Detail Texture", 2D) = "black" {}
		_FoamDetailCutoff ("Foam Detail Cutoff", Range(0, 1)) = 0.5
		_FoamDetailSpeed ("Foam Detail Scroll Speed", Range(-50, 50)) = 1
		_FoamCurveCutoff ("Curve Foam Cutoff", Range(0, 1)) = 0.5
		_Noise ("Noise Texture", 2D) = "white" {}
		_NoiseSpeed ("Noise Scroll Speed", Range(-10, 10)) = 0.5
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
		ColorMask RGB

		CGPROGRAM
		// Opaco con recorte (discard contra _AlphaCutoff) en la cola Transparent.
		// ShadowCaster propio con la misma ola y el mismo recorte => addshadow.
		#pragma surface surf ASHToon vertex:vert alphatest:_AlphaCutoff addshadow fullforwardshadows exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma target 3.0
		#include "ASHToonLighting.cginc"

		sampler2D _MainTex;
		sampler2D _FoamDetailTex;
		sampler2D _Noise;
		sampler2D_float _CameraDepthTexture;
		fixed4 _Color;
		fixed4 _FoamColor;
		float _MainTexSpeed;
		float _FoamDetailCutoff;
		float _FoamDetailSpeed;
		float _FoamCurveCutoff;
		float _NoiseSpeed;
		float _WaveHeight;
		float _WaveSpeed;
		float _WaveLengthX;
		float _WaveLengthY;

		struct Input {
			float2 uv_MainTex;
			float2 uv_FoamDetailTex;
			float2 uv_Noise;
			float3 worldNormal;
			float4 screenPos;
			float eyeDepth;
			float4 color : COLOR;
		};

		// Ola senoidal en Y en espacio de mundo, ponderada por el canal verde del color de vertice.
		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);
			float4 wp = mul(unity_ObjectToWorld, v.vertex);
			wp.y += sin(wp.x * _WaveLengthX + wp.z * _WaveLengthY + _Time.x * _WaveSpeed) * _WaveHeight * v.color.g;
			v.vertex = mul(unity_WorldToObject, wp);
			o.eyeDepth = -UnityObjectToViewPos(v.vertex).z;
		}

		void surf (Input IN, inout SurfaceOutput o) {
			float noise = tex2D(_Noise, IN.uv_Noise - _Time.xy * _NoiseSpeed).r;

			// Espuma de contacto: 1 si la geometria de detras esta a menos de 1 unidad.
			float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)));
			float contactFoam = ceil(1.0 - saturate(sceneZ - IN.eyeDepth));

			// Espuma en las zonas curvas (normal inclinada): 4*ny*(1-ny), ny = peso de Y en la normal al cuadrado.
			float3 n2 = IN.worldNormal * IN.worldNormal;
			float ny = n2.y / dot(n2, float3(1.0, 1.0, 1.0));
			float curve = (4.0 * ny - 4.0 * ny * ny) * noise;
			float curveFoam = (saturate(IN.color.r + _FoamCurveCutoff) >= curve) ? 0.0 : 1.0;

			// Espuma de detalle que se desplaza con el rio.
			float detail = tex2D(_FoamDetailTex, IN.uv_FoamDetailTex - float2(0.0, _Time.x * _FoamDetailSpeed)).r * noise;
			float detailFoam = (_FoamDetailCutoff >= detail) ? 0.0 : 1.0;

			float foam = min(curveFoam + detailFoam + contactFoam, 1.0);

			fixed4 c = tex2D(_MainTex, IN.uv_MainTex - float2(0.0, _Time.x * _MainTexSpeed)) * _Color;
			o.Albedo = lerp(c.rgb, _FoamColor.rgb, foam);
			o.Alpha = c.a;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
