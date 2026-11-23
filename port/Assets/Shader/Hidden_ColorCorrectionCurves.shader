// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Hidden/ColorCorrectionCurves" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "" {}
		_RgbTex ("_RgbTex (RGB)", 2D) = "" {}
		_ZCurve ("_ZCurve (RGB)", 2D) = "" {}
		_RgbDepthTex ("_RgbDepthTex (RGB)", 2D) = "" {}
	}
	SubShader {
		Pass {
			Cull Off
			ZWrite Off
			ZTest Always

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _RgbTex;
			sampler2D _ZCurve;
			sampler2D _RgbDepthTex;
			sampler2D_float _CameraDepthTexture;
			float4 _CameraDepthTexture_ST;
			float _Saturation;

			struct appdata {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uvDepth : TEXCOORD1;
			};

			v2f vert (appdata v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.uvDepth = v.texcoord * _CameraDepthTexture_ST.xy + _CameraDepthTexture_ST.zw;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				fixed4 src = tex2D(_MainTex, i.uv);

				// Cada canal usa su fila de la textura de curvas: R en 0.125, G en 0.375, B en 0.625.
				fixed3 rgbCurve = fixed3(
					tex2D(_RgbTex, float2(src.r, 0.125)).r,
					tex2D(_RgbTex, float2(src.g, 0.375)).g,
					tex2D(_RgbTex, float2(src.b, 0.625)).b);
				fixed3 depthCurve = fixed3(
					tex2D(_RgbDepthTex, float2(src.r, 0.125)).r,
					tex2D(_RgbDepthTex, float2(src.g, 0.375)).g,
					tex2D(_RgbDepthTex, float2(src.b, 0.625)).b);

				// Peso de la curva por profundidad (0..1 lineal) sobre la curva de profundidad.
				float depth01 = Linear01Depth(tex2D(_CameraDepthTexture, i.uvDepth).r);
				float zWeight = tex2D(_ZCurve, float2(depth01, 0.5)).r;
				fixed3 col = lerp(rgbCurve, depthCurve, zWeight);

				fixed lum = dot(col, fixed3(0.22, 0.707, 0.071));
				return fixed4(lerp(fixed3(lum, lum, lum), col, _Saturation), src.a);
			}
			ENDCG
		}
	}
}
