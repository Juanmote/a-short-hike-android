// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom Unlit/Unlit Clouds" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_AttenuationThreshold ("Attenuation Threshold", Range(-1, 1)) = 0
		_ShadowBitDepth ("Shadow Bit Depth", Range(0, 8)) = 1
		_ScrollSpeed ("Scroll Speed", Float) = 1
		_DepthFactor ("Depth Factor", Float) = 0.05
		_DistortTex ("Distortion Normals", 2D) = "white" {}
		_DistortStrength ("Distortion Strength", Range(-1, 1)) = 0
		_DistortSpeed ("Distort Speed", Float) = 1
		_CameraFadeStart ("Camera Fade Near", Float) = 0.1
		_CameraFadeEnd ("Camera Fade Far", Float) = 0.2
		_CameraFarFadeStart ("Camera Far Fade Near", Float) = 0.1
		_CameraFarFadeEnd ("Camera Far Fade Far", Float) = 0.2
	}
	SubShader {
		Tags { "QUEUE"="Transparent" "RenderType"="Transparent" }
		LOD 200
		Cull Back
		ZWrite Off
		ZTest LEqual
		ColorMask RGB

		CGPROGRAM
		#pragma surface surf ASHClouds vertex:vert alpha:fade exclude_path:deferred exclude_path:prepass nolightmap nodynlightmap nodirlightmap nometa
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _DistortTex;
		sampler2D_float _CameraDepthTexture;
		float4 _MainTex_ST;
		float4 _DistortTex_ST;
		fixed4 _Color;
		float _AttenuationThreshold;
		float _ShadowBitDepth;
		float _ScrollSpeed;
		float _DepthFactor;
		float _DistortStrength;
		float _DistortSpeed;
		float _CameraFadeStart;
		float _CameraFadeEnd;
		float _CameraFarFadeStart;
		float _CameraFarFadeEnd;

		struct Input {
			float3 worldPos;
			float4 screenPos;
			float eyeDepth;
			float4 scroll;
		};

		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);
			float3 viewPos = UnityObjectToViewPos(v.vertex);
			o.eyeDepth = -viewPos.z;
			// xy: scroll de la distorsion, zw: scroll de la textura principal
			o.scroll = frac(_Time.yzxy * float4(_DistortSpeed, _DistortSpeed, _ScrollSpeed, _ScrollSpeed));
		}

		// Las nubes no reciben luz directa: el color sale integramente de la emision.
		inline half4 LightingASHClouds (SurfaceOutput s, half3 lightDir, half atten)
		{
			return half4(0, 0, 0, s.Alpha);
		}

		void surf (Input IN, inout SurfaceOutput o) {
			float2 distortUV = IN.worldPos.xz * _DistortTex_ST.xy + _DistortTex_ST.zw + IN.scroll.xy;
			float4 d = tex2D(_DistortTex, distortUV);
			float2 distort = float2(d.w * d.x, d.y) * 2.0 - 1.0;

			float2 uv = IN.worldPos.xz * (_MainTex_ST.xy * 0.01 + _MainTex_ST.zw) + IN.scroll.zw;
			uv += distort * _DistortStrength;
			float4 tex = tex2D(_MainTex, uv);

			float shape = round(tex.a);
			clip(shape - 0.01);

			// Fade por profundidad contra la geometria de detras (cuantizado)
			float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)));
			float depthFade = saturate((sceneZ - IN.eyeDepth) * _DepthFactor);
			depthFade = floor(depthFade * _ShadowBitDepth + _AttenuationThreshold) / max(_ShadowBitDepth, 0.01);
			float a = depthFade * shape;

			// Fade por distancia a la camara (cerca y lejos)
			float z = IN.eyeDepth * _ProjectionParams.w;
			float nearFade = saturate((z - _CameraFadeStart) / (_CameraFadeEnd - _CameraFadeStart));
			float farFade = saturate(1.0 - (z - _CameraFarFadeStart) / (_CameraFarFadeEnd - _CameraFarFadeStart));
			a *= nearFade * farFade;

			float3 col = tex.rgb * _Color.rgb;
			o.Albedo = col;
			o.Emission = col;
			o.Alpha = a * _Color.a;
		}
		ENDCG
	}
	Fallback "Diffuse"
}
