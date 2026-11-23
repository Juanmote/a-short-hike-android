// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Hidden/Custom Unlit/Unlit Terrain AddPass" {
	Properties {
		_Splat3 ("Layer 3 (A)", 2D) = "white" {}
		_Splat2 ("Layer 2 (B)", 2D) = "white" {}
		_Splat1 ("Layer 1 (G)", 2D) = "white" {}
		_Splat0 ("Layer 0 (R)", 2D) = "white" {}
		[HideInInspector]_MainTex ("BaseMap (RGB)", 2D) = "white" {}
		[HideInInspector]_Color ("Main Color", Color) = (1,1,1,1)
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 64)) = 1
		_SideTex ("Albedo Top (RGB)", 2D) = "white" {}
		_Blend ("Sharpness", Range(0, 150)) = 0.5
		_Control1 ("First Control Map", 2D) = "black" {}
		_Control2 ("Second Control Map", 2D) = "black" {}
	}
	SubShader {
		Tags { "Queue"="Geometry-99" "IgnoreProjector"="True" "RenderType"="Opaque" "SplatCount"="4" }
		Cull Back

		CGPROGRAM
		// decal:add -> Blend One One + ZWrite Off en todos los pases, como el original.
		// finalcolor anula la niebla automatica: se aplica a mano hacia negro (pase aditivo).
		#pragma surface surf ASHToon decal:add vertex:vert finalcolor:ASHSplatFinalColor exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma multi_compile_fog
		#pragma multi_compile_instancing
		#pragma target 3.0
		#define TERRAIN_SPLAT_ADDPASS
		#include "ASHToonLighting.cginc"

		sampler2D _Control1, _Control2;
		float4 _Control1_ST;
		sampler2D _Splat0, _Splat1, _Splat2, _Splat3;
		float4 _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST;
		float _Blend;
		fixed4 _Color;

		struct Input {
			float2 tc;          // texcoord0 sin transformar (cada capa aplica su _ST)
			float3 worldNormal;
			UNITY_FOG_COORDS(0)
		};

		inline float4 ASHDominant4(float4 c, float bias, float threshold)
		{
			float4 r;
			r.x = step(threshold, c.x - c.y - c.z - c.w - bias);
			r.y = step(threshold, c.y - c.z - c.w - bias - r.x);
			r.z = step(threshold, c.z - c.w - bias - r.x - r.y);
			r.w = step(threshold, c.w - bias - r.x - r.y - r.z);
			return r;
		}

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.tc = v.texcoord.xy;
			float4 clipPos = UnityObjectToClipPos(v.vertex);
			UNITY_TRANSFER_FOG(o, clipPos);
		}

		void surf (Input IN, inout SurfaceOutput o)
		{
			float2 uvControl = TRANSFORM_TEX(IN.tc, _Control1);
			// Capas 4-7 del terreno (_Splat0..3 de este pase) usando el segundo mapa de control,
			// solo donde no gano ninguna capa del primero.
			float4 w1 = ASHDominant4(tex2D(_Control1, uvControl), 0.0, 0.1);
			float taken = step(0.01, dot(w1, float4(1.0, 1.0, 1.0, 1.0)));
			float4 w2 = ASHDominant4(tex2D(_Control2, uvControl), taken, 0.01);

			float3 top = w2.x * tex2D(_Splat0, TRANSFORM_TEX(IN.tc, _Splat0)).rgb
			           + w2.y * tex2D(_Splat1, TRANSFORM_TEX(IN.tc, _Splat1)).rgb
			           + w2.z * tex2D(_Splat2, TRANSFORM_TEX(IN.tc, _Splat2)).rgb
			           + w2.w * tex2D(_Splat3, TRANSFORM_TEX(IN.tc, _Splat3)).rgb;
			top *= _Color.rgb;

			// Solo las caras "de arriba" del triplanar (los laterales los pinta el pase base).
			float3 bw = pow(abs(IN.worldNormal), _Blend);
			bw /= dot(bw, float3(1.0, 1.0, 1.0));
			float tx = step(0.01, bw.x - bw.y - bw.z);
			float ty = step(0.01, bw.y - bw.z - tx);
			float tz = step(0.01, bw.z - tx - ty);
			float none = 1.0 - step(0.01, tx + ty + tz);

			o.Albedo = top * (none + ty);
			o.Alpha = 1.0;
		}

		void ASHSplatFinalColor (Input IN, SurfaceOutput o, inout fixed4 color)
		{
			UNITY_APPLY_FOG_COLOR(IN.fogCoord, color, fixed4(0, 0, 0, 0));
		}
		ENDCG
	}
	Fallback "Diffuse"
}
