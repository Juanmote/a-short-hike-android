// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Unlit/Screen Gradient" {
	Properties {
		_Color1 ("Color 1", Color) = (1,1,1,1)
		_Color2 ("Color 2", Color) = (1,1,1,1)
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 1
		_MainTex ("Texture", 2D) = "white" {}
		_Scale ("Scale", Range(0.001, 1)) = 1
	}
	SubShader {
		Tags { "IGNOREPROJECTOR"="true" "QUEUE"="Transparent" "RenderType"="Transparent" }
		LOD 100

		Pass {
			Tags { "IGNOREPROJECTOR"="true" "QUEUE"="Transparent" "RenderType"="Transparent" }
			Cull Back
			ZWrite Off
			ZTest LEqual
			Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Cutoff;
			fixed4 _Color1;
			fixed4 _Color2;
			float _Scale;

			struct appdata {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 screenPos : TEXCOORD2;
				UNITY_FOG_COORDS(1)
			};

			v2f vert (appdata v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.screenPos = ComputeScreenPos(o.pos);
				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				fixed4 texCol = tex2D(_MainTex, i.uv);
				clip(texCol.a - _Cutoff);

				// Gradiente vertical en coordenadas de pantalla. Equivale a sy/_Scale - (0.5/_Scale - 0.5).
				float sy = i.screenPos.y / i.screenPos.w;
				float s = saturate((sy - 0.5) / _Scale + 0.5);
				float t = 1.0 - s;
				fixed4 grad = lerp(_Color1, _Color2, t);

				fixed4 col = texCol * grad;
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
