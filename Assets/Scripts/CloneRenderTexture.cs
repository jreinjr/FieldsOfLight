using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CloneRenderTexture : MonoBehaviour {

    public RenderTexture renderTextureToClone;
    public Camera renderCamera;

	// Use this for initialization
	void OnValidate () {
        renderCamera = GetComponent<Camera>();

        if (renderCamera.targetTexture == null)
        {
            renderCamera.targetTexture = new RenderTexture(renderTextureToClone);
        }
	}
	
}
