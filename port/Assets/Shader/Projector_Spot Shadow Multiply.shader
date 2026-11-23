// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Projector/Spot Shadow Multiply" {
	Properties {
		_ShadowTex ("Cookie", 2D) = "gray" {}
		_FalloffTex ("FallOff", 2D) = "white" {}
		_CharacterY ("Character Y", Float) = 1000
		_GroundY ("Ground Y", Float) = 1000
	}
	SubShader {
		Tags { "QUEUE"="Transparent" }

		Pass {
			Tags { "QUEUE"="Transparent" }
			Cull Back
			ZWrite Off
			ZTest LEqual
			Blend DstColor Zero, DstColor Zero
			ColorMask RGB
			Offset -1, -1

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#include "UnityCG.cginc"
			float4x4 unity_Projector;
			float4x4 unity_ProjectorClip;

			sampler2D _ShadowTex;
			sampler2D _FalloffTex;
			float _CharacterY;
			float _GroundY;

			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 uvShadow : TEXCOORD0;
				float4 uvFalloff : TEXCOORD1;
				UNITY_FOG_COORDS(2)
				float3 normalW : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
				float4 pos : SV_POSITION;
			};

			v2f vert (appdata v) {
				v2f o;
				o.uvShadow = mul(unity_Projector, v.vertex);
				o.uvFalloff = mul(unity_ProjectorClip, v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.normalW = UnityObjectToWorldNormal(v.normal);
				o.pos = UnityObjectToClipPos(v.vertex);
				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				// Solo sombrea superficies orientadas hacia arriba y entre CharacterY y GroundY.
				float facing = (_CharacterY >= i.worldPos.y) ? 1.0 : 0.0;
				float shadowAmount = facing * i.normalW.y;
				shadowAmount *= (i.worldPos.y >= _GroundY - 1.0) ? 1.0 : 0.0;

				fixed4 cookie = tex2Dproj(_ShadowTex, UNITY_PROJ_COORD(i.uvShadow));

				// Multiplicativo: 1 = sin cambio. La niebla lleva el sombreado hacia 1 (blanco).
				fixed4 col;
				col.rgb = 1.0 + shadowAmount * (cookie.rgb - 1.0);
				col.a = 1.0 - shadowAmount * cookie.a;
				UNITY_APPLY_FOG_COLOR(i.fogCoord, col, fixed4(1,1,1,1));
				return col;
			}
			ENDCG
		}
	}
}
