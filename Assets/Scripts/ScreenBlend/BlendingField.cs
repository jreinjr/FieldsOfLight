using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BlendingField : MonoBehaviour {

    
    public Texture2D blendingField;
    public Material blendingFieldMat;
    Color[] pixelArray;
    Color pixelColor;


    public int width;
    public int height;
    public int count;

    // Use this for initialization
    private void Start()
    { 
        pixelArray = new Color[width * height];
        blendingField = new Texture2D(width, height);
        blendingFieldMat.mainTexture = blendingField;
    }



	void OnPreRender () {
        for (int i = 0; i < count; i++)
        {
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    if (y == height / 2 && x == width /2)
                    {
                        pixelColor = Color.white;
                    }
                    else
                    {
                        pixelColor = Color.black;
                    }

                    pixelArray[y * height + x] = pixelColor;
                }
            }

            blendingField.SetPixels(pixelArray);
            blendingField.Apply();
        }
    }
}
