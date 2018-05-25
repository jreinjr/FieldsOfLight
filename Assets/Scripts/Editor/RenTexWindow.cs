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
    int depthSlice;

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

        depthSlice = (int)GUILayout.HorizontalSlider(depthSlice, 0, 32, GUILayout.MinWidth(100));


        GUILayout.Label(new GUIContent(activeRenTex !=null? activeRenTex.name + " " + depthSlice : "Select Render Texture"));
        GUILayout.EndHorizontal();

        if (activeRenTex != null)
        {
            Rect texRect = new Rect(0, 20, Mathf.Min(position.width, position.height), Mathf.Min(position.width, position.height));

            if (activeRenTex.dimension == UnityEngine.Rendering.TextureDimension.Tex2DArray)
            {
                Material tex2DarrayScreen = new Material(Shader.Find("Unlit/Texture2DArrayScreen"));
                tex2DarrayScreen.SetInt("_DepthSlice", depthSlice);
                EditorGUI.DrawPreviewTexture(texRect, activeRenTex, tex2DarrayScreen, ScaleMode.ScaleToFit);
            }
            else if (activeRenTex.dimension == UnityEngine.Rendering.TextureDimension.Tex2D)
            {
                EditorGUI.DrawPreviewTexture(texRect, activeRenTex, new Material(Shader.Find("Unlit/TextureScreen")), ScaleMode.ScaleToFit);
            }
            else { Debug.LogError("Unexpected dimension for render texture - not 2d array or 2d"); }

        }

    }
}
