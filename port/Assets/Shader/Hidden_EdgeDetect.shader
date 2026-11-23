// Reconstruido para Android (GLES3) a partir del GLSL del juego original.
Shader "Hidden/EdgeDetect" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "" {}
	}
	CGINCLUDE
	#include "UnityCG.cginc"

	sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	sampler2D_float _CameraDepthTexture;
	sampler2D _CameraDepthNormalsTexture;

	// Valores que pone el script del efecto
	float4 _Sensitivity;
	float4 _BgColor;
	float4 _EdgeColor;
	float _BgFade;
	float _SampleDistance;
	float _Exponent;

	struct v2f2 {
		float4 pos : SV_POSITION;
		float2 uv0 : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
		float2 uv2 : TEXCOORD2;
		float2 uv3 : TEXCOORD3;
		float2 uv4 : TEXCOORD4;
	};

	// Igual que el original: solo uv0 (textura de color) se voltea si hace falta.
	inline float2 ColorUV (float2 uv)
	{
		#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			uv.y = 1.0 - uv.y;
		#endif
		return uv;
	}

	// Profundidad lineal 0..1 (1 / (x*z + y))
	inline float LinDepth (float2 uv)
	{
		return Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	}

	// Decodifica profundidad de _CameraDepthNormalsTexture (zw).
	inline float DecodeDepthRG (float2 enc)
	{
		return dot(enc, float2(1.0, 1.0 / 255.0));
	}

	// 1 si la muestra tiene normal y profundidad parecidas al centro.
	inline float CheckSame (float2 centerNormal, float centerDepth, float4 s)
	{
		float2 diff = abs(centerNormal - s.xy) * _Sensitivity.y;
		bool isSameNormal = (diff.x + diff.y) * _Sensitivity.y < 0.1;
		float sampleDepth = DecodeDepthRG(s.zw);
		float zdiff = abs(centerDepth - sampleDepth);
		bool isSameDepth = zdiff * _Sensitivity.x < 0.09 * centerDepth;
		return (isSameNormal && isSameDepth) ? 1.0 : 0.0;
	}

	// Mezcla final comun: fondo y color de borde.
	inline half4 Compose (float2 uv0, float edge)
	{
		half4 original = tex2D(_MainTex, uv0);
		original = lerp(original, _BgColor, _BgFade);
		edge = min(edge, _EdgeColor.w);
		return lerp(original, _EdgeColor, edge);
	}

	// --- Pase 0: borde por normales+profundidad (2 muestras, triangulo) ---
	v2f2 vertTriangle (appdata_img v)
	{
		v2f2 o;
		o.pos = UnityObjectToClipPos(v.vertex);
		float2 d = _MainTex_TexelSize.xy * _SampleDistance;
		o.uv0 = ColorUV(v.texcoord.xy);
		o.uv1 = v.texcoord.xy;
		o.uv2 = v.texcoord.xy - d;
		o.uv3 = v.texcoord.xy + float2(d.x, -d.y);
		o.uv4 = v.texcoord.xy;
		return o;
	}

	half4 fragTriangle (v2f2 i) : SV_Target
	{
		float4 center = tex2D(_CameraDepthNormalsTexture, i.uv1);
		float4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv2);
		float4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv3);
		float2 centerNormal = center.xy;
		float centerDepth = DecodeDepthRG(center.zw);
		float same = CheckSame(centerNormal, centerDepth, sample1) * CheckSame(centerNormal, centerDepth, sample2);
		return Compose(i.uv0, 1.0 - same);
	}

	// --- Pase 1: Roberts cross sobre normales+profundidad ---
	v2f2 vertRoberts (appdata_img v)
	{
		v2f2 o;
		o.pos = UnityObjectToClipPos(v.vertex);
		float2 d = _MainTex_TexelSize.xy * _SampleDistance;
		o.uv0 = ColorUV(v.texcoord.xy);
		o.uv1 = v.texcoord.xy + d;
		o.uv2 = v.texcoord.xy - d;
		o.uv3 = v.texcoord.xy + float2(-d.x, d.y);
		o.uv4 = v.texcoord.xy + float2(d.x, -d.y);
		return o;
	}

	half4 fragRoberts (v2f2 i) : SV_Target
	{
		float4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv1);
		float4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv2);
		float4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv3);
		float4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv4);
		float same = CheckSame(sample1.xy, DecodeDepthRG(sample1.zw), sample2)
		           * CheckSame(sample3.xy, DecodeDepthRG(sample3.zw), sample4);
		return Compose(i.uv0, 1.0 - same);
	}

	// --- Pases 2 y 3: Sobel sobre la profundidad ---
	struct v2fd {
		float4 pos : SV_POSITION;
		float2 uv0 : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
	};

	v2fd vertDepth (appdata_img v)
	{
		v2fd o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv0 = ColorUV(v.texcoord.xy);
		o.uv1 = v.texcoord.xy;
		return o;
	}

	float SobelDepth (float2 uv, bool thin)
	{
		float2 uvDist = _SampleDistance * _MainTex_TexelSize.xy;
		float centerDepth = LinDepth(uv);

		float4 depthsDiag;
		float4 depthsAxis;
		depthsDiag.x = LinDepth(uv + uvDist);                    // arriba derecha
		depthsDiag.y = LinDepth(uv + uvDist * float2(-1, 1));    // arriba izquierda
		depthsDiag.z = LinDepth(uv - uvDist * float2(-1, 1));    // abajo derecha
		depthsDiag.w = LinDepth(uv - uvDist);                    // abajo izquierda
		depthsAxis.x = LinDepth(uv + uvDist * float2(0, 1));     // arriba
		depthsAxis.y = LinDepth(uv - uvDist * float2(1, 0));     // izquierda
		depthsAxis.z = LinDepth(uv + uvDist * float2(1, 0));     // derecha
		depthsAxis.w = LinDepth(uv - uvDist * float2(0, 1));     // abajo

		if (thin) {
			// Solo cuenta el borde del lado mas cercano a la camara
			depthsDiag = max(depthsDiag, centerDepth.xxxx);
			depthsAxis = max(depthsAxis, centerDepth.xxxx);
		}

		depthsDiag -= centerDepth;
		depthsAxis /= centerDepth;

		const float4 HorizDiagCoeff = float4(1, 1, -1, -1);
		const float4 VertDiagCoeff = float4(-1, 1, -1, 1);
		const float4 HorizAxisCoeff = float4(1, 0, 0, -1);
		const float4 VertAxisCoeff = float4(0, 1, -1, 0);

		float4 sobelH = depthsDiag * HorizDiagCoeff + depthsAxis * HorizAxisCoeff;
		float4 sobelV = depthsDiag * VertDiagCoeff + depthsAxis * VertAxisCoeff;
		float sobelX = dot(sobelH, float4(1, 1, 1, 1));
		float sobelY = dot(sobelV, float4(1, 1, 1, 1));
		float sobel = sqrt(sobelX * sobelX + sobelY * sobelY);
		return pow(min(sobel, 1.0), _Exponent);
	}

	half4 fragSobelDepth (v2fd i) : SV_Target
	{
		return Compose(i.uv0, SobelDepth(i.uv1, false));
	}

	half4 fragSobelDepthThin (v2fd i) : SV_Target
	{
		return Compose(i.uv0, SobelDepth(i.uv1, true));
	}

	// --- Pase 4: solo aplica el color de fondo ---
	v2f2 vertBg (appdata_img v)
	{
		v2f2 o;
		o.pos = UnityObjectToClipPos(v.vertex);
		float2 d = _MainTex_TexelSize.xy * _SampleDistance;
		o.uv0 = ColorUV(v.texcoord.xy);
		o.uv1 = v.texcoord.xy - d;
		o.uv2 = v.texcoord.xy + float2(d.x, -d.y);
		o.uv3 = v.texcoord.xy;
		o.uv4 = v.texcoord.xy;
		return o;
	}

	half4 fragBg (v2f2 i) : SV_Target
	{
		half4 original = tex2D(_MainTex, i.uv0);
		return lerp(original, _BgColor, _BgFade);
	}
	ENDCG

	SubShader {
		// Pase 0
		Pass {
			Cull Off ZWrite Off ZTest Always
			CGPROGRAM
			#pragma vertex vertTriangle
			#pragma fragment fragTriangle
			ENDCG
		}
		// Pase 1
		Pass {
			Cull Off ZWrite Off ZTest Always
			CGPROGRAM
			#pragma vertex vertRoberts
			#pragma fragment fragRoberts
			ENDCG
		}
		// Pase 2
		Pass {
			Cull Off ZWrite Off ZTest Always
			CGPROGRAM
			#pragma vertex vertDepth
			#pragma fragment fragSobelDepth
			ENDCG
		}
		// Pase 3
		Pass {
			Cull Off ZWrite Off ZTest Always
			CGPROGRAM
			#pragma vertex vertDepth
			#pragma fragment fragSobelDepthThin
			ENDCG
		}
		// Pase 4
		Pass {
			Cull Off ZWrite Off ZTest Always
			CGPROGRAM
			#pragma vertex vertBg
			#pragma fragment fragBg
			ENDCG
		}
	}
	Fallback Off
}
