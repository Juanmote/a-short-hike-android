// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Custom Wavy Tree" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
		_MaxDarkness ("Custom Darkness", Range(0, 1)) = 0.25
		_BendFactor ("Bend Factor", Range(0, 32)) = 1
		_UVBendFactor ("UV Bend Factor", Range(0, 32)) = 1
		[HideInInspector]_TreeInstanceColor ("TreeInstanceColor", Vector) = (1,1,1,1)
		[HideInInspector]_TreeInstanceScale ("TreeInstanceScale", Vector) = (1,1,1,1)
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		// Doble cara en todos los pases (tambien el ShadowCaster).
		Cull Off

		CGPROGRAM
		#pragma surface surf ASHToon vertex:vert addshadow fullforwardshadows alphatest:_Cutoff exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma multi_compile_instancing
		#pragma target 3.0
		#include "ASHToonLighting.cginc"

		sampler2D _MainTex;
		fixed4 _Color;
		float _BendFactor;
		float _UVBendFactor;
		float4 _TreeInstanceColor;
		float4 _TreeInstanceScale;

		struct Input {
			float2 uv_MainTex;
			float facing : VFACE;
		};

		inline float4 ASHSmoothTriangleWave(float4 x)
		{
			float4 t = abs(frac(x + 0.5) * 2.0 - 1.0);
			return t * t * (3.0 - 2.0 * t);
		}

		inline float ASHSmoothTriangleWave1(float x)
		{
			float t = abs(frac(x + 0.5) * 2.0 - 1.0);
			return t * t * (3.0 - 2.0 * t);
		}

		void vert (inout appdata_full v)
		{
			float phase = dot(unity_ObjectToWorld._m03_m13_m23, float3(1.0, 1.0, 1.0));
			// Mitad de frecuencia que Custom Tree.
			float4 waves = frac((phase + _Time.xxyy) * float4(0.9875, 0.3965, 0.1875, 0.0965)) * 2.0 - 1.0;
			waves = ASHSmoothTriangleWave(waves);
			float2 wavesSum = waves.xz + waves.yw;

			float3 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)).xyz;

			float bend = _BendFactor * 0.01;
			float y2 = v.vertex.y * v.vertex.y;
			float bendScale = (y2 * bend + 1.0) * _UVBendFactor;
			float uvY = v.texcoord.y;
			float uvY2 = uvY * uvY;

			// Ondulacion que recorre el arbol segun la X de mundo.
			float wave = ASHSmoothTriangleWave1(worldPos.x + _Time.y) + 1.0;
			float zWave = wave * uvY2 * 0.5 * bendScale;
			float offsetZ = bend * y2 * wavesSum.x + wavesSum.y * zWave;
			float offsetX = sin(worldPos.x + _Time.z) * wavesSum.y * bendScale * uvY2 * uvY * 0.25;

			worldPos.x += offsetX;
			worldPos.z += offsetZ;
			float3 objPos = mul(unity_WorldToObject, float4(worldPos, 1.0)).xyz;
			v.vertex.xyz = objPos * _TreeInstanceScale.xyz;
		}

		void surf (Input IN, inout SurfaceOutput o)
		{
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb * _TreeInstanceColor.rgb;
			o.Alpha = c.a;
			// Cara trasera: normal invertida (en espacio tangente).
			o.Normal = float3(0.0, 0.0, IN.facing > 0.0 ? 1.0 : -1.0);
		}
		ENDCG
	}
	Fallback "Diffuse"
}
