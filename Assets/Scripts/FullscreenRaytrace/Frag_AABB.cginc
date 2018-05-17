#ifndef FRAG_AABB
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
#define FRAG_AABB
#include "Vert.cginc"
#include "Intersect_AABB.cginc"

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


	//// 1 if camera is in front of view, 0 otherwise
	//float front = step(0, cam_Eye.w);
	//// 1 if ray direction is within 90deg of view normal (I think?) 0 otherwise
	//float rayfront = step(0, ray_Eye.w);
	//// 1 if both front and rayfront are true. Necessary to switch p0 and p1 in this case
	//float swap = front*rayfront;

	//// Swap p0 and p1 where either cam_view.w or ray_view.w is negative
	//float3 p0 = (1 - swap)*hits[0].xyz + (swap)*hits[1].xyz;
	//float3 p1 = (swap)*hits[0].xyz + (1 - swap)*hits[1].xyz;

	//// TOOD: Why do we do this
	//p0.xy *= -1;
	//p1.xy *= -1;
	////p0.x *= -1;
	////p1.x *= -1;

	//// RGB result of tracing from p0 to p1 from given UV coords
	//// Result is -1.0f if no hit
	//float3 raytraceResult = raytrace(p0, p1, _eyeUV);

	//raytraceResult *= front * intersects;

	fixed4 col = fixed4(hits[0].xyz * intersects, 1);

	return col;
}

#endif