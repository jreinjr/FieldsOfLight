using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class SurfaceRaytrace : MonoBehaviour {

    [SerializeField]
    private Shader _EffectShader;

    public Material EffectMaterial
    {
        get
        {
            if (!_EffectMaterial && _EffectShader)
            {
                _EffectMaterial = new Material(_EffectShader);
                _EffectMaterial.hideFlags = HideFlags.HideAndDontSave;
            }

            return _EffectMaterial;
        }
    }
    private Material _EffectMaterial;


    EyeCollection eyeCollection;

    ProceduralFrustum frustrum;
    Matrix4x4 frustrumMVP;
    Matrix4x4 frustrumPerspective;
    public Texture rgb_Tex;
    public Texture z_Tex;

	// Use this for initialization
	void Start () {
        frustrum = GetComponent<ProceduralFrustum>();
        frustrumPerspective = new Matrix4x4();
        eyeCollection = transform.parent.GetComponentInParent<EyeCollection>();
        GetComponent<Renderer>().material = EffectMaterial;
    }

    public void RefreshTextures()
    {
        string texturePath_RGB = AssetDatabase.GetAssetPath(eyeCollection.rootTextureFolder) + "/" + transform.parent.gameObject.name + "_rgb.png";
        string texturePath_Z = AssetDatabase.GetAssetPath(eyeCollection.rootTextureFolder) + "/"+transform.parent.gameObject.name + "_z.exr";

        Debug.Log("Loading texture " + texturePath_RGB);
        rgb_Tex = (Texture)AssetDatabase.LoadAssetAtPath(texturePath_RGB, typeof(Texture));
        Debug.Log("Loading texture " + texturePath_Z);
        z_Tex = (Texture)AssetDatabase.LoadAssetAtPath(texturePath_Z, typeof(Texture));
    }

    private void Update()
    {
        if(!rgb_Tex || !z_Tex)
        {
            RefreshTextures();
        }

        EffectMaterial.SetFloat("_farClip", frustrum.farClip);
        EffectMaterial.SetFloat("_nearClip", frustrum.nearClip);
        EffectMaterial.SetTexture("_MainTex", rgb_Tex);
        EffectMaterial.SetTexture("_zTex", z_Tex);
        EffectMaterial.SetVector("_eyeFwd", transform.forward);
    }
}
