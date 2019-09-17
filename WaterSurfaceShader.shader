Shader "Custom/WaterSurfaceShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalTex("Normal Map", 2D) = "white"{}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0

		_WaterFogColor("Water Fog Color", Color) = (0, 0, 0, 0)
		_WaterFogDensity("Water Fog Density", Range(0, 2)) = 0.1
		_RefractionStrength("Refraction Strength", Range(0, 1)) = 0.25

		_StandarDeviation("Standard Deviation (Gauss only)", Range(0, 0.1)) = 0.02
		_BlurSize("Blur Size", Range(0,0.1)) = 0
    }
    SubShader
    {
		//HORIZONTAL PASS
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200

		Cull Off

		GrabPass { "_WaterBackground" } 

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard alpha finalcolor:ResetAlpha

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

		#include "LookingThrough.cginc"
        sampler2D _MainTex;
		sampler2D _NormalTex;

        struct Input
        {
            float2 uv_MainTex;
			float4 screenPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

		void ResetAlpha(Input IN, SurfaceOutputStandard o, inout fixed4 color) {
			color.a = 1;
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
			o.Normal = float3(0, 0, 0);// tex2D(_NormalTex, IN.uv_MainTex);
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Emission = ColorBelowWaterBlurV(IN.screenPos, o.Normal) * (1 - c.a);
        }
		
        ENDCG

		//VERTICAL PASS
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
		LOD 200

		Cull Off

		GrabPass { "_WaterBackground" }

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard alpha finalcolor:ResetAlpha

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		#include "LookingThrough.cginc"
		sampler2D _MainTex;
		sampler2D _NormalTex;

		struct Input
		{
			float2 uv_MainTex;
			float4 screenPos;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		void ResetAlpha(Input IN, SurfaceOutputStandard o, inout fixed4 color) {
			color.a = 1;
		}

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
			o.Normal = tex2D(_NormalTex, IN.uv_MainTex);
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Emission = ColorBelowWaterBlurH(IN.screenPos, o.Normal) * (1 - c.a);
		}
			ENDCG
    } 
}
