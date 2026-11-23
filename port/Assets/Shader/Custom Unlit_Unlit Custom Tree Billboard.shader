// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Custom Tree Billboard" {
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
		Cull Back

		CGPROGRAM
		// El original no tiene pase FORWARDADD -> noforwardadd.
		#pragma surface surf ASHToonBillboard vertex:vert addshadow noforwardadd alphatest:_Cutoff exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
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
		};

		// El billboard del original NO usa N.L: solo la atenuacion/sombra cuantizada.
		inline half4 LightingASHToonBillboard(SurfaceOutput s, half3 lightDir, half atten)
		{
			float l = ASHToonFactor(1.0, atten);
			half4 c;
			c.rgb = s.Albedo * _LightColor0.rgb * l;
			c.a = s.Alpha;
			return c;
		}

		inline float4 ASHSmoothTriangleWave(float4 x)
		{
			float4 t = abs(frac(x + 0.5) * 2.0 - 1.0);
			return t * t * (3.0 - 2.0 * t);
		}

		void vert (inout appdata_full v)
		{
			// Orientacion hacia la camara: X del objeto -> derecha de la camara,
			// Z del objeto -> direccion de vision; Y se conserva.
			float3 camRight = normalize(UNITY_MATRIX_V[0].xyz);
			float3 camForward = -normalize(UNITY_MATRIX_V[2].xyz);
			float3 pos = v.vertex.x * camRight + v.vertex.z * camForward + float3(0.0, v.vertex.y, 0.0);
			float3 nrm = v.normal.x * camRight + v.normal.z * camForward + float3(0.0, v.normal.y, 0.0);

			// Viento (igual que Custom Tree, usando la Y ya orientada).
			float phase = dot(unity_ObjectToWorld._m03_m13_m23, float3(1.0, 1.0, 1.0));
			float4 waves = frac((phase + _Time.xxyy) * float4(1.975, 0.793, 0.375, 0.193)) * 2.0 - 1.0;
			waves = ASHSmoothTriangleWave(waves);
			float2 wavesSum = waves.xz + waves.yw;

			float bend = _BendFactor * 0.01;
			float y2 = pos.y * pos.y;
			float uvBend = (y2 * bend + 1.0) * _UVBendFactor * v.texcoord.y;
			float offsetZ = bend * y2 * wavesSum.x + wavesSum.y * uvBend;

			float3 worldPos = mul(unity_ObjectToWorld, float4(pos, 1.0)).xyz;
			worldPos.z += offsetZ;
			float3 objPos = mul(unity_WorldToObject, float4(worldPos, 1.0)).xyz;
			v.vertex.xyz = objPos * _TreeInstanceScale.xyz;
			v.normal = nrm;
		}

		void surf (Input IN, inout SurfaceOutput o)
		{
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb * _TreeInstanceColor.rgb;
			o.Alpha = c.a;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
