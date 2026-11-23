// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Mist" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_CutoffTex ("Cutoff", 2D) = "white" {}
		_CutoffMultiplier ("Cutoff Multiplier", Float) = 1
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
		_GradientFade ("Gradient Fade", Float) = 1
		_ScrollSpeed ("Scroll Speed", Float) = 1
		_DepthFactor ("Depth Factor", Float) = 0.05
		_DistortTex ("Distortion Normals", 2D) = "white" {}
		_DistortStrength ("Distortion Strength", Range(-1, 1)) = 0
		_DistortSpeed ("Distort Speed", Float) = 1
	}
	SubShader {
		Tags { "QUEUE"="Transparent" "RenderType"="Transparent" }
		LOD 200
		Cull Back
		ZWrite Off
		ZTest LEqual
		ColorMask RGB

		CGPROGRAM
		#pragma surface surf ASHMist vertex:vert alpha:fade exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _CutoffTex;
		sampler2D _DistortTex;
		sampler2D_float _CameraDepthTexture;
		float4 _DistortTex_ST;
		fixed4 _Color;
		float _CutoffMultiplier;
		float _AttenuationThreshold;
		float _ShadowBitDepth;
		float _GradientFade;
		float _ScrollSpeed;
		float _DepthFactor;
		float _DistortStrength;
		float _DistortSpeed;

		struct Input {
			float2 uv_MainTex;
			float2 uv_CutoffTex;
			float3 worldPos;
			float4 screenPos;
			float eyeDepth;
		};

		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.eyeDepth = -UnityObjectToViewPos(v.vertex).z;
		}

		// La niebla no recibe luz directa: el color (_Color) sale de la emision.
		inline half4 LightingASHMist (SurfaceOutput s, half3 lightDir, half atten)
		{
			return half4(0, 0, 0, s.Alpha);
		}

		void surf (Input IN, inout SurfaceOutput o) {
			// Fade por profundidad (cuantizado)
			float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)));
			float depthFade = saturate((sceneZ - IN.eyeDepth) * _DepthFactor);
			depthFade = floor(depthFade * _ShadowBitDepth + _AttenuationThreshold) / max(_ShadowBitDepth, 0.01);

			// Distorsion
			float2 distortUV = IN.worldPos.xz * _DistortTex_ST.xy + _DistortTex_ST.zw + _Time.yz * _DistortSpeed;
			float4 d = tex2D(_DistortTex, distortUV);
			float2 distort = float2(d.w * d.x, d.y) * 2.0 - 1.0;

			float2 uv = _Time.xy * _ScrollSpeed + IN.uv_MainTex + distort * _DistortStrength;
			float4 tex = tex2D(_MainTex, uv);
			float a = depthFade * round(tex.a) * _Color.a;

			// Mascara con la textura de corte y el degradado vertical de uv
			float cut = tex2D(_CutoffTex, IN.uv_CutoffTex).x * _CutoffMultiplier;
			float gradient = saturate(IN.uv_CutoffTex.y * _GradientFade);
			float mask = (cut * gradient >= tex.r) ? 1.0 : 0.0;

			o.Albedo = _Color.rgb;
			o.Emission = _Color.rgb;
			o.Alpha = gradient * mask * a;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
