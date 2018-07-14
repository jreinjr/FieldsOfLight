Shader "Unlit/SurfaceRaytrace"
{
	Properties
	{
		_MainTex ("RGB Texture", 2D) = "white" {}
		_zTex("Z Texture", 2D) = "black" {}
		_BlendTex("Blend Texture", 2DArray) = "white" {}
		_DepthSlice("Depth Slice", Int) = 0
		_Cull("_Cull", Float) = 0
	}
	SubShader
	{


		Tags {"Queue" = "Transparent" "RenderType" = "Opaque" }
		LOD 100
		Pass
		{
			//Blend SrcAlpha One
			ZWrite Off
			Cull [_Cull]

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile CAMERA_OUTSIDE CAMERA_INSIDE

			#include "UnityCG.cginc"
			#include "SurfaceRaytraceHelpers.cginc"

			fixed4 frag(v2f input) : SV_Target
			{

				// Fragment worldspace coord
				float3 frag_WS = mul(unity_ObjectToWorld, input.vertex_OS).xyz;
				// Worldspace ray from camera to fragment
				float3 ray_WS = normalize(frag_WS - _WorldSpaceCameraPos);
				// Objectspace ray from camera to fragment
				float3 ray_OS = mul(unity_WorldToObject, ray_WS);
				float3 origin = input.vertex_OS;
				cam_OS = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));


				 
				#if CAMERA_INSIDE
				origin = cam_OS;
				#endif
				float4 hit_CS = surfaceRaytrace(origin, ray_OS, 120, 0.05);
				float4 hit_OS = convertCStoOS(float4(hit_CS.xyz, 1));
				float4 hit_WS = float4(mul(unity_ObjectToWorld, float4(hit_OS.xyz, 1)).xyz, hit_CS.w);
				return hit_WS;
			}
		ENDCG
		}

		Pass
		{
			Stencil
			{
				Ref 255
				Comp Equal
			}
			Blend SrcAlpha One
			ZWrite Off
			Cull [_Cull]

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma require 2Darray
			#pragma multi_compile CAMERA_OUTSIDE CAMERA_INSIDE


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

				float3 origin = input.vertex_OS;
				cam_OS = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));

				#if CAMERA_INSIDE
				origin = cam_OS;
				#endif
				float4 hit_CS = surfaceRaytrace(origin, ray_OS, 120, 0.05);
				float2 rgb_uv = TRANSFORM_TEX(hit_CS.xy, _MainTex);
				hitCol.xyz = tex2D(_MainTex, rgb_uv);
				
				//hitCol.w = hit_CS.w;
				// _BlendTex a is stencil
				hitCol.a = UNITY_SAMPLE_TEX2DARRAY(_BlendTex, blendUV).g;// *hit_CS.w;
				
				//hitCol *= UNITY_SAMPLE_TEX2DARRAY(_BlendTex, blendUV).g;
				float4 debug = float4(1,0,0,1);
				return fixed4(hitCol);
			}
			ENDCG
		}
				
	}
}
