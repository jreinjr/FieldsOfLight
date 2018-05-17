#ifndef INTERSECT_AABB
#define INTERSECT_AABB
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles

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
#endif