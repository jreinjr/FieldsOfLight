// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/FullscreenRaytrace"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_zTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
	// No culling or depth
	Cull Off ZWrite Off ZTest Always

	Pass
	{
	CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
	#pragma vertex vert
	#pragma fragment frag
			
	#include "UnityCG.cginc"
	// Provided by our script
	uniform float4x4 _FrustumCornersES;
	uniform float3 _CameraWS;
	uniform sampler2D _MainTex;
	uniform sampler2D _rgbTex;
	uniform sampler2D _zTex;
	uniform float4 _MainTex_TexelSize;
	uniform float4x4 _CameraInvViewMatrix;
	// Eye extrinsics
	uniform float4x4 _eyeExtrinsics;
	// Eye intrinsics
	uniform float4x4 _eyeIntrinsics;
	uniform float2 _eyeUV;

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




	// Assert: bounding box is range -1 to 1 in all dimensions
	// Return: start and end intersection points along ray plus extra info
	// TODO: Precompute inverse of dir to avoid divisions
	float2x4 intersect(float3 origin, float3 dir) {

		// AABB range -1 to 1 in all dimensions
		float3 box_min = float3(-1.0f, -1.0f, -1.0f);
		float3 box_max = float3(1.0f, 1.0f, 1.0f);

		// "Distance to near plane divided by how long it'll take to get there"
		float tx1 = (box_min.x - origin.x) / dir.x;
		float tx2 = (box_max.x - origin.x) / dir.x;

		float tmin = min(tx1, tx2);
		float tmax = max(tx1, tx2);

		float ty1 = (box_min.y - origin.y) / dir.y;
		float ty2 = (box_max.y - origin.y) / dir.y;

		tmin = max(tmin, min(ty1, ty2));
		tmax = min(tmax, max(ty1, ty2));

		float tz1 = (box_min.z - origin.z) / dir.z;
		float tz2 = (box_max.z - origin.z) / dir.z;

		tmin = max(tmin, min(tz1, tz2));
		tmax = min(tmax, max(tz1, tz2));

		// hits[0].xyz = tmin intersection point (or origin if inside box)
		// hits[1].xyz = tmax intersection point
		// hits[0].w = tmin
		// hits[1].w = tmax
		float2x4 hits;

		// Compute intersection point for tmin
		hits[0].x = tmin * dir.x + origin.x;
		hits[0].y = tmin * dir.y + origin.y;
		hits[0].z = tmin * dir.z + origin.z;

		// 1 if origin is inside box, set hits[0].xyz to origin point
		//float origin_inside = step(tmin, 0);
		//hits[0].xyz = hits[0].xyz * (1. - origin_inside) + origin.xyz * origin_inside;

		// Compute intersection point for tmax
		hits[1].x = tmax * dir.x + origin.x;
		hits[1].y = tmax * dir.y + origin.y;
		hits[1].z = tmax * dir.z + origin.z;

		hits[0].w = tmin;
		hits[1].w = tmax;

		return (hits);
	}

	// TODO: Replace magic numbers with variables 
	float zConvert(float z) {
		return  (pow(z, 2.2)) * 0.1;
	}

	float3 raytrace(float3 start, float3 end, float2 viewUV) {

		// Convert from NDC (-1 to 1) to texture coords (0 to 1)
		float3 p0 = (start + 1) * 0.5;
		float3 p1 = (end + 1) * 0.5;
		// Offset texture coords for tile size and UV (ORIGINAL)
		p0.xy = p0.xy;
		p1.xy = p1.xy;
		// Initialize search point
		float3 p = p0;
		// Initialize depth range
		float zMin = p0.z;
		float zMax = p0.z;
		float zThickness = 0.01;
		float zReal;
		float near = 0.01f;
		float far = 1000.0f;
		float sceneZMax = 990.0f;
		// Initialize return color to 'no hit'
		float3 rgb_tex2D = float3(-1.0, -1.0, -1.0);

		// Lerp from p0 to p1 sampling Z at fixed steps
		// Not sure this is the best way to do this
		// NOTE: Equality test fails when n is range 0-1 and increments in fractional values
		[loop]
		for (int n = 0; n <= 100; ++n) {
			p = lerp(p1, p0, n * 0.01);
			//p = lerp(p1, p0, n * 0.0025);

			zMax = 2.0 * near * far / (far + near - (far - near) * (2 * p.z - 1));
			//zThickness = p.z * p.z / 1000;
			//zThickness = p.z * p.z / 1;
			zReal = zConvert(tex2D(_zTex, (p.xy)));
			if ((zReal <= zMax + zThickness && zReal >= zMin - zThickness) || zMax > sceneZMax) {
				rgb_tex2D = tex2D(_rgbTex, (p.xy));
				break;
			}
			zMin = zMax;

		}
		//rgb_tex2D = tex2D(_rgb_tex, p0.xy);
		return rgb_tex2D;
	}

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

			
	fixed4 frag (v2f i) : SV_Target
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

		// 1 if camera is in front of view, 0 otherwise
		float front = step(0, cam_Eye.w);
		// 1 if ray direction is within 90deg of view normal (I think?) 0 otherwise
		float rayfront = step(0, ray_Eye.w);
		// 1 if both front and rayfront are true. Necessary to switch p0 and p1 in this case
		float swap = front*rayfront;

		// Swap p0 and p1 where either cam_view.w or ray_view.w is negative
		float3 p0 = (1 - swap)*hits[0].xyz + (swap)*hits[1].xyz;
		float3 p1 = (swap)*hits[0].xyz + (1 - swap)*hits[1].xyz;

		// TOOD: Why do we do this
		p0.xy *= -1;
		p1.xy *= -1;
		//p0.x *= -1;
		//p1.x *= -1;

		// RGB result of tracing from p0 to p1 from given UV coords
		// Result is -1.0f if no hit
		float3 raytraceResult = raytrace(p0, p1, _eyeUV);

		raytraceResult *= front * intersects;

		fixed4 col = fixed4(raytraceResult, 1);

		return col;
	}

	ENDCG
	}
	}
}
