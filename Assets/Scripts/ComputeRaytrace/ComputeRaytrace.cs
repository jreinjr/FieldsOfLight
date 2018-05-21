using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ComputeRaytrace : SceneViewFilter {

    [SerializeField]
    private ComputeShader computeShader;

    private RenderTexture computeInOut;

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
        Vector2Int resolution = new Vector2Int(1024, 1024);

        computeInOut = RenderTexture.GetTemporary(resolution.x, resolution.y, 0, RenderTextureFormat.ARGB32);
        computeInOut.enableRandomWrite = true;
        computeInOut.Create();
        // This is inefficient - move this to static method
        int FindIntersectionKernel = computeShader.FindKernel("FindIntersection");
        computeShader.SetTexture(FindIntersectionKernel, "Result", computeInOut);
        computeShader.SetVector("camPos", Camera.current.transform.position);
        computeShader.SetMatrix("camCorners", GetFrustumCornersWS(Camera.current));
        computeShader.SetVector("resolution", (Vector2)resolution);
        computeShader.Dispatch(FindIntersectionKernel, resolution.x / 8, resolution.y / 8, 1);

    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!EffectMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }

        EffectMaterial.SetTexture("_MainTex", computeInOut);

        Graphics.Blit(computeInOut, destination, EffectMaterial);
    }

    private void OnPostRender()
    {
        RenderTexture.ReleaseTemporary(computeInOut);
    }

    /// \brief Stores the normalized rays representing the camera frustum in a 4x4 matrix.  Each row is a vector.
    /// 
    /// The following rays are stored in each row (in eyespace, not worldspace):
    /// Top Left corner:     row=0
    /// Top Right corner:    row=1
    /// Bottom Right corner: row=2
    /// Bottom Left corner:  row=3
    private Matrix4x4 GetFrustumCorners(Camera cam)
    {
        float camFov = cam.fieldOfView;
        float camAspect = cam.aspect;

        Matrix4x4 frustumCorners = Matrix4x4.identity;

        float fovWHalf = camFov * 0.5f;

        float tan_fov = Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 toRight = Vector3.right * tan_fov * camAspect;
        Vector3 toTop = Vector3.up * tan_fov;
        Vector3 topLeft = (-Vector3.forward - toRight + toTop);
        Vector3 topRight = (-Vector3.forward + toRight + toTop);
        Vector3 bottomRight = (-Vector3.forward + toRight - toTop);
        Vector3 bottomLeft = (-Vector3.forward - toRight - toTop);

        frustumCorners.SetRow(0, topLeft);
        frustumCorners.SetRow(1, topRight);
        frustumCorners.SetRow(2, bottomRight);
        frustumCorners.SetRow(3, bottomLeft);

        return frustumCorners;
    }


    /// Bottom Left corner:     row=0
    /// Bottom Right corner:    row=1
    /// Top Left corner: row=2
    /// Top Right corner:  row=3
    private Matrix4x4 GetFrustumCornersWS(Camera cam)
    {
        Matrix4x4 frustumCorners = Matrix4x4.identity;

        Vector3 topLeft = cam.ViewportPointToRay(new Vector3(0, 1, 0)).direction;
        Vector3 topRight = cam.ViewportPointToRay(new Vector3(1, 1, 0)).direction;
        Vector3 bottomLeft = cam.ViewportPointToRay(new Vector3(0, 0, 0)).direction;
        Vector3 bottomRight = cam.ViewportPointToRay(new Vector3(1, 0, 0)).direction;

        frustumCorners.SetRow(0, bottomLeft);
        frustumCorners.SetRow(1, bottomRight);
        frustumCorners.SetRow(2, topLeft);
        frustumCorners.SetRow(3, topRight);

        return frustumCorners;

    }
}
