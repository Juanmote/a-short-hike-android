// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom/Aura" {
	Properties {
		_Color ("Color", Color) = (0.5,0.5,0.5,0.5)
		_MainTex ("Particle Texture", 2D) = "white" {}
		_HoleTex ("Hole Texture", 2D) = "white" {}
		_HoleTexMix ("Hole Texture Color", Color) = (0.5,0.5,0.5,0.5)
		_HoleThresh ("Hole Threshold", Range(0, 10)) = 0.5
		_InvFade ("Soft Particles Factor", Range(0.01, 3)) = 1
		_Alpha ("Alpha Multiplier", Range(0, 1)) = 1
	}
	SubShader {
		Tags { "IGNOREPROJECTOR"="true" "PreviewType"="Plane" "QUEUE"="Transparent" "RenderType"="Transparent" }
		Pass {
			Tags { "IGNOREPROJECTOR"="true" "PreviewType"="Plane" "QUEUE"="Transparent" "RenderType"="Transparent" }
			Cull Off
			ZWrite Off
			ZTest LEqual
			Blend SrcAlpha One, SrcAlpha One
			ColorMask RGB

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ SOFTPARTICLES_ON
			#pragma target 3.0
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _HoleTex;
			float4 _MainTex_ST;
			float4 _HoleTex_ST;
			fixed4 _Color;
			fixed4 _HoleTexMix;
			float _HoleThresh;
			float _InvFade;
			float _Alpha;
			sampler2D_float _CameraDepthTexture;

			struct appdata {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				fixed4 color : COLOR;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				#ifdef SOFTPARTICLES_ON
				float4 projPos : TEXCOORD2;
				#endif
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				o.uv0 = v.uv0 * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv1 = v.uv1 * _HoleTex_ST.xy + _HoleTex_ST.zw;
				#ifdef SOFTPARTICLES_ON
				o.projPos = ComputeScreenPos(o.pos);
				COMPUTE_EYEDEPTH(o.projPos.z);
				#endif
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float4 col = 2.0 * i.color;
				#ifdef SOFTPARTICLES_ON
				float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
				float partZ = i.projPos.z;
				col.a *= saturate(_InvFade * (sceneZ - partZ));
				#endif
				col *= _Color * tex2D(_MainTex, i.uv0);
				float alpha = saturate(col.a * _Alpha);

				// Agujero: luminancia de la textura tintada, escalada por el umbral
				float3 hole = tex2D(_HoleTex, i.uv1).rgb * _HoleTexMix.rgb;
				float holeMask = dot(hole, float3(0.3, 0.59, 0.11)) * _HoleThresh;

				return fixed4(col.rgb, holeMask * alpha);
			}
			ENDCG
		}
	}
}
