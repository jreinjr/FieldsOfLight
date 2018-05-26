Shader "Unlit/SurfaceRaytrace"
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
			ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
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


				float4 hit_CS = surfaceRaytrace(input.vertex_OS, ray_OS);
				float4 hit_OS = convertCStoOS(hit_CS);
				float4 hit_WS = float4(mul(unity_ObjectToWorld, float4(hit_OS)).xyz, hit_CS.w);
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
			Blend SrcAlpha OneMinusSrcAlpha
			BlendOp Add
			ZWrite Off

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


				float4 hitCol = float4(0,0,0,0);

				float4 hit_CS = surfaceRaytrace(input.vertex_OS, ray_OS);
				hitCol.xyz = tex2D(_MainTex, hit_CS.xy);
				//hitCol.w = hit_CS.w;
				// _BlendTex a is stencil
				hitCol.a = UNITY_SAMPLE_TEX2DARRAY(_BlendTex, blendUV).r;
				//hitCol *= UNITY_SAMPLE_TEX2DARRAY(_BlendTex, input.blendUV).g;
				float debug = UNITY_SAMPLE_TEX2DARRAY(_BlendTex, blendUV).r;
				return fixed4(hitCol);
			}
			ENDCG
		}
	}
}
