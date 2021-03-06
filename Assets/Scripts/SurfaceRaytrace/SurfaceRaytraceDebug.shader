﻿Shader "Unlit/SurfaceRaytraceDebug"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BlendTex("Texture", 2DArray) = "white" {}
		_DepthSlice("Depth Slice", Int) = 0
	}
	SubShader
	{
		Tags {"Queue" = "Transparent" "RenderType" = "Opaque" }
		LOD 100
		
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			BlendOp Add
			ZWrite Off
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma require 2Darray
			#include "UnityCG.cginc"
			#include "SurfaceRaytraceHelpers.cginc"
			
			fixed4 frag (v2f input) : SV_Target
			{

				// Fragment worldspace coord
				float3 frag_WS = mul(unity_ObjectToWorld, input.vertex_OS).xyz;
				// Worldspace ray from camera to fragment
				float3 ray_WS = normalize(frag_WS - _WorldSpaceCameraPos);
				// Objectspace ray from camera to fragment
				float3 ray_OS = mul(unity_WorldToObject, ray_WS);

				float3 blendUV;
				blendUV.xy = input.vertex.xy / _ScreenParams.xy;
				blendUV.z = (float)_DepthSlice;
				#if UNITY_UV_STARTS_AT_TOP
				blendUV.y = 1- blendUV.y;
				#endif

				float4 hitCol = float4(0,0,0,0);

				float4 hit_CS = surfaceRaytrace(input.vertex_OS, ray_OS, 90, 0.1);
				hitCol.xyz = tex2D(_MainTex, hit_CS.xy);
				hitCol.w = hit_CS.w;
				//hitCol.w = hit_CS.w;
				// _BlendTex a is stencil
				//hitCol.a = UNITY_SAMPLE_TEX2DARRAY(_BlendTex, blendUV).r;
				//hitCol *= UNITY_SAMPLE_TEX2DARRAY(_BlendTex, input.blendUV).g;
				return fixed4(hitCol);
			}
			ENDCG
		}


		///////////////////////////////////////////////////
		// The next two passes work when the camera is inside frustum.
		// TODO: Make these work nicely with the first two shaders.
		// Think it has to do with something about camera Z conversion
		///////////////////////////////////////////////////

				Pass
			{
				Blend SrcAlpha OneMinusSrcAlpha
				BlendOp Add
				ZWrite Off
				Cull Front
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma require 2Darray
				#include "UnityCG.cginc"
				#include "SurfaceRaytraceHelpers.cginc"

				fixed4 frag(v2f input) : SV_Target
			{

				// Fragment worldspace coord
				float3 frag_WS = mul(unity_ObjectToWorld, input.vertex_OS).xyz;
				// Worldspace ray from camera to fragment
				float3 ray_WS = normalize(frag_WS - _WorldSpaceCameraPos);
				// Objectspace ray from camera to fragment
				float3 ray_OS = mul(unity_WorldToObject, float4(ray_WS, 0));

				float3 blendUV;
				blendUV.xy = input.vertex.xy / _ScreenParams.xy;
				blendUV.z = (float)_DepthSlice;
				#if UNITY_UV_STARTS_AT_TOP
				blendUV.y = 1 - blendUV.y;
				#endif

				float4 hitCol = float4(0,0,0,0);
				float3 cam_OS = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));

				float4 hit_CS = surfaceRaytrace(cam_OS, ray_OS, 100, 0.1);

				hitCol.xyz = tex2D(_MainTex, hit_CS.xy);
				hitCol.w = hit_CS.w;
				//hitCol.w = hit_CS.w;
				// _BlendTex a is stencil
				//hitCol.a = UNITY_SAMPLE_TEX2DARRAY(_BlendTex, blendUV).r;
				//hitCol *= UNITY_SAMPLE_TEX2DARRAY(_BlendTex, input.blendUV).g;
				//float debug = UNITY_SAMPLE_TEX2DARRAY(_BlendTex, blendUV).r;
				return fixed4(hitCol);
			}
				ENDCG
			}

	}
}
