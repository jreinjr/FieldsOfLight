using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SimpleBall : MonoBehaviour {

    public Color color;

    private Renderer Renderer
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


    private void OnValidate()
    {
        Renderer.GetPropertyBlock(PropBlock);
        PropBlock.SetColor("_Color", color);
        Renderer.SetPropertyBlock(PropBlock);
    }
}
