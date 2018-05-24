using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;

[ExecuteInEditMode]
public class ComputeRaytrace : SceneViewFilter {

    public float nearClip;
    public float farClip;
    public float fov;
    public float aspect;

    public Texture2D rgbTex;
    public Texture2D zTex;

    [SerializeField]
    private ComputeShader computeShader;
    Vector2Int resolution = new Vector2Int(1024, 1024);

    private RenderTexture intersection;
    private RenderTexture result;

    private Material _EffectMaterial;
    private Material EffectMaterial
    {
        get
        {
            if (!_EffectMaterial)
            {
                _EffectMaterial = new Material(Shader.Find("Unlit/Texture"));
            }
            return _EffectMaterial;
        }
    }


    private void OnPreRender()
    {

        intersection = RenderTexture.GetTemporary(resolution.x, resolution.y, 0, RenderTextureFormat.ARGBFloat);
        intersection.vrUsage = VRTextureUsage.OneEye;
        intersection.enableRandomWrite = true;
        intersection.Create();

        result = RenderTexture.GetTemporary(resolution.x, resolution.y, 0, RenderTextureFormat.ARGB32);
        result.vrUsage = VRTextureUsage.OneEye;
        result.enableRandomWrite = true;
        result.Create();

        // This is inefficient - move this to static method
        int FindIntersectionKernel = computeShader.FindKernel("FindIntersection");
        int RaymarchKernel = computeShader.FindKernel("Raymarch");

        computeShader.SetTexture(FindIntersectionKernel, "Intersection", intersection);
        computeShader.SetTexture(RaymarchKernel, "Intersection", intersection);
        computeShader.SetTexture(RaymarchKernel, "Result", result);
        computeShader.SetTexture(RaymarchKernel, "_rgbTex", rgbTex);
        computeShader.SetTexture(RaymarchKernel, "_zTex", zTex);


        computeShader.SetVector("camPos", GetCurrentEyePositionWS(Camera.current));
        computeShader.SetFloat("_nearClip", nearClip);
        computeShader.SetFloat("_farClip", farClip);

        computeShader.SetMatrix("camCorners", GetFrustumCornersWS(Camera.current));
        computeShader.SetVector("resolution", (Vector2)resolution);

        computeShader.Dispatch(FindIntersectionKernel, resolution.x / 8, resolution.y / 8, 1);
        //computeShader.Dispatch(RaymarchKernel, resolution.x, resolution.y, 1);

        EffectMaterial.SetTexture("_MainTex", result);


    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!EffectMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }
        
        Graphics.Blit(intersection, destination, EffectMaterial);
    }

    private void OnPostRender()
    {
        RenderTexture.ReleaseTemporary(intersection);
        RenderTexture.ReleaseTemporary(result);
    }

    


    /// Bottom Left corner:     row=0
    /// Bottom Right corner:    row=1
    /// Top Left corner: row=2
    /// Top Right corner:  row=3
    private Matrix4x4 GetFrustumCornersWS(Camera cam)
    {
        Matrix4x4 frustumCorners = Matrix4x4.identity;

        var currentEye = cam.stereoActiveEye;
        var stereoEye = Camera.StereoscopicEye.Left;
        if (currentEye == Camera.MonoOrStereoscopicEye.Left)
        {
            stereoEye = Camera.StereoscopicEye.Left;
        }
        else if (currentEye == Camera.MonoOrStereoscopicEye.Right)
        {
            stereoEye = Camera.StereoscopicEye.Right;
        }

        Matrix4x4 stereoViewMatrix = cam.GetStereoViewMatrix(stereoEye);

        

        Vector3[] outCorners = new Vector3[4];

        Camera.current.CalculateFrustumCorners(new Rect(0, 0, 1, 1), cam.nearClipPlane, currentEye, outCorners);

        for (int i = 0; i < 4; i++)
        {
            outCorners[i] = cam.transform.TransformVector(outCorners[i]);
        }

        Vector3 topLeft = Vector3.Normalize(outCorners[1]);
        Vector3 topRight = Vector3.Normalize(outCorners[2]);
        Vector3 bottomLeft = Vector3.Normalize(outCorners[0]);
        Vector3 bottomRight = Vector3.Normalize(outCorners[3]);

        //Vector3 topLeft = cam.ViewportPointToRay(new Vector3(0, 1, 0)).direction;
        //Vector3 topRight = cam.ViewportPointToRay(new Vector3(1, 1, 0)).direction;
        //Vector3 bottomLeft = cam.ViewportPointToRay(new Vector3(0, 0, 0)).direction;
        //Vector3 bottomRight = cam.ViewportPointToRay(new Vector3(1, 0, 0)).direction;




        frustumCorners.SetRow(0, bottomLeft);
        frustumCorners.SetRow(1, bottomRight);
        frustumCorners.SetRow(2, topLeft);
        frustumCorners.SetRow(3, topRight);

        return frustumCorners;

    }


    private Vector3 GetCurrentEyePositionWS(Camera cam)
    {
        Vector3 left = Quaternion.Inverse(InputTracking.GetLocalRotation(XRNode.LeftEye)) * InputTracking.GetLocalPosition(XRNode.LeftEye);
        Vector3 right = Quaternion.Inverse(InputTracking.GetLocalRotation(XRNode.RightEye)) * InputTracking.GetLocalPosition(XRNode.RightEye);

        Vector3 leftWorld, rightWorld;
        Vector3 offset = (left - right) * 0.5f;

        Matrix4x4 m = cam.cameraToWorldMatrix;
        leftWorld = m.MultiplyPoint(-offset);
        rightWorld = m.MultiplyPoint(offset);

        if (cam.stereoActiveEye == Camera.MonoOrStereoscopicEye.Left)
        {
            return leftWorld;
        }
        else if (cam.stereoActiveEye == Camera.MonoOrStereoscopicEye.Right)
        {
            return rightWorld;
        }
        else return cam.transform.position;

        
    }
}
