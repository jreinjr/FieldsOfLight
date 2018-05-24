using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Linq;

public class RenTexWindow : EditorWindow {
    [MenuItem("Window/RenTexWindow")]
    public static void ShowWindow()
    {
        RenTexWindow window = CreateInstance<RenTexWindow>();
        window.Init();
        window.Show();
    }

    [SerializeField]
    RenderTexture activeRenTex;
    List<RenderTexture> availableRenTex;

    void Init()
    {
        availableRenTex = new List<RenderTexture>();
        GetAvailableRenTex();
        activeRenTex = availableRenTex[0];
    }

    void AddMenuItemForTexture(GenericMenu menu, Texture tex)
    {
        menu.AddItem(new GUIContent(tex.name), activeRenTex.Equals(tex), OnTexSelected, tex);
    }

    void GetAvailableRenTex()
    {
        availableRenTex = FindObjectsOfType(typeof(RenderTexture)).Select(o => (RenderTexture)o).ToList();
    }

    void OnTexSelected(object tex)
    {
        activeRenTex = (RenderTexture)tex;
    }

    private void OnGUI()
    {
        GUILayout.BeginVertical();
        GUILayout.BeginHorizontal();
        if (GUILayout.Button("Select render texture"))
        {
            GenericMenu menu = new GenericMenu();
            GetAvailableRenTex();

            foreach (RenderTexture rt in availableRenTex)
            {
                AddMenuItemForTexture(menu, rt);
            }

            menu.ShowAsContext();
        }
        GUILayout.Label(new GUIContent(activeRenTex !=null? activeRenTex.name : "Select Render Texture"));
        GUILayout.EndHorizontal();

        if (activeRenTex != null)
        {
            Rect texRect = new Rect(0, 20, Mathf.Min(position.width, position.height), Mathf.Min(position.width, position.height));
            EditorGUI.DrawPreviewTexture(texRect, activeRenTex, new Material(Shader.Find("Unlit/Texture")), ScaleMode.ScaleToFit);
        }

    }
}
