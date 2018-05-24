Shader "Unlit/StupidExpensive"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_StencilMask("Mask Layer", Range(0, 255)) = 1
		[Enum(CompareFunction)] _StencilComp("Mask Mode", Int) = 6
	}
		SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 100
		Cull Off

		Pass
	{
		Stencil{
			Ref[_StencilMask]
			Comp [_StencilComp]
		}

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
	};

	sampler2D _MainTex;
	float4 _MainTex_ST;

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		// sample the texture
		float4 col = 0;
		float2 uv = i.uv;
		float s = 0;
		for (int iter = 0; iter<10000; iter++)
		{
			s += 0.151;
			uv += sin(s);
			col += tex2D(_MainTex, uv);
		}

		col /= 10000;
		return col;
	}
		ENDCG
	}
	}
}