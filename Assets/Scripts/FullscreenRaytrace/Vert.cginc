#ifndef VERT
#define VERT

uniform float4x4 _FrustumCornersES;
uniform sampler2D _MainTex;
uniform float4 _MainTex_TexelSize;
uniform float4x4 _CameraInvViewMatrix;


// Input to vertex shader
struct appdata
{
	// Remember, the z value here contains the index of _FrustumCornersES to use
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
};

// Output of vertex shader / input to fragment shader
struct v2f
{
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 ray : TEXCOORD1;
};

v2f vert(appdata v)
{
	v2f o;

	// Index passed via custom blit function in FullscreenRaytrace.cs
	half index = v.vertex.z;
	v.vertex.z = 0.1;

	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.uv.xy;

#if UNITY_UV_STARTS_AT_TOP
	if (_MainTex_TexelSize.y < 0)
		o.uv.y = 1 - o.uv.y;
#endif

	// Get the eyespace view ray (normalized)
	o.ray = _FrustumCornersES[(int)index].xyz;

	// Transform the ray from eyespace to worldspace
	// Note: _CameraInvViewMatrix was provided by the script
	o.ray = mul(_CameraInvViewMatrix, o.ray);
	return o;
}
#endif