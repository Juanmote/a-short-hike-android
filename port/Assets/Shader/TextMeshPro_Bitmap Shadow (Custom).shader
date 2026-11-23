// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "TextMeshPro/Bitmap Shadow (Custom)" {
	Properties {
		_MainTex ("Font Atlas", 2D) = "white" {}
		_FaceTex ("Font Texture", 2D) = "white" {}
		_FaceColor ("Text Color", Color) = (1,1,1,1)
		_ShadowColor ("Shadow Color", Color) = (0,0,0,0)
		_Shadow1X ("Shadow 1X", Float) = 0
		_Shadow1Y ("Shadow 1Y", Float) = 0
		_VertexOffsetX ("Vertex OffsetX", Float) = 0
		_VertexOffsetY ("Vertex OffsetY", Float) = 0
		_MaskSoftnessX ("Mask SoftnessX", Float) = 0
		_MaskSoftnessY ("Mask SoftnessY", Float) = 0
		_ClipRect ("Clip Rect", Vector) = (-32767,-32767,32767,32767)
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255
		_ColorMask ("Color Mask", Float) = 15
	}

	CGINCLUDE
	#include "UnityCG.cginc"

	sampler2D _MainTex;
	sampler2D _FaceTex;
	float4 _FaceTex_ST;
	fixed4 _FaceColor;
	fixed4 _ShadowColor;
	float _Shadow1X;
	float _Shadow1Y;
	float _VertexOffsetX;
	float _VertexOffsetY;
	float4 _ClipRect;
	float _MaskSoftnessX;
	float _MaskSoftnessY;

	struct appdata_t {
		float4 vertex : POSITION;
		fixed4 color : COLOR;
		float2 texcoord0 : TEXCOORD0;
		float2 texcoord1 : TEXCOORD1;
	};

	struct v2f {
		float4 vertex : SV_POSITION;
		fixed4 color : COLOR;
		float2 texcoord0 : TEXCOORD0;
		float2 texcoord1 : TEXCOORD1;
		float4 mask : TEXCOORD2;
	};

	// offset: desplazamiento extra (sombra) en las unidades del vertice; tint: color que multiplica al color del vertice.
	v2f BuildVert (appdata_t input, float2 offset, fixed4 tint)
	{
		v2f output;

		// Medio pixel de desplazamiento + offsets del vertice
		float2 vPosition = input.vertex.xy + offset + float2(_VertexOffsetX, _VertexOffsetY);
		vPosition += (input.vertex.w * 0.5) / _ScreenParams.xy;

		float4 clipPos = UnityObjectToClipPos(float4(vPosition, input.vertex.z, 1.0));

		// Ajuste a pixel de pantalla
		float2 halfScreen = _ScreenParams.xy * 0.5;
		float2 snapped = round((clipPos.xy / clipPos.w) * halfScreen) / halfScreen;
		output.vertex = float4(clipPos.w * snapped, clipPos.zw);

		output.color = input.color * tint;

		// UV de la textura de cara empaquetado en texcoord1.x
		float packedHi = floor(input.texcoord1.x * 0.000244140625);
		float2 faceUV = float2(packedHi, input.texcoord1.x - packedHi * 4096.0);
		output.texcoord1 = faceUV * _FaceTex_ST.xy * 0.001953125 + _FaceTex_ST.zw;
		output.texcoord0 = input.texcoord0;

		// Mascara de ClipRect con suavizado
		float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
		float2 pixelSize = clipPos.w / abs(float2(_ScreenParams.x * UNITY_MATRIX_P[0][0], _ScreenParams.y * UNITY_MATRIX_P[1][1]));
		output.mask = float4(vPosition * 2.0 - clampedRect.xy - clampedRect.zw,
			0.25 / (0.25 * float2(_MaskSoftnessX, _MaskSoftnessY) + pixelSize));
		return output;
	}

	v2f vertShadow (appdata_t input)
	{
		return BuildVert(input, float2(_Shadow1X, _Shadow1Y), _ShadowColor);
	}

	v2f vertFace (appdata_t input)
	{
		return BuildVert(input, float2(0, 0), _FaceColor);
	}

	fixed4 frag (v2f input) : SV_Target
	{
		float2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(input.mask.xy)) * input.mask.zw);
		float clip = m.x * m.y;

		fixed4 c = tex2D(_FaceTex, input.texcoord1);
		c.rgb *= input.color.rgb;
		c.a = tex2D(_MainTex, input.texcoord0).a * input.color.a;
		return c * clip;
	}
	ENDCG

	SubShader {
		Tags { "IGNOREPROJECTOR"="true" "QUEUE"="Transparent" "RenderType"="Transparent" }

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
			#pragma fragment frag
			ENDCG
		}

		// Pase 1: texto
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
			#pragma vertex vertFace
			#pragma fragment frag
			ENDCG
		}
	}
}
