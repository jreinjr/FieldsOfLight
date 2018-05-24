using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;

public class BlendingField : MonoBehaviour {

    
    public Texture2D blendingField;
    public Material blendingFieldMat;
    Vector3[] rayArray;
    Vector3 ray;

    public EyeCollection eyeCollection;


    public int width;
    public int height;
    public int count;

    // Use this for initialization
    private void Start()
    {
        //pixelArray = new Color[width * height];
        rayArray = new Vector3[width * height];
        blendingField = new Texture2D(width, height);
        blendingFieldMat.mainTexture = blendingField;
    }

    void UpdateBlendField()
    {

        Matrix4x4 frustrumCorners = GetFrustumCorners(Camera.current) * Matrix4x4.TRS(Camera.current.transform.position, Camera.current.transform.rotation, Camera.current.transform.localScale);

        float[][] weights = new float[eyeCollection.eyes.Count][];
        Color[] weightColors = new Color[height * width];

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                Vector3 topLerp = Vector3.Lerp(frustrumCorners.GetRow(0), frustrumCorners.GetRow(1), (float)x / (float)width);
                Vector3 bottomLerp = Vector3.Lerp(frustrumCorners.GetRow(3), frustrumCorners.GetRow(2), (float)x / (float)width);
                Vector3 bilinearLerp = Vector3.Lerp(topLerp, bottomLerp, (float)y / (float)height);

                ray = new Vector3(bilinearLerp.x, bilinearLerp.y, bilinearLerp.z);
                rayArray[y * width + x] = ray;

                float[] eyeFovWeights = new float[eyeCollection.eyes.Count];

                // Get array of all FOV weights
                for (int i = 0; i < eyeCollection.eyes.Count; i++)
                {
                    Vector3 eyeForward = eyeCollection.eyes[i].transform.forward;
                    eyeFovWeights[i] = Vector3.Dot(eyeForward, ray);
                }

                // Operate on array (0 out all but top 3, normalize those to sum to 1)
                List<float> fovWeightList = eyeFovWeights.ToList();
                var sorted = fovWeightList.ToList()
                    .Select((w, i) => new KeyValuePair<float, int>(w, i))
                    .OrderBy(w => w.Key)
                    .ToList();
                List<float> sortedFovWeightList = sorted.Select(w => w.Key).ToList();
                List<int> idx = sorted.Select(w => w.Value).ToList();
                // fovWeightList[idx[i]] = sortedFovWeightList[i]
                float sumTopFour = sortedFovWeightList.Take(4).Sum();
                for (int i = 0; i < sortedFovWeightList.Count; i++)
                {
                    if (i < 4)
                    {
                        sortedFovWeightList[i] /= sumTopFour;
                    }
                    else
                    {
                        sortedFovWeightList[i] = 0;
                    }

                    fovWeightList[idx[i]] = sortedFovWeightList[i];
                }

                // Iterate through eyeCollection.eyes.Count and set array index [y*height+x] to weight

                for (int i = 0; i < eyeCollection.eyes.Count; i++)
                {
                    weightColors[y * width + x] = new Color(fovWeightList[i], 0, 0);
                }
            }
        }

        blendingField.SetPixels(weightColors);
        blendingField.Apply();
    }

    // Must be on a Camera
	void OnPreRender () {

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
}
