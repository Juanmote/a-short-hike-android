// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom/Stencil Write" {
	Properties {
	}
	SubShader {
		Tags { "QUEUE"="Geometry+1" "RenderType"="Opaque" }

		Pass {
			Tags { "QUEUE"="Geometry+1" "RenderType"="Opaque" }
			Cull Back
			ZWrite Off
			ZTest LEqual
			ColorMask 0
			Stencil { Ref 2 ReadMask 255 WriteMask 255 Comp Always Pass Keep Fail Keep ZFail Keep }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata {
				float4 vertex : POSITION;
			};

			struct v2f {
				float4 pos : SV_POSITION;
			};

			v2f vert (appdata v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				return fixed4(1.0, 1.0, 0.0, 1.0);
			}
			ENDCG
		}
	}
}
