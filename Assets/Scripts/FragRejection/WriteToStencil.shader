Shader "Unlit/WriteToStencil"
{
	Properties
	{
		_StencilMask("Mask Layer", Range(0, 255)) = 255
		_MainTex("Texture", 2DArray) = "white" {}

	}
	SubShader
	{
		Tags{ "Queue" = "Background" } // irrelevant for blit, but useful for testing
		LOD 100

		Pass
		{
			ColorMask 0
			ZWrite Off
			Stencil
			{
				Ref [_StencilMask]
				Comp Always
				Pass Replace
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma require 2Darray
			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float3 uv : TEXCOORD0;
			};

			UNITY_DECLARE_TEX2DARRAY(_MainTex);
			float4 _MainTex_ST;
			int _WriteToStencilLayer;

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.z = (float)_WriteToStencilLayer;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = UNITY_SAMPLE_TEX2DARRAY(_MainTex, i.uv);
				// _MainTex r is stencil, g is blend factor
				if (col.r < 0.0000000001f) discard;
				return fixed4(1,1,1, 1);
			}
			ENDCG
		}
	}
}