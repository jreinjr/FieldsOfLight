#ifndef SURFACE_RAYTRACE_HELPERS
#define SURFACE_RAYTRACE_HELPERS
#include "UnityCG.cginc"

struct appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
};

struct v2f
{
	float4 vertex_OS: TEXCOORD0;
	float4 vertex : SV_POSITION;
};

sampler2D _MainTex;
sampler2D _zTex;
UNITY_DECLARE_TEX2DARRAY(_BlendTex);
int _DepthSlice;
int _isInside;
uniform float _farClip;
uniform float _nearClip;
float3 cam_OS;

v2f vert(appdata v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.vertex_OS = v.vertex;
	return o;
}

float4 convertOStoCS(float4 OS) {
	// "Clipspace" coordinate - xy is UV, z is linear depth (0 nearclip, 1 farclip)
	float4 vertex_CS = OS;
	vertex_CS.xy = vertex_CS.xy / vertex_CS.z;
	vertex_CS.xy = (vertex_CS.xy + 1) / 2;
	return vertex_CS;
}

float4 convertCStoOS(float4 CS) {
	// "Clipspace" coordinate - xy is UV, z is linear depth (0 nearclip, 1 farclip)
	float4 vertex_OS = CS;
	vertex_OS.xy = vertex_OS.xy * 2 - 1;
	vertex_OS.xy = vertex_OS.xy * vertex_OS.z;
	
	return vertex_OS;
}

//TODO: For some reason this is only working properly
// when nearClip >= 1
float LinearEyeDepthFromFile(float d) {
	float x = -1 + _farClip / _nearClip;
	float y = 1;
	float z = x / _farClip;
	float w = 1 / _farClip;
	return 1.0 / (z * d + w);
}

float zConvert(float z) {
	if (z == 0) return 10000;
	return LinearEyeDepthFromFile(pow((z), 2.22));
}

// origin is the objectspace point of first intersection with the frustum
// dir is objectspace ray (origin - cameraPosition)
float4 surfaceRaytrace(float3 origin, float3 dir, uint max_steps, float orig_step_size) {
	float step_size = orig_step_size;
	float hitTolerance = orig_step_size * 4;
	float refineTolerance = orig_step_size * 0.1;
	uint refine_steps = 8;
	float3 hit_OS = origin;
	float4 hit_CS = (0,0,0,0);
	bool hitIsInsideFrustum = false;


	[loop]
	for (uint i = 0; i < max_steps; i++)
	{

		hit_CS = convertOStoCS(float4(hit_OS, 0));
		float stored_depth = zConvert(tex2D(_zTex, hit_CS.xy).r);

		if (hit_CS.x < 1.0 && hit_CS.y < 1.00 && hit_CS.x > 0 && hit_CS.y >  0) {
			hitIsInsideFrustum = true;
		}

		if (hitIsInsideFrustum &&(hit_CS.x > 1.0 || hit_CS.y > 1.0 || hit_CS.x < -0.00 || hit_CS.y < -0.00))
		{
			break;
		}

		if (hit_CS.z >= (stored_depth - hitTolerance * hit_CS.z) && hit_CS.z <= (stored_depth + hitTolerance * hit_CS.z)) {
			[loop]
			for (uint j = 0; j < refine_steps; j++)
			{
				if (hit_CS.z >= (stored_depth - refineTolerance * hit_CS.z) && hit_CS.z <= (stored_depth + refineTolerance * hit_CS.z)) {
					//hit_CS.w = 1;
					hit_CS.w = distance(cam_OS, hit_OS);
					break;
				}
				else if (hit_CS.z > stored_depth && hit_CS.z < stored_depth + hit_CS.z) {
					step_size = step_size * 0.5;
					hit_OS -= dir * step_size * hit_CS.z;
				}
				else {
					hit_OS += dir * step_size * hit_CS.z;

				}
				hit_CS = convertOStoCS(float4(hit_OS, 0));
				stored_depth = zConvert(tex2D(_zTex, hit_CS.xy).r);
			}
			if (hit_CS.z >= (stored_depth - refineTolerance * hit_CS.z *2) && hit_CS.z <= (stored_depth + refineTolerance * hit_CS.z * 2))
			{
				hit_CS.w = distance(cam_OS, hit_OS);
				//hit_CS.w = 1;
			}
		}
		
		else {
			step_size = orig_step_size;
			hit_OS += dir * step_size * hit_CS.z;
		}

	}
	//return float4(dir, 1);

	return hit_CS;
}

#endif
