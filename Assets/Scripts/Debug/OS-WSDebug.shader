Shader "Unlit/OS-WSDebug"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

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
				float4 vertex_CS : SV_POSITION;
				float4 vertex_OS : TEXCOORD0;
			};

			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex_CS = UnityObjectToClipPos(v.vertex);
				o.vertex_OS = v.vertex;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 vertex_WS = mul(unity_ObjectToWorld, i.vertex_OS);
				float3 vertex_OS2 = mul(unity_WorldToObject, float4(vertex_WS, 0));
				float3 debug = vertex_WS;

				return fixed4(debug,1);
			}
			ENDCG
		}
	}
}
