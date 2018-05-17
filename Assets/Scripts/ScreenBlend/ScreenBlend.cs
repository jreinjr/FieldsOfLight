using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class ScreenBlend : SceneViewFilter {

    Texture2D blendingField;
    Material EffectMaterial;

    private void Start()
    {
        EffectMaterial = GetComponent<BlendingField>().blendingFieldMat;
    }

    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, EffectMaterial);
    }

}
