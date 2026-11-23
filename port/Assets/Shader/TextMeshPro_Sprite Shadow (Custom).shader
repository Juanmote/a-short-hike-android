// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "TextMeshPro/Sprite Shadow (Custom)" {
	Properties {
		_MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		_ShadowColor ("Shadow Color", Color) = (0,0,0,0)
		_Shadow1X ("Shadow 1X", Float) = 0
		_Shadow1Y ("Shadow 1Y", Float) = 0
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255
		_ColorMask ("Color Mask", Float) = 15
		_ClipRect ("Clip Rect", Vector) = (-32767,-32767,32767,32767)
		[Toggle(UNITY_UI_ALPHACLIP)]_UseUIAlphaClip ("Use Alpha Clip", Float) = 0
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "UnityUI.cginc"

	sampler2D _MainTex;
	fixed4 _Color;
	fixed4 _ShadowColor;
	fixed4 _TextureSampleAdd;
	float4 _ClipRect;
	float _Shadow1X;
	float _Shadow1Y;

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

	// Pase 0 (sombra): desplaza el vertice por (_Shadow1X, _Shadow1Y) mas medio pixel de pantalla.
	v2f vertShadow (appdata_t v)
	{
		v2f OUT;
		float2 pos = v.vertex.xy + float2(_Shadow1X, _Shadow1Y) + (v.vertex.w * 0.5) / _ScreenParams.xy;
		OUT.worldPosition = float4(pos, v.vertex.zw);
		OUT.vertex = UnityObjectToClipPos(float4(pos, v.vertex.z, 1.0));
		OUT.color = v.color * _Color;
		OUT.texcoord = v.texcoord;
		return OUT;
	}

	// Pase 1: sprite normal (UI/Default)
	v2f vertSprite (appdata_t v)
	{
		v2f OUT;
		OUT.worldPosition = v.vertex;
		OUT.vertex = UnityObjectToClipPos(v.vertex);
		OUT.color = v.color * _Color;
		OUT.texcoord = v.texcoord;
		return OUT;
	}

	// tint: color por el que se multiplica la muestra (sombra o color del vertice)
	fixed4 ShadeSprite (v2f IN, fixed4 tint)
	{
		half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * tint;

		#ifdef UNITY_UI_CLIP_RECT
		color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
		#endif

		#ifdef UNITY_UI_ALPHACLIP
		clip(color.a - 0.001);
		#endif

		return color;
	}

	fixed4 fragShadow (v2f IN) : SV_Target
	{
		return ShadeSprite(IN, _ShadowColor);
	}

	fixed4 fragSprite (v2f IN) : SV_Target
	{
		return ShadeSprite(IN, IN.color);
	}
	ENDCG

	SubShader {
		Tags { "CanUseSpriteAtlas"="true" "IGNOREPROJECTOR"="true" "PreviewType"="Plane" "QUEUE"="Transparent" "RenderType"="Transparent" }

		// Pase 0: sombra
		Pass {
			Cull Off
			ZWrite Off
			ZTest [unity_GUIZTestMode]
			Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha
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
			#pragma vertex vertShadow
			#pragma fragment fragShadow
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma multi_compile __ UNITY_UI_CLIP_RECT
			ENDCG
		}

		// Pase 1: sprite
		Pass {
			Cull Off
			ZWrite Off
			ZTest [unity_GUIZTestMode]
			Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha
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
			#pragma vertex vertSprite
			#pragma fragment fragSprite
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma multi_compile __ UNITY_UI_CLIP_RECT
			ENDCG
		}
	}
}
