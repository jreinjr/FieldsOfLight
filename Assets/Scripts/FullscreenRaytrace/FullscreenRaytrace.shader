// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/FullscreenRaytrace"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_zTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
	// No culling or depth
	Cull Off ZWrite Off ZTest Always

	Pass
	{
	CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
	#pragma exclude_renderers gles
	#pragma vertex vert
	#pragma fragment frag
			
	#include "UnityCG.cginc"
	// Vertex shader is #included in frag shader
	#include "Frag_RayTriangle.cginc"
	#include "Raytrace.cginc"
	
	ENDCG
	}
	}
}
