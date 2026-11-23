// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Hidden/ColorCorrectionCurvesSimple" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "" {}
		_RgbTex ("_RgbTex (RGB)", 2D) = "" {}
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
			float _Saturation;

			struct appdata {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert (appdata v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				fixed4 src = tex2D(_MainTex, i.uv);

				// Curva por canal: R en 0.125, G en 0.375, B en 0.625.
				fixed3 rgb = fixed3(
					tex2D(_RgbTex, float2(src.r, 0.125)).r,
					tex2D(_RgbTex, float2(src.g, 0.375)).g,
					tex2D(_RgbTex, float2(src.b, 0.625)).b);

				fixed lum = dot(rgb, fixed3(0.22, 0.707, 0.071));
				return fixed4(lerp(fixed3(lum, lum, lum), rgb, _Saturation), src.a);
			}
			ENDCG
		}
	}
}
