Shader "Unlit/WriteToStencil"
{
	Properties
	{
		_StencilMask("Mask Layer", Range(0, 255)) = 255
		_MainTex("Texture", 2D) = "white" {}

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
			#pragma target 2.0
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float2 texcoord : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord);
				if (col.r < 0.001f) discard;
				return fixed4(1,1,1,1);
			}
			ENDCG
		}
	}
}