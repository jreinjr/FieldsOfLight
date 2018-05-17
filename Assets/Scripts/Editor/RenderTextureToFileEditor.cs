using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(RenderTextureToFile))]
public class RenderTextureToFileEditor : Editor {

    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        
    }
}
