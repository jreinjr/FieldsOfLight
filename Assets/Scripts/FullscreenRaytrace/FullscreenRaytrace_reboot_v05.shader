// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/FullscreenRaytrace_reboot_v05"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_rgb_texture("_rgb_tex", 2D) = "white" {}
		_z_texture("_z_tex", 2D) = "white" {}
		_ztolerance("ztolerance", Range(0, 5)) = 0.01
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
			#pragma target 5.0
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma enable_d3d11_debug_symbols


			#include "UnityCG.cginc"

		struct appdata
		{
			// Z value here contains index of _FrustrumCornersES to use
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct v2g
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float3 ray : TEXCOORD1;
			nointerpolation float4 blend : TEXCOORD2;
		};

		struct g2f
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float3 ray : TEXCOORD1;
			nointerpolation float4 blend[3] : TEXCOORD2;
			float3 bary : TEXCOORD5;
		};

		struct View
		{
			float4x4 viewMatrix;
			float2 viewUV;
		};

		uniform sampler2D _rgb_tex;
		uniform sampler2D _z_tex;
		uniform float4x4 _FC; // Frustrum Corners
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_TexelSize;
		uniform float4x4 _CameraInvViewMatrix;
		uniform float4x4 _CameraViewMatrix;
		uniform float3 _CameraWS;
		uniform StructuredBuffer<View> _ViewBuffer;
		uniform float4x4 _projectionMatrix;
		uniform float2 _tilesize;
		uniform float _zOffset;
		uniform float _zMult;


		// Maximum number of views
		const static int _maxLength = 256;

		uniform int _length;
		const static float _inf = 1. / 0.;


		// Extracts homogenic position coordinates from a 4x4 view matrix
		float4 getPosFromMatrix(float4x4 m) {
			return float4(m[0].w, m[1].w, m[2].w, 1);
		}



		// Extracts homogenic position coordinates from a 4x4 view matrix
		float4 getFwdFromMatrix(float4x4 m) {
			return float4(m[0].z, m[1].z, m[2].z, 0);
		}



		// Finds magnitude of distance between two vector2s
		float distance(float2 a, float2 b) {
			float2 c = b - a;
			return dot(c, c);
		}

		// Normalize a vector4 so that the sum of all components is 1
		float4 customNormalize(float4 vec) {
			// Commented-out code below preserves blending weight of 1 for closest view around view center 
			// TODO: Perhaps re-implement this
			//vec.x = vec.x * vec.x;
			//vec.y = (1.0f - vec.x) * (vec.y);
			//vec.z = (1.0f - vec.x) * (1.0f - vec.y) * (vec.z);

			float sum = vec.x + vec.y + vec.z + vec.w;

			return vec / sum;
		}

		// Weighs each component in a vector4 by its fraction of the maximum value
		// Max value has 0 weight
		float4 weigh(float4 vec) {
			float vMax = max(max(vec.x, vec.y), max(vec.z, vec.w));
			return (1.0f - (vec / vMax));
		}

		// Returns indices of four closest views before decimal and normalized blend weights after
		float4 indexSort(float d[_maxLength]) {
			uint i;
			float4 indices = { 0.0f, 0.0f, 0.0f, 0.0f };

			float4 sorted = { _inf, _inf, _inf, _inf };
			for (i = 0; i < _length; i++)
			{
				if (d[i] < sorted.w) {

					if (d[i] < sorted.z) {

						if (d[i] < sorted.y) {

							if (d[i] < sorted.x) {

								sorted.w = sorted.z;
								sorted.z = sorted.y;
								sorted.y = sorted.x;
								sorted.x = d[i];
								indices.w = indices.z;
								indices.z = indices.y;
								indices.y = indices.x;
								indices.x = i;
							}
							else {
								sorted.w = sorted.z;
								sorted.z = sorted.y;
								sorted.y = d[i];
								indices.w = indices.z;
								indices.z = indices.y;
								indices.y = i;
							}
						}
						else {
							sorted.w = sorted.z;
							sorted.z = d[i];
							indices.w = indices.z;
							indices.z = i;
						}
					}
					else {
						sorted.w = d[i];
						indices.w = i;
					}
				}
			}
			sorted = customNormalize(weigh(sorted));
			return float4(indices + sorted);
		}

		// Returns indices of four closest views before decimal and normalized blend weights after
		// Modified for fragment shader - maxLength is 12 and no need to reweight, uses input index list
		// (since indices are no longer in numerical order) also switched to descending order (since we are looking at weights)
		float1x4 fragIndexSort(float d[9], float n[9]) {
			uint i;
			float4 indices = { 0.0f, 0.0f, 0.0f, 0.0f };

			float4 sorted = { 0.0f, 0.0f, 0.0f, 0.0f };
			for (i = 0; i < 9; i++)
			{
				if (d[i] > sorted.w) {

					if (d[i] > sorted.z) {

						if (d[i] > sorted.y) {

							if (d[i] > sorted.x) {

								sorted.w = sorted.z;
								sorted.z = sorted.y;
								sorted.y = sorted.x;
								sorted.x = d[i];
								indices.w = indices.z;
								indices.z = indices.y;
								indices.y = indices.x;
								indices.x = n[i];
							}
							else {
								sorted.w = sorted.z;
								sorted.z = sorted.y;
								sorted.y = d[i];
								indices.w = indices.z;
								indices.z = indices.y;
								indices.y = n[i];
							}
						}
						else {
							sorted.w = sorted.z;
							sorted.z = d[i];
							indices.w = indices.z;
							indices.z = n[i];
						}
					}
					else {
						sorted.w = d[i];
						indices.w = n[i];
					}
				}
			}
			//sorted = customNormalize(sorted);
			return float1x4(indices + sorted);
		}



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
			return  (pow(z, 2.2) - _zOffset) * _zMult;
		}



		// Search from start point to end point (given in NDC) for an intersection with stored geo in depth map
		// TODO: Convert to floating point math				
		// TODO: Care about mipmaps and derivatives
		// TODO: find out why uniform float tile width is out of scope here
		float3 raytrace(float3 start, float3 end, float2 viewUV) {

			// Convert from NDC (-1 to 1) to texture coords (0 to 1)
			float3 p0 = (start + 1) * 0.5;
			float3 p1 = (end + 1) * 0.5;
			// Offset texture coords for tile size and UV
			p0.xy = p0.xy * _tilesize + viewUV;
			p1.xy = p1.xy * _tilesize + viewUV;
			// Initialize search point
			float3 p = p0;
			// Initialize depth range
			float zMin = p0.z;
			float zMax = p0.z;
			float zThickness = 10;
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
			for (int n = 0; n <= 500; ++n) {
				p = lerp(p1, p0, n * 0.002);
				//p = lerp(p1, p0, n * 0.0025);

				zMax = 2.0 * near * far / (far + near - (far - near) * (2 * p.z - 1));
				//zThickness = p.z * p.z / 1000;
				//zThickness = p.z * p.z / 1;
				zReal = zConvert(tex2D(_z_tex, (p.xy)));
				if ((zReal <= zMax + zThickness && zReal >= zMin - zThickness) || zMax > sceneZMax) {
					rgb_tex2D = tex2D(_rgb_tex, (p.xy));
					break;
				}
				zMin = zMax;

			}
			//rgb_tex2D = tex2D(_rgb_tex, p0.xy);
			return rgb_tex2D;
		}



		v2g vert(appdata v)
		{
			v2g o;

			// Index passed via custom blit function in FullscreenRaytrace.cs
			half index = v.vertex.z;
			v.vertex.z = 0.1;

			o.pos = UnityObjectToClipPos(v.vertex);

			o.uv = v.uv;

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv.y = 1 - o.uv.y;
			#endif

			// Quadrilinearly interpolate eyespace frustrum corner rays using UV coords
			// _FC[0] BL
			// _FC[1] BR
			// _FC[2] TL
			// _FC[3] TR
			float3 ray_view = lerp(lerp(_FC[0], _FC[1], v.uv.x), lerp(_FC[2], _FC[3], v.uv.x), v.uv.y);

			// Transform the ray from eyespace to worldspace
			// Note: _CameraInvViewMatrix provided by the script
			float3 ray_world = mul(_CameraInvViewMatrix, ray_view);

			// Initialize array of screen distances for blending field
			float combinedWeights[_maxLength];
			float4 viewPos;
			float4 viewScreenPos;
			float screenDistWeight;  // calculated from screen distance between ray and view center
			float screenDistWeight_contrib = 0.0f;
			float fovWeight;  // Should be close to 1 inside the FOV of a camera falling off to zero beyond
			float fovWeight_contrib = 1.0f;
			// This loop populates an array of distances between each view and the current ray
			//DEBUG - global constants aren't working now?
			for (uint n = 0; n < _length; ++n) {
				// Extract view vertex world position from view matrix
				viewPos = getPosFromMatrix(_ViewBuffer[n].viewMatrix);

				// Project view vertex position to screen space
				viewScreenPos = mul(_CameraViewMatrix, viewPos);

				// worldToCameraMatrix (input) is OpenGL standard by default (forward is -z)
				// Multiply by -1 to convert to Unity standard (forward is +z)
				viewScreenPos /= viewScreenPos.z * -1;

				screenDistWeight = distance(ray_view.xy, viewScreenPos.xy);

				// TODO: Why do we multiply view fwd dir by -1 (same reason as -1 mult above?)
				fovWeight = 1 - dot(normalize(ray_world), normalize(getFwdFromMatrix(_ViewBuffer[n].viewMatrix)*-1));

				// Add screen distance between ray and view to array
				// DEBUG : NOT USING FOV WEIGHT
				combinedWeights[n] = fovWeight*fovWeight_contrib + screenDistWeight*screenDistWeight_contrib;
			}

			// Blend represents the nearest 4 views in order
			// The index of the view is before decimal and its blend weight is after
			o.blend = indexSort(combinedWeights);

			o.ray = ray_world;
			o.uv.x = fovWeight;
			return o;
		}



		[maxvertexcount(3)]
		void geom(triangle v2g i[3], inout TriangleStream<g2f> OutputStream)
		{
			g2f o;

			o.blend[0] = i[0].blend;
			o.blend[1] = i[1].blend;
			o.blend[2] = i[2].blend;

			o.pos = i[0].pos;
			o.ray = i[0].ray;
			o.uv = i[0].uv;
			o.bary = float3(1, 0, 0);

			OutputStream.Append(o);

			o.pos = i[1].pos;
			o.ray = i[1].ray;
			o.uv = i[1].uv;
			o.bary = float3(0, 1, 0);

			OutputStream.Append(o);

			o.pos = i[2].pos;
			o.ray = i[2].ray;
			o.uv = i[2].uv;
			o.bary = float3(0, 0, 1);

			OutputStream.Append(o);

			OutputStream.RestartStrip();

		}



		fixed4 frag(g2f i) : SV_Target
		{
			fixed4 col;


			// raycasts holds the results of raytracing the 4 closest views
			// Initialized to -1.0f (no hit)
			float4x3 raycasts = { -1.0f, -1.0f, -1.0f,
			-1.0f, -1.0f, -1.0f,
			-1.0f, -1.0f, -1.0f,
			-1.0f, -1.0f, -1.0f };



			uint viewIndex;
			float4 ray_view;
			float4 cam_view;
			float2x4 hits;
			float3 p0;
			float3 p1;
			float intersects;
			float swap;
			float1x3 bary;
			bary[0] = i.bary;


			// Interpolate 4 closest views from 3x9 (9) closest views (from geom)

			float wList[9] = { 0,0,0,0,0,0,0,0,0 };
			float nList[9] = { -1,-1,-1,-1,-1,-1,-1,-1,-1 };
			uint listLength = 0;
			for (uint j = 0; j < 3; ++j) {
				for (uint k = 0; k < 3; ++k) {
					float w = frac(i.blend[j][k]) * bary[0][j];
					float n = floor(i.blend[j][k]);

					// Check if index already exists in nList or if position is empty; add weights if so
					[loop]
					for (uint l = 0; l < 9; ++l) {
						if (nList[l] == n || nList[l] == -1) {
							wList[l] += w;
							nList[l] = n;
							break;
						}
					}
				}
			}

			float1x4 weights = fragIndexSort(wList, nList);
			float1x4 weightIndices = floor(weights[0]);
			weights[0] = frac(weights[0]);
			float4x4 viewMatrix;
			float4x4 _view_VP;
			float front;
			float rayfront;

			// Raytrace each of the 4 closest views in screen space
			for (uint n = 0; n < 4; ++n) {

				///// DEBUG
				//viewIndex = 0;
				viewIndex = floor(weightIndices[0][n]);
				viewMatrix = _ViewBuffer[viewIndex].viewMatrix;


				// Get view * projection matrix for the current view
				_view_VP = mul(_projectionMatrix, viewMatrix);
				

				// Transform the ray from worldspace to current view projection space
				// DEBUG
				ray_view = mul(_view_VP, float4(i.ray, 0.0f));
				//ray_view = float4(mul(float4(i.ray, 0), getFwdFromMatrix(viewMatrix)));
				//ray_view = mul(viewMatrix, i.ray);
				//ray_view = mul(_projectionMatrix, ray_view);
				ray_view.xyz = ray_view / ray_view.w;

				// Transform camera position from worldspace to current view projection space
				// DEBUG
				cam_view = mul(_view_VP, float4(_CameraWS, 1.0f));
				//cam_view = float4(_CameraWS - getPosFromMatrix(viewMatrix).xyz, 1);
				//cam_view = mul(_projectionMatrix, cam_view);
				cam_view.xyz = cam_view / cam_view.w;

				// Get direction from camera along ray
				// Not 100% sure why this works and is necessary
				float3 dir_view = ray_view - cam_view;

				// Get hitpoints of frustum and ray in current view space
				// hits[0].xyz = tmin intersection point
				// hits[1].xyz = tmax intersection point
				// hits[0].w = tmin
				// hits[1].w = tmax
				hits = intersect(cam_view.xyz, dir_view.xyz);
				// DEBUG - WHY
				hits[0].xy *= -1;
				hits[1].xy *= -1;

				// 1 if ray hits frustum, 0 otherwise
				intersects = step(hits[0].w, hits[1].w);

				// 1 if camera is in front of view, 0 otherwise
				front = step(0, cam_view.w);
				// 1 if ray direction is within 90deg of view normal (I think?) 0 otherwise
				rayfront = step(0, ray_view.w);
				// 1 if both front and rayfront are true. Necessary to switch p0 and p1 in this case
				swap = front*rayfront;

				// Swap p0 and p1 where either cam_view.w or ray_view.w is negative
				p0 = (1 - swap)*hits[0].xyz + (swap)*hits[1].xyz;
				p1 = (swap)*hits[0].xyz + (1 - swap)*hits[1].xyz;
				
				// TOOD: Why do we do this
				p0.xy *= -1;
				p1.xy *= -1;
				//p0.x *= -1;
				//p1.x *= -1;

				// RGB result of tracing from p0 to p1 from given UV coords
				// Result is -1.0f if no hit
				float3 raytraceResult = raytrace(p0, p1, _ViewBuffer[viewIndex].viewUV);

				// Zero out blend weight if no hit was found
				weights[0][n] = weights[0][n] * step(0, raytraceResult.r);

				// Store raytrace result in raycasts array
				// Multiply by intersects to omit rays that do not intersect given view frustum
				raycasts[n].xyz = raytraceResult * intersects;
			}

			// Renormalize blend weights after ray rejection
			weights[0] = customNormalize(weights[0]);

			// Multiply raycast results by blend weight
			// DEBUG 
			//col = fixed4(raycasts[0].xyz, 1);
			col = fixed4(mul(weights[0], raycasts), 1);
			

			float b0 = frac(i.blend[0][0]) + frac(i.blend[0][1]) + frac(i.blend[0][2]);
			float b1 = frac(i.blend[1][0]) + frac(i.blend[1][1]) + frac(i.blend[1][2]);
			float b2 = frac(i.blend[2][0]) + frac(i.blend[2][1]) + frac(i.blend[2][2]);

			b0 = b0 * bary[0][0];
			b1 = b1 * bary[0][1];
			b2 = b2 * bary[0][2];

			float n00 = floor(i.blend[0][0]);
			float n01 = floor(i.blend[0][1]);
			float n02 = floor(i.blend[0][2]);

			float n10 = floor(i.blend[1][0]);
			float n11 = floor(i.blend[1][1]);
			float n12 = floor(i.blend[1][2]);

			float n20 = floor(i.blend[2][0]);
			float n21 = floor(i.blend[2][1]);
			float n22 = floor(i.blend[2][2]);

			float indexR0 = weightIndices[0][0] / 192.0f;
			float indexG0 = weightIndices[0][0] % 16 / 16.0f;
			float indexB0 = weightIndices[0][0] % 64 / 64.0f;

			float indexR1 = weightIndices[0][1] / 192.0f;
			float indexG1 = weightIndices[0][1] % 16 / 16.0f;
			float indexB1 = weightIndices[0][1] % 64 / 64.0f;

			float indexR2 = weightIndices[0][0] / 192.0f;
			float indexG2 = weightIndices[0][0] % 16 / 16.0f;
			float indexB2 = weightIndices[0][0] % 64 / 64.0f;

			float blendR = indexR0 * weights[0][0] + indexR1 * weights[0][1] + indexR2 * weights[0][2];
			float blendG = indexG0 * weights[0][0] + indexG1 * weights[0][1] + indexG2 * weights[0][2];
			float blendB = indexB0 * weights[0][0] + indexB1 * weights[0][1] + indexB2 * weights[0][2];

			//col = fixed4(indexR0, 0, 0,1);
			//col = fixed4(swap, 0, 0, 1);
			//col = fixed4(i.uv.x, 0, 0, 1);
			return col;
			}
			ENDCG
		}
	}
}