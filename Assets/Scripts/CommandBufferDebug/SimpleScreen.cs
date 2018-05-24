using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SimpleScreen : MonoBehaviour {

    public RenderTexture RenTex
    {
        get
        {
            if (_renTex == null)
            {
                _renTex = new RenderTexture(256, 256, 0, RenderTextureFormat.ARGB32);
                _renTex.name = gameObject.name + "_RenderTexture";
                RenTex.Create();
            }
            return _renTex;
        }
    }
    private RenderTexture _renTex;

    private MaterialPropertyBlock PropBlock
    {
        get
        {
            if (_propBlock == null)
            {
                _propBlock = new MaterialPropertyBlock();
            }
            return _propBlock;
        }
        set
        {
            _propBlock = value;
        }
    }
    private MaterialPropertyBlock _propBlock;


    private Renderer rend;

    private void OnEnable()
    {
        rend = GetComponent<Renderer>();
        rend.GetPropertyBlock(PropBlock);
        PropBlock.SetTexture("_MainTex", RenTex);
        rend.SetPropertyBlock(PropBlock);
    }

    private void OnDisable()
    {
        RenTex.Release();
    }
} 
