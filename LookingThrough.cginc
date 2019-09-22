#if !defined(LOOKING_THROUGH_INCLUDED)
#define LOOKING_THROUGH_INCLUDED 

sampler2D _CameraDepthTexture, _Background, _HorizontalBackground;
float4 _CameraDepthTexture_TexelSize; 
float4 _Background_TexelSize;
float3 _WaterFogColor;
float _WaterFogDensity;
float _RefractionStrength;
float _BlurSize;
float _StandarDeviation;

#define PI 3.14159265359
#define E 2.71828182846
#define SAMPLES 100

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

float3 VerticalGaussianBlur(float2 uvGrab, float surfaceDepth)
{
	if (_StandarDeviation == 0.0f)
		return tex2D(_HorizontalBackground, uvGrab);

	float3 col = float3(0.0, 0.0, 0.0);
	float sum = 0;
	float stdDevSquared = _StandarDeviation * _StandarDeviation;
	
	for (float ind = 0; ind < SAMPLES; ind++)
	{ 
		float offset = (ind / (SAMPLES - 1) - 0.5) * clamp(_BlurSize, 0.00, 0.04);
		float2 uv = uvGrab + AlignWithGrabTexel(float2(0, offset));
		float pixelDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv)); 
		float diff = saturate(pixelDepth - surfaceDepth);

		if(diff > 0.001f)
		{ 
			float gauss = GaussianFunction(offset, clamp(stdDevSquared, 0.01, 1));
			sum += gauss;
			col += tex2D(_HorizontalBackground, uv).rgb * gauss;
		}
		else
		{
			sum += 1;
			col += float3(0.6, 0.6, 0.6);// tex2D(_HorizontalBackground, uvGrab).rgb;
		}
	}
	col = col / sum;

	return col;
}

float3 HorizontalGaussianBlur(float2 uvGrab, float surfaceDepth)
{
	if (_StandarDeviation == 0.0f)
		return tex2D(_Background, uvGrab);

	float3 col = float3(0.0, 0.0, 0.0);
	float sum = 0;
	float stdDevSquared = _StandarDeviation * _StandarDeviation;

	for (float ind = 0; ind < SAMPLES; ind++)
	{
		float offset = (ind / (SAMPLES - 1) - 0.5) * clamp(_BlurSize, 0.00, 0.04);
		float2 uv = uvGrab + AlignWithGrabTexel(float2(offset, 0));
		float pixelDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
		float diff = saturate(pixelDepth - surfaceDepth);

		if (diff > 0.001f)
		{ 
			float gauss = GaussianFunction(offset, clamp(stdDevSquared, 0.01, 1));
			sum += gauss;
			col += tex2D(_Background, uv).rgb * gauss;
		}
		else
		{
			sum += 1;
			col += float3(0.6, 0.6, 0.6);// tex2D(_VerticalBackground, uvGrab).rgb;
		}
	}
	col = col / sum;

	return col;
}

//BORRAR
/*
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
*/

float3 ColorBelowWaterBlurH(float4 screenPos, float3 tangentSpaceNormal) {
	float2 uvOffset = tangentSpaceNormal.xy * _RefractionStrength;
	uvOffset.y *= _CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
	//Convertimos las UV a coordenadas de textura final de profundidad
	float2 uv = AlignWithGrabTexel((screenPos.xy + uvOffset) / screenPos.w);
	float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	//Calculamos la distancia de profundidad entre la superficie del cristal y la pantalla
	float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
	//Calculamos la profundidad de los objetos mas profundos de la superfice del agua
	float depthDifference = backgroundDepth - surfaceDepth;

	//Saturamos para evitar artefactos
	uvOffset *= saturate(depthDifference);
	uv = AlignWithGrabTexel((screenPos.xy + uvOffset) / screenPos.w);

	if (depthDifference/20 < 0.001f)
		return tex2D(_Background, uv);

	float3 color = float3(0, 0, 0);
	color = HorizontalGaussianBlur(uv, surfaceDepth);
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

	//Saturamos para evitaar artefactos
	uvOffset *= saturate(depthDifference);
	uv = AlignWithGrabTexel((screenPos.xy + uvOffset) / screenPos.w);

	//Si la diferencia de profundidad es practicamente 0 pintamos el background
	//depthDifference /= 20;
	if (depthDifference/20 < 0.001f)
		return tex2D(_HorizontalBackground, uv);

	float3 color = VerticalGaussianBlur(uv, surfaceDepth);

	float3 fogColor = float3(0.0, 0.0, 0.0);
	if (_WaterFogDensity > 0.0)
	{
		//float3 backgroundColor = tex2D(_HorizontalBackground, uv).rgb;
		float fogFactor = exp2(-_WaterFogDensity * depthDifference);
		float3 fogColor = lerp(_WaterFogColor, color, fogFactor);

		color *= fogColor;
	}
	
	return color;
}



#endif