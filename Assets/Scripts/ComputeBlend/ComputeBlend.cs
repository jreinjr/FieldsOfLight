﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(Camera))]
public class ComputeBlend : MonoBehaviour {

    public ComputeShader computeShader;
    public Renderer debugRenderer;

    private Camera cam;
    private CommandBuffer cmdBufferBeforeOpaque;
    private CommandBuffer cmdBufferAfterOpaque;
    private CommandBuffer cmdBufferAfterEverything;
    private RenderTargetIdentifier defaultRenderTarget;


    private Material stencilClearMat;
    private Material writeToStencilMat;
    private Texture whiteTex;

    private RenderTexture hitTex;
    private RenderTexture blendTex;
    // used for 
    private Vector2Int hitTexRes = new Vector2Int(64, 64);
    private Vector2Int blendTexRes = new Vector2Int(64, 64);

    int BlendKernel;

    private void Start()
    {
        // Declare materials
        stencilClearMat = new Material(Shader.Find("Unlit/ClearStencil"));
        writeToStencilMat = new Material(Shader.Find("Unlit/WriteToStencil"));
        // Set up Command Buffer
        cmdBufferBeforeOpaque = new CommandBuffer();
        cmdBufferBeforeOpaque.name = "BeforeOpaque";
        cmdBufferAfterOpaque = new CommandBuffer();
        cmdBufferAfterOpaque.name = "AfterOpaque";
        cmdBufferAfterEverything = new CommandBuffer();
        cmdBufferAfterEverything.name = "AfterEverything";
        cam = GetComponent<Camera>();

        // hitTex is generated by a vert+frag shader running on each frustum
        if(hitTex == null)
        {
            hitTex = new RenderTexture(hitTexRes.x, hitTexRes.y, 0, RenderTextureFormat.ARGBFloat);
            //hitTex.dimension = TextureDimension.Tex2DArray;
            hitTex.name = "HitTex";
            //hitTex.filterMode = FilterMode.Point;
            hitTex.Create();
        }
        
        // blendTex will be generated by compute shader using one hitTex per Eye
        if(blendTex == null)
        {
            blendTex = new RenderTexture(blendTexRes.x, blendTexRes.y, 0, RenderTextureFormat.ARGBFloat);
            blendTex.name = "BlendTex";
            blendTex.enableRandomWrite = true;
            blendTex.Create();
        }


        // Set up Compute Shader
        BlendKernel = computeShader.FindKernel("Blend");
        computeShader.SetTexture(BlendKernel, "hitTex", hitTex);
        computeShader.SetTexture(BlendKernel, "blendTex", blendTex);

        cmdBufferBeforeOpaque.SetGlobalFloat(Shader.PropertyToID("_StencilMask"), 0);
        cmdBufferBeforeOpaque.Blit(BuiltinRenderTextureType.CurrentActive, BuiltinRenderTextureType.CurrentActive, stencilClearMat);

        // Draw hit pass to hitTex
        cmdBufferBeforeOpaque.SetRenderTarget(hitTex);
        cmdBufferBeforeOpaque.ClearRenderTarget(true, true, Color.clear);
        cmdBufferBeforeOpaque.DrawRenderer(debugRenderer, debugRenderer.sharedMaterial, 0, 0);


        // Dispatch compute shader to compute blendTex
        cmdBufferBeforeOpaque.DispatchCompute(computeShader, BlendKernel, blendTexRes.x / 8, blendTexRes.y / 8, 1);

        writeToStencilMat.SetTexture("_MainTex", blendTex);
        debugRenderer.sharedMaterial.SetTexture("_BlendTex", blendTex);

        cmdBufferAfterEverything.Blit(BuiltinRenderTextureType.CurrentActive, BuiltinRenderTextureType.CurrentActive, writeToStencilMat);

        cmdBufferAfterEverything.DrawRenderer(debugRenderer, debugRenderer.sharedMaterial, 0, 1);

        cam.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, cmdBufferBeforeOpaque);
        cam.AddCommandBuffer(CameraEvent.AfterForwardOpaque, cmdBufferAfterOpaque);
        cam.AddCommandBuffer(CameraEvent.AfterEverything, cmdBufferAfterEverything);

    }


    private void OnDisable()
    {
        cam.RemoveCommandBuffer(CameraEvent.BeforeForwardOpaque, cmdBufferBeforeOpaque);
        hitTex.Release();
        blendTex.Release();
    }
}
