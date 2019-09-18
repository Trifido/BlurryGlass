// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/ShaderTest2"
{
    Properties
    {
		_Color("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
		_NormalTex("Normal Map", 2D) = "white"{}

		_WaterFogColor("Water Fog Color", Color) = (0, 0, 0, 0)
		_WaterFogDensity("Water Fog Density", Range(0, 2)) = 0.1
		_RefractionStrength("Refraction Strength", Range(0, 1)) = 0.25

		_StandarDeviation("Standard Deviation (Gauss only)", Range(0, 0.1)) = 0.02
		_BlurSize("Blur Size", Range(0,0.1)) = 0
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 100

		Cull Off

		GrabPass { "_WaterBackground" }

		//HORIZONTAL PASS
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag 

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0; 
                float4 vertex : SV_POSITION;
				float4 grabPos : TEXCOORD1;
            };

			sampler2D _MainTex, _NormalTex;
            float4 _MainTex_ST;

			#include "LookingThrough.cginc"

            v2f vert (appdata v)
            {
                v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); 
				o.grabPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
				fixed3 norm = tex2D(_NormalTex, i.uv);//fixed3(0, 0, 0);

				fixed3 col = ColorBelowWaterWithRefractions(i.grabPos, norm);
				fixed4 color = fixed4(col, 1);
                return color;
            }
            ENDCG
        }
/*
		GrabPass { "_VerticalBackground" }

		//VERTICAL PASS
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag 

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 grabPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			fixed4 _Color;
			sampler2D _NormalTex;
			float4 _MainTex_ST;

			#include "LookingThrough.cginc"

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex); 
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.grabPos = ComputeGrabScreenPos(o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed3 norm = tex2D(_NormalTex, i.uv);

				fixed3 col = ColorBelowWaterBlurV(i.grabPos, norm);
				fixed4 color = fixed4(col, 0.5) * _Color * tex2D(_MainTex, i.uv);
				return color;
			}
			ENDCG
		}
		*/
    }
}
