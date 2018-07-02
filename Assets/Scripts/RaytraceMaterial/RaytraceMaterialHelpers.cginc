

#ifndef RAYTRACE_MATERIAL_HELPERS
#define RAYTRACE_MATERIAL_HELPERS
#include "UnityCG.cginc"

#pragma vertex vert
#pragma fragment frag

sampler2D _MainTex;
float4 _MainTex_ST;

sampler2D _StencilTex;
float4 _StencilTex_ST;

struct appdata
{
	float4 vertex : POSITION;
};

struct v2f
{
	float4 vertex : SV_POSITION;
};

v2f vert(appdata v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	return o;
}

#endif