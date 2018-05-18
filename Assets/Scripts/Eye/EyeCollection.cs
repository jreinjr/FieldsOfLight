using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;

[ExecuteInEditMode]
public class EyeCollection : MonoBehaviour {

    public List<Eye> eyes;
    public int eyeCount;
    public DefaultAsset rootTextureFolder;
    public string textureNamingPrefix;

    bool projectorsEnabled = false;

    private void Start()
    {
        eyes = new List<Eye>();
        CheckEyeCount();

    }

    private void Update()
    {
        if (Application.isPlaying == false)
        {
            CheckEyeCount();
        }
    }

    private void CheckEyeCount()
    {
        eyes = GetComponentsInChildren<Eye>().OfType<Eye>().ToList();
        eyeCount = eyes.Count;
    }

    public void RenameChildren()
    {
        for (int i = 0; i < eyes.Count; i++)
        {
            eyes[i].gameObject.name = textureNamingPrefix + "_" + i.ToString("000");
        }
    }

    public void GenerateTextureSubfolders()
    {
        throw new System.NotImplementedException();
    }

    public void RenderAll()
    {
        foreach (Eye e in eyes)
        {
            e.RenderRGB();
            e.RenderZ();
        }
    }

    public void ToggleProjectors()
    {
        projectorsEnabled = !projectorsEnabled;
        foreach (Transform t in eyes.Select(eye => eye.transform))
        {
            GameObject projector = t.Find("Projector").gameObject;
            // Projectors can be individually toggled so the global bool keeps this button in sync
            Debug.Log("Projectors enabled: " + projectorsEnabled);
            projector.SetActive(projectorsEnabled);
        }
    }

    public void RefreshTextures()
    {
        foreach (Eye e in eyes)
        {
            e.RefreshTextures();
        }
    }

}
