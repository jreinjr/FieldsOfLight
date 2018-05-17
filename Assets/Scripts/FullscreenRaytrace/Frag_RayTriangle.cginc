#ifndef FRAG_AABB
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
#define FRAG_AABB
#include "Vert.cginc"
#include "Intersect_RayTriangle.cginc"

uniform float3 _CameraWS;
// Eye extrinsics
uniform float4x4 _eyeExtrinsics;
// Eye intrinsics
uniform float4x4 _eyeIntrinsics;
uniform float2 _eyeUV;

fixed4 frag(v2f i) : SV_Target
{
	// View * projection matrix for the current eye
	float4x4 eye_VP = mul(_eyeIntrinsics, _eyeExtrinsics);
	// Transform ray direction from worldspace to eye view projection space
	float4 ray_Eye = mul(eye_VP, float4(i.ray, 0.0f));
	// MAY NEED TO TURN THIS BACK ON!! Maybe not since its a direction?
	ray_Eye.xyz = ray_Eye / ray_Eye.w;

	// Transform camera position from worldspace to current view projection space
	float4 cam_Eye = mul(eye_VP, float4(_CameraWS, 1.0f));
	cam_Eye.xyz = cam_Eye / cam_Eye.w;

	// This is a fucky line
	float3 dir_Eye = ray_Eye - cam_Eye;

	float2x4 hits = intersect(cam_Eye.xyz, dir_Eye.xyz);
	float intersects = step(hits[0].w, hits[1].w);

	// Focusing on intersect for now
	fixed4 col = fixed4(hits[0].xyz * intersects, 1);

	return col;
}

#endif