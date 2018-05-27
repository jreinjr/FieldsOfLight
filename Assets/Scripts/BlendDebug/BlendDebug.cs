using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;

[ExecuteInEditMode]
public class BlendDebug : MonoBehaviour
{

    public Transform eyeCollection;
    [Range(0, 2)]
    public int index;
    List<Transform> eyes;
    List<Color> eyeColors;
    Color color;

    private Renderer Renderer
    {
        get
        {
            if (_renderer == null)
            {
                _renderer = GetComponent<Renderer>();
            }
            return _renderer;
        }
    }
    private Renderer _renderer;


    private MaterialPropertyBlock PropBlock
    {
        get
        {
            if (_propBlock == null)
            {
                _propBlock = new MaterialPropertyBlock();
            }
            return _propBlock;
        }
        set
        {
            _propBlock = value;
        }
    }
    private MaterialPropertyBlock _propBlock;


    private void OnValidate()
    {
        if (eyeCollection)
        {
            eyes = new List<Transform>();

            for (int i = 0; i < eyeCollection.childCount; i++)
            {
                eyes.Add(eyeCollection.GetChild(i));
            }
        }

        eyeColors = new List<Color>();
        eyeColors.Add(Color.red);
        eyeColors.Add(Color.green);
        eyeColors.Add(Color.blue);

    }

    void CalculateWeight(int index)
    {

    }

    private void OnWillRenderObject()
    {
        int[] sorted_keys = new int[3];
        int[] nthLargest = new int[3];
        int blend_N_eyes = 2;
        float[] angDiff = new float[3];

        Vector3 hit_WS = transform.position;
        Vector3 cam_ray_WS = Vector3.Normalize(hit_WS - Camera.current.transform.position);
        List<Vector3> eyes_ray_WS = eyes.Select(e => Vector3.Normalize(hit_WS - e.position)).ToList();

        

        for (int i = 0; i < 3; i++)
        {
            angDiff[i] = (Vector3.Dot(eyes_ray_WS[i], cam_ray_WS) + 1) / 2;

        }

        for (int j = 0; j < 3; j++)
        {
            nthLargest[j] = 0;
            for (int i = 1; i < 3; i++)
            {
                nthLargest[j] += angDiff[(j + i) % 3] > angDiff[j] ? 1 : 0;
            }
            sorted_keys[nthLargest[j]] = j;

        }


      

        float thresh = angDiff[sorted_keys[blend_N_eyes - 1]];

        float[] angBlend = new float[3];

        for (int i = 0; i < 3; i++)
        {
            angBlend[i] = Mathf.Max(0, 1 - (1 - angDiff[i]) / (1 - thresh));

        }

        float angBlendSum = 0;

        for (int i = 0; i < blend_N_eyes; i++)
        {
            angBlendSum += angBlend[sorted_keys[i]];
        }

        float normalizedAngBlend = angBlend[index] / angBlendSum;

        //color = (Vector4)eyes_ray_WS[eyeIndex];
        color = new Color(angDiff[index], 0, 0);


        Renderer.GetPropertyBlock(PropBlock);
        PropBlock.SetColor("_Color", color);
        Renderer.SetPropertyBlock(PropBlock);
    }

    private void Update()
    {
       
    }

    private void OnDrawGizmos()
    {

        for (int i = 0; i < 3; i++)
        {
            Gizmos.matrix = Matrix4x4.TRS(eyes[i].position, eyes[i].rotation, eyes[i].localScale);
            Gizmos.color = eyeColors[i];
            Gizmos.DrawFrustum(Vector3.zero, 90, 10, 0.1f, 1);

        }
    }
}
