// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Custom/Hanging Wire" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_Wind1Freq ("Wind 1 Freq", Float) = 0
		_Wind1Amp ("Wind 1 Amp", Float) = 0
		_Wind2Freq ("Wind 2 Freq", Float) = 0
		_Wind2Amp ("Wind 2 Amp", Float) = 0
		_WindPhaseScale ("Wind Phase Scale", Float) = 0
		_Droop ("Droop", Float) = 10
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100
		Pass {
			Tags { "RenderType"="Opaque" }
			Cull Back
			ZWrite On
			ZTest LEqual

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"

			fixed4 _Color;
			float _Wind1Freq;
			float _Wind1Amp;
			float _Wind2Freq;
			float _Wind2Amp;
			float _WindPhaseScale;
			float _Droop;

			struct appdata {
				float4 vertex : POSITION;
				fixed4 color : COLOR; // .r = cuanto se mueve/cuelga el vertice (0 en los anclajes)
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				float4 pos : SV_POSITION;
				UNITY_FOG_COORDS(0)
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

				// Dos ondas de viento con fase dependiente de la posicion mundial (x, y)
				float2 phase = worldPos.xy * _WindPhaseScale + _Time.y * float2(_Wind1Freq, _Wind2Freq);
				float2 waves = sin(phase) * float2(_Wind1Amp, _Wind2Amp);
				float sway = waves.x + waves.y;

				worldPos.z += sway * v.color.x;
				worldPos.y -= _Droop * v.color.x;

				// El original pasa por WorldToObject y vuelve con ObjectToWorld: equivale a usar worldPos directamente.
				o.pos = mul(UNITY_MATRIX_VP, float4(worldPos.xyz, 1.0));
				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = _Color;
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
