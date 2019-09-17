// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/ShaderTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100

		ZWrite Off
		Cull Back
		//ZTest Less
		Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members screenPosition)
#pragma exclude_renderers d3d11
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
				float4 screenPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			#include "LookingThrough.cginc"

            v2f vert (appdata v)
            {
                v2f o;
				//o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				//fixed4 col = ColorBelow(i.vertex);//tex2D(_MainTex, i.uv);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);

				float2 uv = i.screenPos.xy / i.screenPos.w;
				float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
				//Calculamos la distancia de profundidad entre la superficie del agua y la pantalla
				float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(i.screenPos.z);
				//Calculamos la profundidad de los objetos mas profundos de la superfice del agua
				float depthDifference = backgroundDepth - surfaceDepth;

				depthDifference /= 20;
				return fixed4(depthDifference, depthDifference, depthDifference, 1);

				//col.a = 1;
                //return col;
            }
            ENDCG
        }
    }
}
