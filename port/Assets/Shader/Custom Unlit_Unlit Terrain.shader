// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Terrain" {
	Properties {
		_Splat3 ("Layer 3 (A)", 2D) = "white" {}
		_Splat2 ("Layer 2 (B)", 2D) = "white" {}
		_Splat1 ("Layer 1 (G)", 2D) = "white" {}
		_Splat0 ("Layer 0 (R)", 2D) = "white" {}
		[HideInInspector]_MainTex ("BaseMap (RGB)", 2D) = "white" {}
		[HideInInspector]_Color ("Main Color", Color) = (1,1,1,1)
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
		_SideTex ("Albedo Top (RGB)", 2D) = "white" {}
		_Blend ("Sharpness", Range(0, 150)) = 0.5
		_AltSideTex ("Second Albedo Top (RGB)", 2D) = "white" {}
		_AltSideTexChannel ("Second Albedo Channel", Vector) = (0,0,0,0)
		_Control1 ("First Control Map", 2D) = "black" {}
		_Control2 ("Second Control Map", 2D) = "black" {}
	}
	SubShader {
		Tags { "Queue"="Geometry-100" "RenderType"="Opaque" "SplatCount"="4" }
		Cull Back

		CGPROGRAM
		// FORWARDADD del original sin sombras -> sin fullforwardshadows. Sin ShadowCaster propio (lo da el Fallback).
		#pragma surface surf ASHToon vertex:vert exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma multi_compile_instancing
		#pragma target 3.0
		#include "ASHToonLighting.cginc"

		sampler2D _Control1;
		float4 _Control1_ST;
		sampler2D _Splat0, _Splat1, _Splat2, _Splat3;
		float4 _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST;
		sampler2D _SideTex;
		float4 _SideTex_ST;
		sampler2D _AltSideTex;
		float4 _AltSideTexChannel;
		float _Blend;
		fixed4 _Color;

		struct Input {
			float2 tc;          // texcoord0 sin transformar (cada capa aplica su _ST)
			float3 worldPos;
			float3 worldNormal;
		};

		// Capa "dominante" (sin mezcla suave): cada canal gana si supera a los siguientes
		// y no ha ganado ya uno anterior.
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
		}

		void surf (Input IN, inout SurfaceOutput o)
		{
			// Splatmap
			float4 control = tex2D(_Control1, TRANSFORM_TEX(IN.tc, _Control1));
			float4 w = ASHDominant4(control, 0.0, 0.1);
			float3 top = w.x * tex2D(_Splat0, TRANSFORM_TEX(IN.tc, _Splat0)).rgb
			           + w.y * tex2D(_Splat1, TRANSFORM_TEX(IN.tc, _Splat1)).rgb
			           + w.z * tex2D(_Splat2, TRANSFORM_TEX(IN.tc, _Splat2)).rgb
			           + w.w * tex2D(_Splat3, TRANSFORM_TEX(IN.tc, _Splat3)).rgb;
			top *= _Color.rgb;

			// Triplanar "duro" segun la normal de mundo.
			float3 bw = pow(abs(IN.worldNormal), _Blend);
			bw /= dot(bw, float3(1.0, 1.0, 1.0));
			float tx = step(0.01, bw.x - bw.y - bw.z);
			float ty = step(0.01, bw.y - bw.z - tx);
			float tz = step(0.01, bw.z - tx - ty);
			float none = 1.0 - step(0.01, tx + ty + tz);
			float topWeight = none + ty;

			// Laterales (X usa ZY, Z usa XY), con textura alternativa segun la capa.
			float alt = saturate(dot(w, _AltSideTexChannel));
			float2 uvX = (IN.worldPos.zy + _SideTex_ST.zw) * _SideTex_ST.xy;
			float2 uvZ = (IN.worldPos.xy + _SideTex_ST.zw) * _SideTex_ST.xy;
			float3 sideX = lerp(tex2D(_SideTex, uvX).rgb, tex2D(_AltSideTex, uvX).rgb, alt);
			float3 sideZ = lerp(tex2D(_SideTex, uvZ).rgb, tex2D(_AltSideTex, uvZ).rgb, alt);

			o.Albedo = top * topWeight + sideX * tx + sideZ * tz;
			o.Alpha = 1.0;
		}
		ENDCG
	}
	Dependency "AddPassShader" = "Hidden/Custom Unlit/Unlit Terrain AddPass"
	Dependency "BaseMapShader" = "Hidden/Custom Unlit/Unlit Terrain BasePass"
	Fallback "Diffuse"
}
