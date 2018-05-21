using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BlendCompute : MonoBehaviour {

    public ComputeShader shader;
    Renderer rend;
    RenderTexture tex;
    RenderTexture tex2;

    public Renderer rend2;

    private void Start()
    {
        tex = new RenderTexture(512, 512, 24);
        tex.enableRandomWrite = true;
        tex.Create();

        tex2 = new RenderTexture(512, 512, 24);
        tex2.enableRandomWrite = true;
        tex2.Create();

        rend = GetComponent<Renderer>();
        rend.enabled = true;

        int kernelIndex = shader.FindKernel("CSMain");
        shader.SetTexture(kernelIndex, "Result", tex);
        shader.SetTexture(kernelIndex, "Result2", tex2);
        shader.Dispatch(kernelIndex, 512 / 8, 512 / 8, 1);

        rend.material.SetTexture("_MainTex", tex);
        rend2.material.SetTexture("_MainTex", tex2);
    }


    
}
