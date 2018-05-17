#ifndef RAYTRACE
#define RAYTRACE

uniform sampler2D _rgbTex;
uniform sampler2D _zTex;

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

#endif