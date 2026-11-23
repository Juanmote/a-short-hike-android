// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "UI/Premultiplied Default" {
	Properties {
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255
		_ColorMask ("Color Mask", Float) = 15
		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
	}
	SubShader {
		Tags { "CanUseSpriteAtlas"="true" "IGNOREPROJECTOR"="true" "PreviewType"="Plane" "QUEUE"="Transparent" "RenderType"="Transparent" }

		Pass {
			Name "Default"
			Cull Off
			ZWrite Off
			ZTest [unity_GUIZTestMode]
			Blend One OneMinusSrcAlpha, One OneMinusSrcAlpha
			ColorMask [_ColorMask]
			Stencil {
				Ref [_Stencil]
				ReadMask [_StencilReadMask]
				WriteMask [_StencilWriteMask]
				Comp [_StencilComp]
				Pass [_StencilOp]
				Fail Keep
				ZFail Keep
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma multi_compile __ UNITY_UI_CLIP_RECT
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;
			// Global que pone el juego: 1 = el rgb ya viene premultiplicado, 0 = se premultiplica por alfa aqui.
			float _PremultiplyAlpha;

			struct appdata_t {
				float4 vertex : POSITION;
				float4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
			};

			v2f vert (appdata_t v)
			{
				v2f OUT;
				OUT.worldPosition = v.vertex;
				OUT.vertex = UnityObjectToClipPos(v.vertex);
				OUT.texcoord = v.texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
				OUT.color = v.color * _Color;
				return OUT;
			}

			fixed4 frag (v2f IN) : SV_Target
			{
				half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;

				float clipMask = 1.0;
				#ifdef UNITY_UI_CLIP_RECT
				clipMask = UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
				#endif
				float a = color.a * clipMask;

				#ifdef UNITY_UI_ALPHACLIP
				clip(a - 0.001);
				#endif

				// rgb *= (1 - a) * _PremultiplyAlpha + a  -> con _PremultiplyAlpha = 1 el rgb queda tal cual; con 0 se premultiplica por alfa
				float premul = _PremultiplyAlpha * (1.0 - a) + a;
				float3 rgb = (a == 0.0) ? float3(0, 0, 0) : color.rgb * premul;
				return fixed4(rgb, a);
			}
			ENDCG
		}
	}
}
