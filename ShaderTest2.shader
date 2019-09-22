// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/ShaderTest2"
{
    Properties
    {
		_Color("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
		_DistortionTex("Distortion Map", 2D) = "white"{}

		//Gaussian Blur two steps
		_StandarDeviation("Standard Deviation (Gauss only)", Range(0, 1)) = 0.02
		_BlurSize("Blur Size", Range(0,0.1)) = 0 

		//Fog Material & Distortion
		_WaterFogColor("Water Fog Color", Color) = (0, 0, 0, 0)
		_WaterFogDensity("Water Fog Density", Range(0, 2)) = 0.1
		_RefractionStrength("Refraction Strength", Range(0, 1)) = 0.25 

		//Wave Simulator
		 [Toggle] _WaveSimulator("Wave Simulator", Float) = 0
		_FirstWave("First Wave (dir, steepness, wavelength)", Vector) = (1, 0, 0.5, 10)
		_SecondWave("Second Wave (dir, steepness, wavelength)", Vector) = (0,1,0.25,20)
		_ThirdWave("Third Wave (dir, steepness, wavelength)", Vector) = (1,1,0.15,10)
		_Speed("Speed", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 100

		Cull Off
		ZWrite On 

		GrabPass { "_Background" }

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

            sampler2D _MainTex;
            float4 _MainTex_ST;

			#include "LookingThrough.cginc"
			#include "Flow.cginc"

            v2f vert (appdata v)
            {
                v2f o;

				if (_WaveSimulator > 0)
				{
					v.vertex += WaveSimulation(_FirstWave, v.vertex);
					v.vertex += WaveSimulation(_SecondWave, v.vertex);
					v.vertex += WaveSimulation(_ThirdWave, v.vertex);
				}

				o.vertex = UnityObjectToClipPos(v.vertex); 
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); 
				o.grabPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture 
				fixed3 col = ColorBelowWaterBlurH(i.grabPos, fixed3(0, 0, 0));
				fixed4 color = fixed4(col, 0.5);
                return color;
            }
            ENDCG
        }

		GrabPass { "_HorizontalBackground" }

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
			sampler2D _DistortionTex;
			float4 _MainTex_ST;

			#include "LookingThrough.cginc" 
			#include "Flow.cginc"

			v2f vert(appdata v)
			{ 
				v2f o;

				if (_WaveSimulator > 0)
				{
					v.vertex += WaveSimulation(_FirstWave, v.vertex);
					v.vertex += WaveSimulation(_SecondWave, v.vertex);
					v.vertex += WaveSimulation(_ThirdWave, v.vertex);
				}

				o.vertex = UnityObjectToClipPos(v.vertex); 

				

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.grabPos = ComputeGrabScreenPos(o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				//fixed3 norm = WaveNormal();
				fixed3 distortion = tex2D(_DistortionTex, i.uv);

				fixed3 col = ColorBelowWaterBlurV(i.grabPos, distortion);

				if (_WaterFogDensity > 0.0)
					return fixed4(col, 0.5);
				else
					return fixed4(col, 0.5) *_Color* tex2D(_MainTex, i.uv);
			}
			ENDCG
		}
    }
}
