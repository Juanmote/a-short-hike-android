// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Projector/Light" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_ShadowTex ("Cookie", 2D) = "" {}
		_FalloffTex ("FallOff", 2D) = "" {}
	}
	SubShader {
		Tags { "QUEUE"="Transparent" }

		Pass {
			Tags { "QUEUE"="Transparent" }
			Cull Back
			ZWrite Off
			ZTest LEqual
			Blend DstColor One, DstColor One
			ColorMask RGB
			Offset -1, -1

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#include "UnityCG.cginc"
			float4x4 unity_Projector;
			float4x4 unity_ProjectorClip;

			fixed4 _Color;
			sampler2D _ShadowTex;
			sampler2D _FalloffTex;

			struct appdata {
				float4 vertex : POSITION;
			};

			struct v2f {
				float4 uvShadow : TEXCOORD0;
				float4 uvFalloff : TEXCOORD1;
				UNITY_FOG_COORDS(2)
				float4 pos : SV_POSITION;
			};

			v2f vert (appdata v) {
				v2f o;
				o.uvShadow = mul(unity_Projector, v.vertex);
				o.uvFalloff = mul(unity_ProjectorClip, v.vertex);
				o.pos = UnityObjectToClipPos(v.vertex);
				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				fixed falloff = tex2Dproj(_FalloffTex, UNITY_PROJ_COORD(i.uvFalloff)).a;
				fixed4 cookie = tex2Dproj(_ShadowTex, UNITY_PROJ_COORD(i.uvShadow));
				fixed4 col;
				col.rgb = cookie.rgb * _Color.rgb;
				col.a = 1.0 - cookie.a;
				col *= falloff;
				// La niebla oscurece hacia negro porque el blend es multiplicativo.
				UNITY_APPLY_FOG_COLOR(i.fogCoord, col, fixed4(0,0,0,0));
				return col;
			}
			ENDCG
		}
	}
}
