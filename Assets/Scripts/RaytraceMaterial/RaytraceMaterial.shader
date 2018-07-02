Shader "Unlit/RaytraceMaterial"
{

	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_StencilTex("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		/////////////////////////////////////////////
		// ROUGH PASS
		/////////////////////////////////////////////
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature PROXY_ON
			
			#include "RaytraceMaterialHelpers.cginc"

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = (0,0,0,0);
				#if PROXY_ON
				float2 screen_uv = i.vertex.xy / _ScreenParams.xy;
				screen_uv = TRANSFORM_TEX(screen_uv, _MainTex);
				col = fixed4(screen_uv, 0, 1);
				#endif
				return col;
			}
			ENDCG
		}

		/////////////////////////////////////////////
		// STENCIL PASS
		/////////////////////////////////////////////
		Pass
		{
			ColorMask 0
			ZWrite Off
			Stencil
			{
				Ref 1
				Comp Always
				Pass Replace
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature STENCIL_ON
			#include "RaytraceMaterialHelpers.cginc"

			fixed4 frag(v2f i) : SV_Target
			{
				float2 screen_uv = i.vertex.xy / _ScreenParams.xy;
				screen_uv = TRANSFORM_TEX(screen_uv, _StencilTex);


				// sample the texture
				fixed4 col = tex2D(_StencilTex, screen_uv);
				
				#if STENCIL_ON
				if (col.r < 0.000000000000001f) discard;
				#endif

				return col;
			}
			ENDCG
		}

		/////////////////////////////////////////////
		// FINE PASS
		/////////////////////////////////////////////
		Pass
		{
			Stencil
			{
				Ref 1
				Comp Equal
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "RaytraceMaterialHelpers.cginc"

			fixed4 frag(v2f i) : SV_Target
			{
				float2 screen_uv = i.vertex.xy / _ScreenParams.xy;
				screen_uv = TRANSFORM_TEX(screen_uv, _MainTex);

				fixed4 col = tex2D(_MainTex, screen_uv);
				return col;
			}
			ENDCG

		}
	}
	CustomEditor "RaytraceMaterialEditor"
}
