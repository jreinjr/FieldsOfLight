using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ProceduralCube : MonoBehaviour {

    public float radius;

    private MeshFilter filter;
    private Mesh mesh;



    // Use this for initialization
    void Start () {

        
    }




    private void OnValidate()
    {

        Vector3 toRight = Vector3.right;
        Vector3 toTop = Vector3.up;

        Vector3 topLeft = -toRight + toTop;
        Vector3 topRight = toRight + toTop;
        Vector3 bottomRight = toRight - toTop;
        Vector3 bottomLeft = -toRight - toTop;

        Vector3 nearTopLeft = topLeft + Vector3.forward;
        Vector3 nearTopRight = topRight +Vector3.forward;
        Vector3 nearBottomRight = bottomRight + Vector3.forward;
        Vector3 nearBottomLeft = bottomLeft + Vector3.forward;

        Vector3 farTopLeft = topLeft - Vector3.forward;
        Vector3 farTopRight = topRight - Vector3.forward;
        Vector3 farBottomRight = bottomRight - Vector3.forward;
        Vector3 farBottomLeft = bottomLeft - Vector3.forward;


        filter = GetComponent<MeshFilter>();
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
            0, 3, 1,    // Front 1
            1, 3, 2,    // Front 2
            7, 3, 4,    // Left 1
            4, 3, 0,    // Left 2
            4, 0, 5,    // Top 1
            5, 0, 1,    // Top 2
            5, 1, 6,    // Right 1
            6, 1, 2,    // Right 2
            6, 2, 7,    // Bottom 1
            7, 2, 3,    // Bottom 2
            5, 6, 4,    // Far 1
            4, 6, 7     // Far 2
            };
        #endregion


        mesh.vertices = vertices;
        mesh.uv = uv;
        mesh.triangles = triangles;
        mesh.colors = colors;
    }
    
}
