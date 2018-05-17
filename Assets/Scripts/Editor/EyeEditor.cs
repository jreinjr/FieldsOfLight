using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(Eye))]
[ExecuteInEditMode]
[CanEditMultipleObjects]
public class EyeEditor : Editor {

    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();
        Eye thisEye = (Eye)target;

        ///////////////////////////////
        // Camera actions
        ///////////////////////////////
        EditorGUILayout.Separator();
        EditorGUILayout.LabelField("Camera Actions", EditorStyles.boldLabel);
       
        if (GUILayout.Button("Render RGB"))
        {
            thisEye.RenderRGB();

        }
        if (GUILayout.Button("Render Z"))
        {
            thisEye.RenderZ();
        }


        ///////////////////////////////
        // Projector actions
        ///////////////////////////////
        EditorGUILayout.Separator();
        EditorGUILayout.LabelField("Projector Actions", EditorStyles.boldLabel);
        if (GUILayout.Button("Toggle Projector"))
        {
            thisEye.ToggleProjector();
        }
        if (GUILayout.Button("Link RenderTextures"))
        {
            thisEye.RefreshTextures();
        }

    }
}
