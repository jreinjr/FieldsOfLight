using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[ExecuteInEditMode]
[CanEditMultipleObjects]
public class Eye: MonoBehaviour {

    Transform camera_RGB
    {
        get
        {
            return transform.Find("Camera_RGB");
        }
    }
    Transform camera_Z
    {
        get
        {
            return transform.Find("Camera_Z");
        }
    }
    Transform eyeProjector
    {
        get
        {
            return transform.Find("Projector");
        }
    }

    public void RenderRGB()
    {
        GetComponent<RenderTextureToFile>().RenderRGB();
    }

    public void RenderZ()
    {
        GetComponent<RenderTextureToFile>().RenderZ();
    }

    
    public void ToggleProjector()
    {
        eyeProjector.gameObject.SetActive(!eyeProjector.gameObject.activeSelf);
    }

    public void RefreshTextures()
    {
        transform.Find("Projector").GetComponent<SurfaceRaytrace>().RefreshTextures();
    }
}
