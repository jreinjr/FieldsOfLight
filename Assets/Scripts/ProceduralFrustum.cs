using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ProceduralFrustum : MonoBehaviour {

    public Camera cameraSettings
    {
        get
        {
            return transform.parent.Find("Camera_RGB").GetComponent<Camera>();
        }
    }

    public float fov;
    public float aspect;
    public float nearClip;
    public float farClip;

    private MeshFilter filter;
    private Mesh mesh;



    // Use this for initialization
    void Start () {

       
    }


    private void Update()
    {
        fov = cameraSettings.fieldOfView;
        //aspect = cameraSettings.aspect;
        nearClip = cameraSettings.nearClipPlane;
        farClip = cameraSettings.farClipPlane;
    }

    private void OnValidate()
    {
        
        float fovWHalf = fov * 0.5f;
        float tan_fov = Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 toRight = Vector3.right * tan_fov * aspect;
        Vector3 toTop = Vector3.up * tan_fov;

        Vector3 topLeft = (Vector3.forward - toRight + toTop);
        Vector3 topRight = (Vector3.forward + toRight + toTop);
        Vector3 bottomRight = (Vector3.forward + toRight - toTop);
        Vector3 bottomLeft = (Vector3.forward - toRight - toTop);

        Vector3 nearTopLeft = topLeft * nearClip;
        Vector3 nearTopRight = topRight * nearClip;
        Vector3 nearBottomRight = bottomRight * nearClip;
        Vector3 nearBottomLeft = bottomLeft * nearClip;

        Vector3 farTopLeft = topLeft * farClip;
        Vector3 farTopRight = topRight * farClip;
        Vector3 farBottomRight = bottomRight * farClip;
        Vector3 farBottomLeft = bottomLeft * farClip;

        Vector3 farTop = (Vector3.forward + toTop) * farClip;
        Vector3 farRight = (Vector3.forward + toRight) * farClip;
        Vector3 farBottom = (Vector3.forward - toTop) * farClip;
        Vector3 farLeft = (Vector3.forward - toTop) * farClip;

        filter = GetComponent<MeshFilter>();
        if (filter.sharedMesh == null)
        {
            filter.sharedMesh = new Mesh();
        }
        mesh = filter.sharedMesh; 
        mesh.Clear();

        // Trying first with shared verts
        Vector3[] vertices = new Vector3[8];

        // Bottom cap
        vertices[0] = nearTopLeft;
        vertices[1] = nearTopRight;
        vertices[2] = nearBottomRight;
        vertices[3] = nearBottomLeft;

        // Top cap
        vertices[4] = farTopLeft;
        vertices[5] = farTopRight;
        vertices[6] = farBottomRight;
        vertices[7] = farBottomLeft;

        #region colors
        Color[] colors = new Color[8];
        // Bottom cap
        colors[0] = new Color(0, 1, 0);
        colors[1] = new Color(1, 1, 0);
        colors[2] = new Color(1, 0, 0);
        colors[3] = new Color(0, 0, 0);

        // Top cap
        colors[4] = new Color(0, 1, 1);
        colors[5] = new Color(1, 1, 1);
        colors[6] = new Color(1, 0, 1);
        colors[7] = new Color(0, 0, 1);
        #endregion

        Vector2[] uv = new Vector2[8];
        // Bottom cap
        uv[0] = new Vector2(0, 1);
        uv[1] = new Vector2(1, 1);
        uv[2] = new Vector2(1, 0);
        uv[3] = new Vector2(0, 0);

        // Top cap
        uv[4] = new Vector2(0, 1);
        uv[5] = new Vector2(1, 1);
        uv[6] = new Vector2(1, 0);
        uv[7] = new Vector2(0, 0);

        #region triangles
        // Triangles
        int[] triangles = new int[]{
            0, 1, 3,    // Front 1
            1, 2, 3,    // Front 2
            7, 4, 3,    // Left 1
            4, 0, 3,    // Left 2
            4, 5, 0,    // Top 1
            5, 1, 0,    // Top 2
            5, 6, 1,    // Right 1
            6, 2, 1,    // Right 2
            6, 7, 2,    // Bottom 1
            7, 3, 2,    // Bottom 2
            5, 4, 6,    // Far 1
            4, 7, 6     // Far 2
            };
        #endregion


        mesh.vertices = vertices;
        mesh.uv = uv;
        mesh.triangles = triangles;
        mesh.colors = colors;

        
    }
    
}
