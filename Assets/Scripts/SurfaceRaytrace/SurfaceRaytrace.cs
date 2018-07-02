using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class SurfaceRaytrace : MonoBehaviour {

    [SerializeField]
    private Shader _EffectShader;

    public Material EffectMaterial
    {
        get
        {
            _EffectMaterial = GetComponent<Renderer>().material;

            if (!_EffectMaterial && _EffectShader)
            {
                _EffectMaterial = new Material(_EffectShader);
                _EffectMaterial.hideFlags = HideFlags.HideAndDontSave;
            }

            return _EffectMaterial;
        }
    }
    private Material _EffectMaterial;

    public Renderer Renderer
    {
        get
        {
            if (_renderer == null)
            {
                _renderer = GetComponent<Renderer>();
            }
            return _renderer;
        }
    }
    private Renderer _renderer;

    EyeCollection eyeCollection;

    ProceduralFrustum frustum;
    Matrix4x4 frustrumMVP;
    Matrix4x4 frustrumPerspective;
    public Texture rgb_Tex;
    public Texture z_Tex;

	// Use this for initialization
	void Start () {
        frustum = GetComponent<ProceduralFrustum>();
        frustrumPerspective = new Matrix4x4();
        //eyeCollection = transform.parent.GetComponentInParent<EyeCollection>();
        Renderer.material = EffectMaterial;
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

    private void OnWillRenderObject()
    {
    }

    private void Update()
    {
        if(!rgb_Tex || !z_Tex)
        {
            RefreshTextures();
        }

        if (frustum.IsPointInsideFrustum(Camera.main.transform.position, 0.1f))
        {
            EffectMaterial.EnableKeyword("CAMERA_INSIDE");
            EffectMaterial.DisableKeyword("CAMERA_OUTSIDE");

            EffectMaterial.SetFloat("_Cull", 1);
        }
        else
        {
            EffectMaterial.EnableKeyword("CAMERA_OUTSIDE");
            EffectMaterial.DisableKeyword("CAMERA_INSIDE");

            EffectMaterial.SetFloat("_Cull", 2);
        }

        EffectMaterial.SetFloat("_farClip", frustum.farClip);
        EffectMaterial.SetFloat("_nearClip", frustum.nearClip);
        EffectMaterial.SetTexture("_MainTex", rgb_Tex);
        EffectMaterial.SetTexture("_zTex", z_Tex);
        EffectMaterial.SetVector("_eyeFwd", transform.forward);
    }
}
