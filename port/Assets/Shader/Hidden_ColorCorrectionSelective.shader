// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Hidden/ColorCorrectionSelective" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "" {}
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
			float4 selColor;
			float4 targetColor;

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
				// Peso 0 en el color seleccionado y 1 a partir de la mitad de la distancia de color.
				float dist = length(src.rgb - selColor.rgb);
				float w = min(dist + dist, 1.0);
				return lerp(targetColor, src, w);
			}
			ENDCG
		}
	}
}
