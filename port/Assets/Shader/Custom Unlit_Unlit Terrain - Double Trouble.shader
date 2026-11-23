// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Terrain - Double Trouble" {
	Properties {
		_Splat3 ("Layer 3 (A)", 2D) = "white" {}
		_Splat2 ("Layer 2 (B)", 2D) = "white" {}
		_Splat1 ("Layer 1 (G)", 2D) = "white" {}
		_Splat0 ("Layer 0 (R)", 2D) = "white" {}
		_Splat7 ("Layer 7 (A)", 2D) = "white" {}
		_Splat6 ("Layer 6 (B)", 2D) = "white" {}
		_Splat5 ("Layer 5 (G)", 2D) = "white" {}
		_Splat4 ("Layer 4 (R)", 2D) = "white" {}
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
		_SideTex ("Albedo Top (RGB)", 2D) = "white" {}
		_Blend ("Sharpness", Range(0, 150)) = 0.5
		_AltSideTex ("Second Albedo Top (RGB)", 2D) = "white" {}
		_AltSideTexChannel ("Second Albedo Channel", Vector) = (0,0,0,0)
		_AltSideTexChannel2 ("Second Albedo Channel 2", Vector) = (0,0,0,0)
		_Control1 ("First Control Map", 2D) = "black" {}
		_Control2 ("Second Control Map", 2D) = "black" {}
	}
	SubShader {
		Tags { "Queue"="Geometry-100" "RenderType"="Opaque" "SplatCount"="4" }
		Cull Back

		CGPROGRAM
		// El original no tiene variantes INSTANCING_ON en este shader (sin multi_compile_instancing).
		#pragma surface surf ASHToon vertex:vert exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma target 3.0
		#include "ASHToonLighting.cginc"

		sampler2D _Control1, _Control2;
		float4 _Control1_ST;
		sampler2D _Splat0, _Splat1, _Splat2, _Splat3;
		sampler2D _Splat4, _Splat5, _Splat6, _Splat7;
		float4 _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST;
		float4 _Splat4_ST, _Splat5_ST, _Splat6_ST, _Splat7_ST;
		sampler2D _SideTex;
		float4 _SideTex_ST;
		sampler2D _AltSideTex;
		float4 _AltSideTex_ST;
		float4 _AltSideTexChannel;
		float4 _AltSideTexChannel2;
		float _Blend;

		struct Input {
			float2 tc;          // texcoord0 sin transformar (cada capa aplica su _ST)
			float3 worldPos;
			float3 worldNormal;
		};

		// Capa "dominante" (sin mezcla suave): cada canal gana si supera a los siguientes
		// y no ha ganado ya uno anterior (ni la cantidad "bias" ya ocupada).
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
			float2 uvControl = TRANSFORM_TEX(IN.tc, _Control1);

			// Capas 0-3 (primer mapa de control)
			float4 w1 = ASHDominant4(tex2D(_Control1, uvControl), 0.0, 0.1);
			// ¿Ya hay capa elegida en el primer mapa? (el original re-evalua los pesos igual)
			float4 used = ASHDominant4(w1, 0.0, 0.1);
			float taken = step(0.01, dot(used, float4(1.0, 1.0, 1.0, 1.0)));
			// Capas 4-7 (segundo mapa de control, mismas UV), solo donde no gano ninguna de 0-3
			float4 w2 = ASHDominant4(tex2D(_Control2, uvControl), taken, 0.01);

			float3 top = w1.x * tex2D(_Splat0, TRANSFORM_TEX(IN.tc, _Splat0)).rgb
			           + w1.y * tex2D(_Splat1, TRANSFORM_TEX(IN.tc, _Splat1)).rgb
			           + w1.z * tex2D(_Splat2, TRANSFORM_TEX(IN.tc, _Splat2)).rgb
			           + w1.w * tex2D(_Splat3, TRANSFORM_TEX(IN.tc, _Splat3)).rgb
			           + w2.x * tex2D(_Splat4, TRANSFORM_TEX(IN.tc, _Splat4)).rgb
			           + w2.y * tex2D(_Splat5, TRANSFORM_TEX(IN.tc, _Splat5)).rgb
			           + w2.z * tex2D(_Splat6, TRANSFORM_TEX(IN.tc, _Splat6)).rgb
			           + w2.w * tex2D(_Splat7, TRANSFORM_TEX(IN.tc, _Splat7)).rgb;

			// Triplanar "duro" segun la normal de mundo.
			float3 bw = pow(abs(IN.worldNormal), _Blend);
			bw /= dot(bw, float3(1.0, 1.0, 1.0));
			float tx = step(0.01, bw.x - bw.y - bw.z);
			float ty = step(0.01, bw.y - bw.z - tx);
			float tz = step(0.01, bw.z - tx - ty);
			float none = 1.0 - step(0.01, tx + ty + tz);
			float topWeight = none + ty;

			// Laterales con textura alternativa segun las capas de ambos mapas.
			float alt = saturate(dot(w1, _AltSideTexChannel) + dot(w2, _AltSideTexChannel2));
			float2 uvX  = (IN.worldPos.zy + _SideTex_ST.zw) * _SideTex_ST.xy;
			float2 uvZ  = (IN.worldPos.xy + _SideTex_ST.zw) * _SideTex_ST.xy;
			float2 uvAX = (IN.worldPos.zy + _AltSideTex_ST.zw) * _AltSideTex_ST.xy;
			float2 uvAZ = (IN.worldPos.xy + _AltSideTex_ST.zw) * _AltSideTex_ST.xy;
			float3 sideX = lerp(tex2D(_SideTex, uvX).rgb, tex2D(_AltSideTex, uvAX).rgb, alt);
			float3 sideZ = lerp(tex2D(_SideTex, uvZ).rgb, tex2D(_AltSideTex, uvAZ).rgb, alt);

			o.Albedo = top * topWeight + sideX * tx + sideZ * tz;
			o.Alpha = 1.0;
		}
		ENDCG
	}
	// Pinta las 8 capas en un solo pase: NO declara AddPassShader (si no, las capas 4-7 se sumarian dos veces).
	Dependency "BaseMapShader" = "Hidden/Custom Unlit/Unlit Terrain BasePass"
	Fallback "Diffuse"
}
