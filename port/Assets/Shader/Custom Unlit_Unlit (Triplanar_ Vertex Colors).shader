// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit (Triplanar, Vertex Colors)" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_MainTex2 ("Albedo (RGB)", 2D) = "white" {}
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
		_SideTex ("Albedo Top (RGB)", 2D) = "white" {}
		_Blend ("Sharpness", Range(0, 150)) = 0.5
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#pragma surface surf ASHToon fullforwardshadows alphatest:_Cutoff exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma target 3.0
		#include "ASHToonLighting.cginc"
		
		sampler2D _MainTex;
		sampler2D _MainTex2;
		sampler2D _SideTex;
		float4 _MainTex_ST;
		float4 _SideTex_ST;
		fixed4 _Color;
		float _Blend;

		struct Input {
		    float3 worldPos;
		    float3 worldNormal;
		    float4 color : COLOR;
		};

		void surf (Input IN, inout SurfaceOutput o) {
		    // Pesos por eje a partir de la normal en mundo (sharpness = _Blend).
		    float3 n = normalize(IN.worldNormal);
		    float3 w = exp2(log2(abs(n)) * _Blend);
		    w /= (w.x + w.y + w.z);

		    // Seleccion dura del eje dominante (umbral 0.01, igual que el original).
		    float xFlag = (w.x - w.y - w.z >= 0.01) ? 1.0 : 0.0;
		    float yFlag = (w.y - w.z - xFlag >= 0.01) ? 1.0 : 0.0;
		    float zFlag = (w.z - xFlag - yFlag >= 0.01) ? 1.0 : 0.0;
		    float noneFlag = (xFlag + yFlag + zFlag >= 0.01) ? 0.0 : 1.0;
		    float topWeight = noneFlag + yFlag;   // proyeccion cenital (XZ): eje Y dominante o ninguno

		    // Coordenadas de proyeccion en espacio mundo (el original usa _SideTex_ST.z para ambos ejes de la proyeccion cenital).
		    float2 uvZY = (IN.worldPos.zy + _SideTex_ST.zw) * _SideTex_ST.xy;
		    float2 uvXY = (IN.worldPos.xy + _SideTex_ST.zw) * _SideTex_ST.xy;
		    float2 uvXZ = float2(IN.worldPos.x + _SideTex_ST.z, IN.worldPos.z + _SideTex_ST.z) * _MainTex_ST.xy;

		    fixed3 sideX = tex2D(_SideTex, uvZY).rgb;
		    fixed3 sideZ = tex2D(_SideTex, uvXY).rgb;
		    fixed3 top1 = tex2D(_MainTex, uvXZ).rgb;
		    fixed3 top2 = tex2D(_MainTex2, uvXZ).rgb;
		    // El canal rojo del color de vertice elige la textura superior: r >= 0.5 -> _MainTex, r < 0.5 -> _MainTex2.
		    fixed3 top = (IN.color.r >= 0.5) ? top1 : top2;

		    o.Albedo = (sideX * xFlag + sideZ * zFlag + top * topWeight) * _Color.rgb;
		    o.Alpha = 1.0;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
