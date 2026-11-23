// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Legacy Shaders/Particles/Additive (No Fog)" {
	Properties {
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
		_MainTex ("Particle Texture", 2D) = "white" {}
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
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _TintColor;
			float _InvFade;
			float _Alpha;
#ifdef SOFTPARTICLES_ON
			sampler2D_float _CameraDepthTexture;
#endif

			struct appdata {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				fixed4 color : COLOR;
				float2 uv : TEXCOORD0;
#ifdef SOFTPARTICLES_ON
				float4 projPos : TEXCOORD2;
#endif
			};

			v2f vert (appdata v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
#ifdef SOFTPARTICLES_ON
				o.projPos = ComputeScreenPos(o.pos);
				o.projPos.z = -UnityObjectToViewPos(v.vertex).z;
#endif
				o.color = v.color;
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				fixed4 col = i.color;
#ifdef SOFTPARTICLES_ON
				float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
				float fade = saturate(_InvFade * (sceneZ - i.projPos.z));
				col.a *= fade;
#endif
				fixed4 c = (col + col) * _TintColor * tex2D(_MainTex, i.uv);
				c.a = saturate(c.a * _Alpha);
				return c;
			}
			ENDCG
		}
	}
}
