using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DebugEye : EyeCollection {

    // Eye extrinsics
    public Vector3 eyePos;
    public Vector3 eyeRot;

    // Eye intrinsics
    [Range(0.0f, 180.0f)]
    public float eyeFov = 90f;
    [Range(0.5f, 2.0f)]
    public float eyeAspect = 1.0f;
    [Range(0, 1f)]
    public float eyeNear;
    [Range(0, 10000.0f)]
    public float eyeFar;

    // UV coord of eye on texture
    public Vector2 eyeUV;

    private Eye debugEye;
    private Matrix4x4 debugExtrinsics;
    private Matrix4x4 debugIntrinsics;

    private void BuildDebugEye()
    {
        eyes = new List<Eye>();

        debugEye = new Eye();

        debugExtrinsics = new Matrix4x4();
        debugExtrinsics.SetTRS(eyePos, Quaternion.Euler(eyeRot), Vector3.one);
        debugEye.Extrinsics = debugExtrinsics;

        debugIntrinsics = new Matrix4x4();
        debugIntrinsics = Matrix4x4.Perspective(eyeFov, eyeAspect, eyeNear, eyeFar);
        debugIntrinsics = GL.GetGPUProjectionMatrix(debugIntrinsics, false);

        debugEye.Intrinsics = debugIntrinsics;

        debugEye.UV = eyeUV;

        eyes.Clear();
        eyes.Add(debugEye);

    }

    public void OnValidate()
    {
        BuildDebugEye();
    }


    protected void Start()
    {
        BuildDebugEye();
    }
}
