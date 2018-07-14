using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEditor;

public class RaytraceMaterialEditor : ShaderGUI {

    // Texture properties
    MaterialProperty _RGBTex;
    MaterialProperty _ZTex;
    MaterialProperty _StencilTex;
    MaterialProperty _BlendTex;

    // Feature properties
    MaterialProperty _SeparateRGBZ;
    MaterialProperty _StencilEnabled;
    MaterialProperty _BlendEnabled;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // Find properties
        _RGBTex = ShaderGUI.FindProperty("_RGBTex", properties);
        _ZTex = ShaderGUI.FindProperty("_ZTex", properties);
        _StencilTex = ShaderGUI.FindProperty("_StencilTex", properties);
        _BlendTex = ShaderGUI.FindProperty("_BlendTex", properties);
        _SeparateRGBZ = ShaderGUI.FindProperty("_SeparateRGBZ", properties);
        _StencilEnabled = ShaderGUI.FindProperty("_StencilEnabled", properties);
        _BlendEnabled = ShaderGUI.FindProperty("_BlendEnabled", properties);

        // Show RGB tex properties
        materialEditor.ShaderProperty(_RGBTex, _RGBTex.displayName);

        // Show Z tex properties
        materialEditor.ShaderProperty(_SeparateRGBZ, _SeparateRGBZ.displayName);
        if (_SeparateRGBZ.floatValue == 1)
            materialEditor.ShaderProperty(_ZTex, _ZTex.displayName);

        // Show Stencil tex properties
        materialEditor.ShaderProperty(_StencilEnabled, _StencilEnabled.displayName);
        if (_StencilEnabled.floatValue == 1)
            materialEditor.ShaderProperty(_StencilTex, _StencilTex.displayName);

        // Show Blend tex properties
        materialEditor.ShaderProperty(_BlendEnabled, _BlendEnabled.displayName);
        if (_BlendEnabled.floatValue == 1)
            materialEditor.ShaderProperty(_BlendTex, _BlendTex.displayName);

        EditorGUILayout.Vector2Field("test", Vector2.zero);

        //base.OnGUI(materialEditor, properties);

        //Material targetMat = materialEditor.target as Material;


        //bool stencil = Array.IndexOf(targetMat.shaderKeywords, "STENCIL_ON") != -1;
        //bool proxy = Array.IndexOf(targetMat.shaderKeywords, "PROXY_ON") != -1;

        //EditorGUI.BeginChangeCheck();
        //stencil = EditorGUILayout.Toggle("Stencil", stencil);
        //proxy = EditorGUILayout.Toggle("Proxy", proxy);
        //if (EditorGUI.EndChangeCheck())
        //{
        //    if (stencil)
        //        targetMat.EnableKeyword("STENCIL_ON");
        //    else
        //        targetMat.DisableKeyword("STENCIL_ON");
        //    if (proxy)
        //        targetMat.EnableKeyword("PROXY_ON");
        //    else
        //        targetMat.DisableKeyword("PROXY_ON");
        //}
    }
}
