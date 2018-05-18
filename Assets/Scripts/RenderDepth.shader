﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/RenderDepth"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}
		SubShader
	{
		Pass
	{
		CGPROGRAM

#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"

		uniform sampler2D _MainTex;
	uniform sampler2D _CameraDepthTexture;
	uniform half4 _MainTex_TexelSize;

	struct input
	{
		float4 pos : POSITION;
		half2 uv : TEXCOORD0;
	};

	struct output
	{
		float4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;
	};


	output vert(input i)
	{
		output o;
		o.pos = UnityObjectToClipPos(i.pos);
		o.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, i.uv);
		// why do we need this? cause sometimes the image I get is flipped. see: http://docs.unity3d.com/Manual/SL-PlatformDifferences.html
#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv.y = 1 - o.uv.y;
#endif

		return o;
	}

	fixed4 frag(output o) : COLOR
	{
		float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, o.uv));
		//float dOrigin = distance(o.uv, float2(0.5, 0.5));
		//float scaleFactor = sqrt(pow(dOrigin, 2) + pow(1, 2));
		//depth = depth * scaleFactor;
		return fixed4(depth, 0,0,1);
	}

		ENDCG
	}
	}
}