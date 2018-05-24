Shader "Unlit/ClearStencil"
{
	Properties
	{
		//_StencilMask("Mask Layer", Range(0, 255)) = 0
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
		}
	}
}