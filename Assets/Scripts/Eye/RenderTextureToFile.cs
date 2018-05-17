using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;
using System;

[ExecuteInEditMode]
public class RenderTextureToFile : MonoBehaviour {

    Camera camera_RGB;
    Camera camera_Z;

    RenderTexture renderTexture_RGB;
    RenderTexture renderTexture_Z;

    EyeCollection eyeCollection;
    string texturePath;

    private void Awake()
    {
        camera_RGB = transform.Find("Camera_RGB").GetComponent<Camera>();
        camera_Z = transform.Find("Camera_Z").GetComponent<Camera>();

        renderTexture_RGB = camera_RGB.targetTexture;
        renderTexture_Z = camera_Z.targetTexture;

        eyeCollection = transform.parent.GetComponentInParent<EyeCollection>();
        // texturePath is set by eyeCollection root folder property; starts after 'Assets' and ends with /
        texturePath = AssetDatabase.GetAssetPath(eyeCollection.rootTextureFolder);
        texturePath = texturePath.Split(new string[1] { "Assets" }, StringSplitOptions.None)[1] + "/";

    }


    public void RenderRGB()
    {
        // Create new Texture2D to store our RenderTexture data
        Texture2D texToWrite = new Texture2D(renderTexture_RGB.width, renderTexture_RGB.height, TextureFormat.RGB24, false);
        // Set RGB renderTexture to active
        RenderTexture.active = renderTexture_RGB;
        // Read renderTexture data into our new Texture2D
        texToWrite.ReadPixels(new Rect(0, 0, renderTexture_RGB.width, renderTexture_RGB.height), 0, 0);
        texToWrite.Apply();
        // Create byte array to encode our Texture2D as a PNG
        byte[] bytes = texToWrite.EncodeToPNG();
        // imagePath starts with C:/
        string imagePath = Application.dataPath + texturePath + gameObject.name + "_rgb.png";
        Debug.Log("Writing file " + imagePath);
        File.WriteAllBytes(imagePath, bytes);
        // Import our texture at the end
        RefreshImports();

    }


    public void RenderZ()
    {
        // Create new Texture2D to store our RenderTexture data
        Texture2D texToWrite = new Texture2D(renderTexture_Z.width, renderTexture_Z.height, TextureFormat.RGBAFloat, false);
        // Set Z renderTexture to active
        RenderTexture.active = renderTexture_Z;
        // Read renderTexture data into our new Texture2D
        texToWrite.ReadPixels(new Rect(0, 0, renderTexture_Z.width, renderTexture_Z.height), 0, 0);
        texToWrite.Apply();
        byte[] bytes = texToWrite.EncodeToEXR();
        // imagePath starts with C:/
        string imagePath = Application.dataPath + texturePath + gameObject.name + "_z.exr";
        Debug.Log("Writing file " + imagePath);
        File.WriteAllBytes(imagePath, bytes);
        // Import our texture at the end
        RefreshImports();

    }

    void RefreshImports()
    {
        AssetDatabase.Refresh();
    }

}
