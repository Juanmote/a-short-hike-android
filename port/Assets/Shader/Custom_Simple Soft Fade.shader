// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom/Simple Soft Fade" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Fade ("Fade", Range(0, 1)) = 1
		_InvFade ("Soft Particles Factor", Range(0.01, 3)) = 1
	}
	SubShader {
		Tags { "QUEUE"="Transparent" "RenderType"="Transparent" }
		LOD 200
		Cull Back
		ZWrite Off
		ZTest LEqual
		ColorMask RGB

		CGPROGRAM
		#pragma surface surf ASHSoftFade vertex:vert alpha:fade noforwardadd exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D_float _CameraDepthTexture;
		fixed4 _Color;
		float _Fade;
		float _InvFade;
		// Global que pone el juego.
		float _PremultiplyAlpha;

		struct Input {
			float2 uv_MainTex;
			float4 screenPos;
			float eyeDepth;
		};

		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.eyeDepth = -UnityObjectToViewPos(v.vertex).z;
		}

		// Sin luz directa: el color sale de la emision.
		inline half4 LightingASHSoftFade (SurfaceOutput s, half3 lightDir, half atten)
		{
			return half4(0, 0, 0, s.Alpha);
		}

		void surf (Input IN, inout SurfaceOutput o) {
			float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)));
			float soft = saturate((sceneZ - IN.eyeDepth) * _InvFade);

			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Emission = c.rgb;
			o.Alpha = soft * (c.a * _Fade + _PremultiplyAlpha * 0.4);
		}
		ENDCG
	}
	Fallback "Diffuse"
}
