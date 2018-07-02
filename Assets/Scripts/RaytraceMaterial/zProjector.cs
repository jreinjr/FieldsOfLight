using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class zProjector : MonoBehaviour {

    public ComputeShader computeShader;

    RenderTexture blendTex;
    Material raytraceMaterial;

    void Start () {
        blendTex = new RenderTexture(256, 256, 0, RenderTextureFormat.ARGBFloat);
        blendTex.name = "BlendTex";
        blendTex.enableRandomWrite = true;
        blendTex.Create();

        raytraceMaterial = GetComponent<Renderer>().material;
        raytraceMaterial.SetTexture("_StencilTex", blendTex);

        int BlendKernel = computeShader.FindKernel("Blend");
        computeShader.SetTexture(BlendKernel, "_blendTex", blendTex);
        computeShader.Dispatch(BlendKernel, 256 / 8, 256 / 8, 1);
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
