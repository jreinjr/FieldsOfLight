using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class MirrorCameraSettings : MonoBehaviour {

    public Camera cameraToMirror
    {
        get
        {
            return transform.parent.Find("Camera_RGB").GetComponent<Camera>();
        }
    }



    Camera myCamera
    {
        get
        {
            return GetComponent<Camera>();
        }
    }


    private void Update()
    {
        myCamera.cullingMask = cameraToMirror.cullingMask;
        myCamera.fieldOfView = cameraToMirror.fieldOfView;
        myCamera.nearClipPlane = cameraToMirror.nearClipPlane;
        myCamera.farClipPlane = cameraToMirror.farClipPlane;

        // Maybe copy ViewportRect as Aspect?
    }
}
