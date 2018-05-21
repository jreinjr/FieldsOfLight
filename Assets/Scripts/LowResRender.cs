using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LowResRender : MonoBehaviour {

    RenderTexture screenTexture;
    Material screenMat;

	// Use this for initialization
	void Start () {
        screenTexture = new RenderTexture(1080 / 16, 1200 / 16, 0, RenderTextureFormat.ARGB32);
        screenMat = new Material(Shader.Find("Unlit/Texture"));
        Camera.main.targetTexture = screenTexture;
        screenMat.mainTexture = screenTexture;
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, screenMat);
    }
}
