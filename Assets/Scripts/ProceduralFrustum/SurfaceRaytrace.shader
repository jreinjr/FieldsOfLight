Shader "Unlit/SurfaceRaytrace"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_BlendTex("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags {"Queue" = "Transparent" "RenderType" = "Opaque" }
		LOD 100

		////////////////////////////////////////////
		// TODO: Reuse code between passes
		////////////////////////////////////////////
		Pass
	{
		
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		Cull Off

		Stencil
		{
			Ref 255
			Comp Equal
		}

		CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"

		struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex_WS: TEXCOORD1;
		float4 vertex_OS: TEXCOORD2;
		float4 vertex : SV_POSITION;
		//float4 grabPos : TEXCOORD3;
	};

	sampler2D _MainTex;
	float4 _MainTex_ST;
	sampler2D _zTex;
	float4x4 _eyePerspective;
	uniform float _farClip;
	uniform float _nearClip;

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		o.vertex_WS = mul(unity_ObjectToWorld, v.vertex);
		o.vertex_OS = v.vertex;

		return o;
	}
	float3 convertOStoCS(float3 OS) {
		// "Clipspace" coordinate - xy is UV, z is linear depth (0 nearclip, 1 farclip)
		float3 vertex_CS = OS;
		vertex_CS.xy = vertex_CS.xy / vertex_CS.z;
		vertex_CS.xy = (vertex_CS.xy + 1) / 2;
		//vertex_CS.z = ((vertex_CS.z) - _nearClip) / (_farClip - _nearClip);
		return vertex_CS;
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

	fixed4 frag(v2f input) : SV_Target
	{
		// Fragment worldspace coord
		float3 frag_WS = input.vertex_WS.xyz;
		// Worldspace ray from camera to fragment
		float3 ray_WS = normalize(frag_WS - _WorldSpaceCameraPos);
		// Fragment objectspace coord
		float3 frag_OS = input.vertex_OS;
		// Objectspace ray from camera to fragment
		float3 ray_OS = mul(unity_WorldToObject, ray_WS);

		float stored_depth;
		const uint max_steps = 100;
		const float orig_step_size = .1;
		float step_size = orig_step_size;
		const float hitTolerance = 0.064;
		const float refineTolerance = 0.064;

		float4 hitCol = float4(0,0,0,0);

		float3 hit_OS = input.vertex_OS;
		float3 hit_CS = convertOStoCS(hit_OS);

		float3 hit;
		float stepsTaken = 0;
		[loop]
		for (uint i = 0; i < max_steps; i++)
		{
			// Almost working
			hit_CS = convertOStoCS(hit_OS);

			if (hit_CS.x > 1 || hit_CS.y > 1 || hit_CS.x < -0.1 || hit_CS.y < -0.1 || hit_CS.z > 10) {
				break;
			}

			stored_depth = zConvert(tex2D(_zTex, hit_CS.xy).r);
			if (hit_CS.z >= (stored_depth - hitTolerance) && hit_CS.z <= (stored_depth + hitTolerance)) {
				//hitCol.xyz = tex2D(_MainTex, hit_CS.xy);
				hitCol.w = 1;
				break;
			}
			else if (hit_CS.z >(stored_depth - refineTolerance)) {
				step_size = step_size / 2;
				hit_OS -= ray_OS * step_size;
			}

			else {

				step_size = orig_step_size;
				hit_OS += ray_OS * step_size;
			}

			stepsTaken += (float)i / (float)max_steps;
		}

		fixed4 col = fixed4(hit_OS.xyz, hitCol.w);

		return col;
	}


		ENDCG
	}

		Pass
		{
			Stencil
			{
				Ref 255
				Comp Equal

			}


			Blend SrcAlpha OneMinusSrcAlpha
			BlendOp Add
			ZWrite Off



			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
		
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex_WS: TEXCOORD1;
				float4 vertex_OS: TEXCOORD2;
				float4 vertex : SV_POSITION;
				float2 screenPos : TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BlendTex;

			sampler2D _zTex;
			float4x4 _eyePerspective;
			uniform float _farClip;
			uniform float _nearClip;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.vertex_WS = mul(unity_ObjectToWorld, v.vertex);
				o.vertex_OS = v.vertex;
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}
			float3 convertOStoCS(float3 OS) {
				// "Clipspace" coordinate - xy is UV, z is linear depth (0 nearclip, 1 farclip)
				float3 vertex_CS = OS;
				vertex_CS.xy = vertex_CS.xy / vertex_CS.z;
				vertex_CS.xy = (vertex_CS.xy + 1) / 2;
				//vertex_CS.z = ((vertex_CS.z) - _nearClip) / (_farClip - _nearClip);
				return vertex_CS;
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

			fixed4 frag (v2f input) : SV_Target
			{
				// Fragment worldspace coord
				float3 frag_WS = input.vertex_WS.xyz;
				// Worldspace ray from camera to fragment
				float3 ray_WS = normalize(frag_WS - _WorldSpaceCameraPos);
				// Fragment objectspace coord
				float3 frag_OS = input.vertex_OS;
				// Objectspace ray from camera to fragment
				float3 ray_OS = mul(unity_WorldToObject, ray_WS);

				float stored_depth;
				const uint max_steps = 100;
				const float orig_step_size = .1;
				float step_size = orig_step_size;
				const float hitTolerance = 0.064;
				const float refineTolerance = 0.064;

				float4 hitCol = float4(0,0,0,0);
				
				float3 hit_OS = input.vertex_OS;
				float3 hit_CS = convertOStoCS(hit_OS);

				float3 hit;
				float stepsTaken = 0;
				[loop]
				for (uint i = 0; i < max_steps; i++)
				{
					// Almost working
					hit_CS = convertOStoCS(hit_OS);
					
					if (hit_CS.x > 1 || hit_CS.y > 1 || hit_CS.x < -0.1 || hit_CS.y < -0.1 || hit_CS.z > 10) {
						break;
					}

					stored_depth = zConvert(tex2D(_zTex, hit_CS.xy).r);
					if (hit_CS.z >= (stored_depth - hitTolerance) && hit_CS.z <= (stored_depth + hitTolerance)) {
						hitCol.xyz = tex2D(_MainTex, hit_CS.xy);
						hitCol.w = 1;
						break;
					}
					else if (hit_CS.z > (stored_depth - refineTolerance)) {
						step_size = step_size / 2;
						hit_OS -= ray_OS * step_size;
					}
				
					else {

						step_size = orig_step_size;
						hit_OS += ray_OS * step_size;
					}
					
					stepsTaken += (float)i / (float)max_steps;
				}
				
				fixed4 col = fixed4(hitCol);
				col *= tex2D(_BlendTex, input.vertex.xy / _ScreenParams.xy).g;
				fixed4 debug = fixed4(input.vertex.xy / _ScreenParams.xy, 0, 1);
				return col;
			}

			
			ENDCG
		}
	}
}
