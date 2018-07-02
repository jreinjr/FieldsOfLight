using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEditor;

public class RaytraceMaterialEditor : ShaderGUI {

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);

        Material targetMat = materialEditor.target as Material;

        bool stencil = Array.IndexOf(targetMat.shaderKeywords, "STENCIL_ON") != -1;
        bool proxy = Array.IndexOf(targetMat.shaderKeywords, "PROXY_ON") != -1;

        EditorGUI.BeginChangeCheck();
        stencil = EditorGUILayout.Toggle("Stencil", stencil);
        proxy = EditorGUILayout.Toggle("Proxy", proxy);
        if (EditorGUI.EndChangeCheck())
        {
            if (stencil)
                targetMat.EnableKeyword("STENCIL_ON");
            else
                targetMat.DisableKeyword("STENCIL_ON");
            if (proxy)
                targetMat.EnableKeyword("PROXY_ON");
            else
                targetMat.DisableKeyword("PROXY_ON");
        }
    }
}
