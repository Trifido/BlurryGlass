#if !defined(LOOKING_THROUGH_INCLUDED)
#define LOOKING_THROUGH_INCLUDED 

sampler2D _CameraDepthTexture, _WaterBackground, _VerticalBackground;
float4 _CameraDepthTexture_TexelSize; 
float3 _WaterFogColor;
float _WaterFogDensity;
float _RefractionStrength;
float _BlurSize;
float _StandarDeviation;

#define PI 3.14159265359
#define E 2.71828182846
#define SAMPLES 30

float2 AlignWithGrabTexel(float2 uv)
{
	#if UNITY_UV_STARTS_AT_TOP 
		if (_CameraDepthTexture_TexelSize.y < 0)
		{
			uv.y = 1 - uv.y;
		}
	#endif

	return (floor(uv * _CameraDepthTexture_TexelSize.zw) + 0.5) * abs(_CameraDepthTexture_TexelSize.xy);
}

float GaussianFunction(float offset, float desviation)
{
	return (1 / sqrt(2 * PI * desviation)) * pow(E, -((offset * offset) / (2 * desviation)));
}

float3 VerticalGaussianBlur(float2 uvGrab, float3 col, float surfaceDepth)
{
	if (_StandarDeviation == 0)
		return tex2D(_WaterBackground, uvGrab);

	float sum = 0;
	float stdDevSquared = _StandarDeviation * _StandarDeviation;

	for (float ind = 0; ind < SAMPLES; ind++)
	{ 
		float offset = (ind / (SAMPLES - 1) - 0.5) * _BlurSize + ;
		float2 uv = uvGrab + float2(0, offset);
		float pixelDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
		float diffDepth = pixelDepth - surfaceDepth;

		if (diffDepth > 0)
		{
			float gauss = GaussianFunction(offset, clamp(stdDevSquared+diffDepth, 0.0, 0.1));
			sum += gauss;
			col += tex2D(_VerticalBackground, uv).rgb * gauss;
		}
	}
	col = col / sum;

	return col;
}

float3 HorizontalGaussianBlur(float2 uvGrab, float3 col, float surfaceDepth)
{
	if (_StandarDeviation == 0)
		return tex2D(_WaterBackground, uvGrab);

	float sum = 0;
	float stdDevSquared = _StandarDeviation * _StandarDeviation;

	for (float ind = 0; ind < SAMPLES; ind++)
	{
		float offset = (ind / (SAMPLES - 1) - 0.5) * _BlurSize;
		float2 uv = uvGrab + float2(offset, 0);
		float pixelDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
		float diffDepth = pixelDepth - surfaceDepth;

		if (diffDepth > 0)
		{
			float gauss = GaussianFunction(offset, clamp(stdDevSquared+diffDepth, 0.0, 0.1));
			sum += gauss;
			col += tex2D(_WaterBackground, uv).rgb * gauss;
		}
	}
	col = col / sum;

	return col;
}

float3 ColorBelowWater(float4 screenPos) {
	//Convertimos las UV a coordenadas de textura final de profundidad
	float2 uv = screenPos.xy / screenPos.w;
#if UNITY_UV_STARTS_AT_TOP
	if (_CameraDepthTexture_TexelSize.y < 0)
	{
		uv.y = 1 - uv.y;
	}
#endif
	float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	//Calculamos la distancia de profundidad entre la superficie del agua y la pantalla
	float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
	//Calculamos la profundidad de los objetos mas profundos de la superfice del agua
	float depthDifference = backgroundDepth - surfaceDepth;

	float3 backgroundColor = tex2D(_WaterBackground, uv).rgb;
	float fogFactor = exp2(-_WaterFogDensity * depthDifference);
	return lerp(_WaterFogColor, backgroundColor, fogFactor);

	//return depthDifference / 20;
}

float3 ColorBelowWaterWithRefractions(float4 screenPos, float3 tangentSpaceNormal) {
	float2 uvOffset = tangentSpaceNormal.xy * _RefractionStrength;
	uvOffset.y *= _CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
	//Convertimos las UV a coordenadas de textura final de profundidad
	float2 uv = AlignWithGrabTexel((screenPos.xy + uvOffset) / screenPos.w);
	float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	//Calculamos la distancia de profundidad entre la superficie del agua y la pantalla
	float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
	//Calculamos la profundidad de los objetos mas profundos de la superfice del agua
	float depthDifference = backgroundDepth - surfaceDepth;
	
	//Saturamos para evitar artefactos
	uvOffset *= saturate(depthDifference);
	uv = AlignWithGrabTexel((screenPos.xy + uvOffset) / screenPos.w);

	backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	depthDifference = backgroundDepth - surfaceDepth;

	float3 backgroundColor = tex2D(_WaterBackground, uv).rgb;
	float fogFactor = exp2(-_WaterFogDensity * depthDifference);
	//if (depthDifference > 10)
	//	return float3(1, 0, 0);
	return lerp(_WaterFogColor, backgroundColor, fogFactor);
	//return backgroundColor;

	//return depthDifference / 20;
}

half4 ColorBelow(float4 screenPos) {
	//Convertimos las UV a coordenadas de textura final de profundidad
	float2 uv = screenPos.xy / screenPos.w;
	float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	//Calculamos la distancia de profundidad entre la superficie del agua y la pantalla
	float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
	//Calculamos la profundidad de los objetos mas profundos de la superfice del agua
	float depthDifference = backgroundDepth - surfaceDepth;

	return depthDifference / 20;
}

float3 ColorBelowWaterBlurH(float4 screenPos, float3 tangentSpaceNormal) {
	float2 uvOffset = tangentSpaceNormal.xy * _RefractionStrength;
	uvOffset.y *= _CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
	//Convertimos las UV a coordenadas de textura final de profundidad
	float2 uv = AlignWithGrabTexel((screenPos.xy + uvOffset) / screenPos.w);
	float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	//Calculamos la distancia de profundidad entre la superficie del agua y la pantalla
	float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
	//Calculamos la profundidad de los objetos mas profundos de la superfice del agua
	float depthDifference = backgroundDepth - surfaceDepth;

	//Saturamos para evitar artefactos
	uvOffset *= saturate(depthDifference);
	uv = AlignWithGrabTexel((screenPos.xy + uvOffset) / screenPos.w);

	float3 color2 = 0;
	float3 color = HorizontalGaussianBlur( uv, color2, surfaceDepth);
	return color; 
}

float3 ColorBelowWaterBlurV(float4 screenPos, float3 tangentSpaceNormal) {
	float2 uvOffset = tangentSpaceNormal.xy * _RefractionStrength;
	uvOffset.y *= _CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
	//Convertimos las UV a coordenadas de textura final de profundidad
	float2 uv = AlignWithGrabTexel((screenPos.xy + uvOffset) / screenPos.w);
	float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	//Calculamos la distancia de profundidad entre la superficie del agua y la pantalla
	float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
	//Calculamos la profundidad de los objetos mas profundos de la superfice del agua
	float depthDifference = backgroundDepth - surfaceDepth;

	//Saturamos para evitar artefactos
	uvOffset *= saturate(depthDifference);
	uv = AlignWithGrabTexel((screenPos.xy + uvOffset) / screenPos.w);

	float3 color2 = 0;
	float3 color = VerticalGaussianBlur( uv, color2, surfaceDepth);
	return color;
}



#endif