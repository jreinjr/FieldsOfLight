using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(EyeCollection))]
public class EyeCollectionEditor : Editor{

    EyeCollection eyeCollection;

    SerializedProperty eyeCount;
    SerializedProperty rootTextureFolder;
    SerializedProperty textureNamingPrefix;

    private void OnEnable()
    {
        eyeCollection = (EyeCollection)target;

        eyeCount = serializedObject.FindProperty("eyeCount");
        rootTextureFolder = serializedObject.FindProperty("rootTextureFolder");
        textureNamingPrefix = serializedObject.FindProperty("textureNamingPrefix"); 
        
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        

        // Current eye count
        EditorGUILayout.Separator();
        EditorGUILayout.LabelField(eyeCount.intValue.ToString() + " child eyes collected", EditorStyles.boldLabel);

        ///////////////////////////////
        // Texture folder & naming setup
        ///////////////////////////////

        // Set default value of texture naming prefix
        if (textureNamingPrefix.stringValue == "")
        {
            textureNamingPrefix.stringValue = "Eye";
        }
        EditorGUILayout.Separator();
        EditorGUILayout.LabelField("Texture Folder Setup", EditorStyles.boldLabel);
        EditorGUILayout.PropertyField(rootTextureFolder);
        EditorGUILayout.PropertyField(textureNamingPrefix);
        EditorGUILayout.LabelField("Example: " + textureNamingPrefix.stringValue + "_###");
        if (GUILayout.Button("Rename children"))
        {
            eyeCollection.RenameChildren();
        }
        //if (GUILayout.Button("Generate texture subfolders"))
        //{
        //    eyeCollection.GenerateTextureSubfolders();
        //}

        ///////////////////////////////
        // Camera actions
        ///////////////////////////////
        EditorGUILayout.Separator();
        EditorGUILayout.LabelField("Camera Actions", EditorStyles.boldLabel);
        if (GUILayout.Button("Render all"))
        {
            eyeCollection.RenderAll();
        }

        ///////////////////////////////
        // Projector actions
        ///////////////////////////////
        EditorGUILayout.Separator();
        EditorGUILayout.LabelField("Projector Actions", EditorStyles.boldLabel);
        if (GUILayout.Button("Toggle projectors"))
        {
            eyeCollection.ToggleProjectors();
        }
        if (GUILayout.Button("Refresh textures"))
        {
            eyeCollection.RefreshTextures();
        }

        serializedObject.ApplyModifiedProperties();

    }
}
