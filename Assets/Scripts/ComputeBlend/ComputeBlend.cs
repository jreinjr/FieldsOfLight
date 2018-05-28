﻿using System.Collections;
using System.Linq;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(Camera))]
public class ComputeBlend : MonoBehaviour {

    public EyeCollection eyeCollection;
    private List<Renderer> eyeRenderers;
    private Camera cam;
    
    private void Start()
    {
        cam = GetComponent<Camera>();
        eyeRenderers = eyeCollection.eyes.Select(e => e.GetComponentInChildren<Renderer>()).ToList();

        InitRenderTextures();
        InitStencilMaterials();
        InitComputeBuffers();
        InitComputeShaders();
        InitCommandBuffers();

        // StencilMat will use blendtex for main texture, Eyes use as blend texture
        // This needs to be reorganized.
        // Will this work? Setting shared material on first eyeRenderer?
        for (int i = 0; i < eyeRenderers.Count; i++)
        {
            eyeRenderers[i].sharedMaterial.SetTexture("_BlendTex", blendTex);
            eyeRenderers[i].sharedMaterial.SetInt("_DepthSlice", i);
        }
        //eyeRenderers[0].sharedMaterial.SetTexture("_BlendTex", blendTex);

    }

    /////////////////////////////////////
    // Render Texture Setup
    /////////////////////////////////////
    private RenderTexture hitTex;
    private RenderTexture blendTex;
    private Vector2Int hitTexRes = new Vector2Int(256, 256);
    private Vector2Int blendTexRes = new Vector2Int(256, 256);
    /// <summary>
    /// Declares array textures hitTex and blendTex.
    /// hitTex stores raytrace hit positions for each Eye.
    /// blendTex stores stencil and blend weights.
    /// </summary>
    void InitRenderTextures()
    {
        // hitTex is generated by a vert+frag shader running on each frustum
        hitTex = new RenderTexture(hitTexRes.x, hitTexRes.y, 0, RenderTextureFormat.ARGBFloat);
        hitTex.dimension = TextureDimension.Tex2DArray;
        hitTex.volumeDepth = eyeRenderers.Count;
        hitTex.filterMode = FilterMode.Point;
        hitTex.name = "HitTex";
        hitTex.Create();
        // blendTex will be generated by compute shader using one hitTex per Eye
        blendTex = new RenderTexture(blendTexRes.x, blendTexRes.y, 0, RenderTextureFormat.ARGBFloat);
        blendTex.dimension = TextureDimension.Tex2DArray;
        blendTex.volumeDepth = eyeRenderers.Count;
        blendTex.name = "BlendTex";
        blendTex.enableRandomWrite = true;
        blendTex.Create();
    }

    /////////////////////////////////////
    // Material Setup
    /////////////////////////////////////
    private Material stencilClearMat;
    private Material writeToStencilMat;
    /// <summary>
    /// Declares materials that wipe stencil buffer to 0 or write to it based on greyscale texture value.
    /// </summary>
    void InitStencilMaterials()
    {
        // Declare materials
        stencilClearMat = new Material(Shader.Find("Unlit/ClearStencil"));
        writeToStencilMat = new Material(Shader.Find("Unlit/WriteToStencil"));
        writeToStencilMat.SetTexture("_MainTex", blendTex);
    }

    /////////////////////////////////////
    // Compute Buffer Setup
    /////////////////////////////////////
    private ComputeBuffer eyeDataBuffer;
    private struct EyeData
    {
        public Vector3 eyePos;
        public Vector3 eyeFwd;
    }
    /// <summary>
    /// Declares a compute buffer to pass Eye world space positions to our compute blend shader.
    /// </summary>
    void InitComputeBuffers()
    {
        EyeData[] eyeDataArray = new EyeData[eyeRenderers.Count];
        for (int i = 0; i < eyeDataArray.Length; i++)
        {
            eyeDataArray[i].eyePos = eyeRenderers[i].gameObject.transform.position;
            eyeDataArray[i].eyeFwd = eyeRenderers[i].gameObject.transform.forward;
        }
        eyeDataBuffer = new ComputeBuffer(eyeRenderers.Count, sizeof(float) * 6, ComputeBufferType.Default);
        eyeDataBuffer.SetData(eyeDataArray);
    }

    /////////////////////////////////////
    // Compute Shader Setup
    /////////////////////////////////////
    public ComputeShader computeShader;
    int BlendKernel;
    /// <summary>
    /// Given WS raytrace hits and camera centers for each Eye, outputs
    /// blend weights and stencil (where blend == 0).
    /// </summary>
    void InitComputeShaders()
    {
        // Set up Compute Shader
        BlendKernel = computeShader.FindKernel("Blend");
        computeShader.SetTexture(BlendKernel, "hitTex", hitTex);
        computeShader.SetTexture(BlendKernel, "blendTex", blendTex);
        computeShader.SetBuffer(BlendKernel, "eyeDataBuffer", eyeDataBuffer);
        computeShader.SetInt("_EyeCount", eyeRenderers.Count);
    }

    /////////////////////////////////////
    // Command Buffer Setup
    /////////////////////////////////////
    private CommandBuffer cmdBufferBeforeOpaque;
    private CommandBuffer cmdBufferAfterEverything;
    /// <summary>
    /// Each Eye is raytraced and hits are stored in a low res array texture.
    /// Compute Buffer is executed to compute stencil and blend weights.
    /// Eyes are raytraced and blended again only where weight > 0.
    /// </summary>
    void InitCommandBuffers()
    {
        /////////////////////////////////////
        // Command Buffer: Before Opaque
        /////////////////////////////////////
        cmdBufferBeforeOpaque = new CommandBuffer();
        cmdBufferBeforeOpaque.name = "BeforeOpaque";
        for (int i = 0; i < eyeRenderers.Count; i++)
        {
            // Draw hit pass (pass 0) to hitTex
            cmdBufferBeforeOpaque.SetRenderTarget(hitTex, 0, CubemapFace.Unknown, i);
            cmdBufferBeforeOpaque.ClearRenderTarget(true, true, Color.clear);
            // Draw low res raytrace hit to hitTex
            cmdBufferBeforeOpaque.DrawRenderer(eyeRenderers[i], eyeRenderers[i].sharedMaterial, 0, 2);
            cmdBufferBeforeOpaque.DrawRenderer(eyeRenderers[i], eyeRenderers[i].sharedMaterial, 0, 0);
        }
        // Dispatch compute shader to compute blendTex from hitTex
        cmdBufferBeforeOpaque.DispatchCompute(computeShader, BlendKernel, blendTexRes.x, blendTexRes.y, 1);
        cam.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, cmdBufferBeforeOpaque);

        /////////////////////////////////////
        // Command Buffer: After Everything
        /////////////////////////////////////
        cmdBufferAfterEverything = new CommandBuffer();
        cmdBufferAfterEverything.name = "AfterEverything";
        for (int i = 0; i < eyeRenderers.Count; i++)
        {
            cmdBufferAfterEverything.Blit(BuiltinRenderTextureType.CurrentActive, BuiltinRenderTextureType.CurrentActive, stencilClearMat);
            // Blit stencilMat to screen for each Eye
            cmdBufferAfterEverything.SetGlobalInt("_WriteToStencilLayer", i);
            cmdBufferAfterEverything.Blit(BuiltinRenderTextureType.CurrentActive, BuiltinRenderTextureType.CurrentActive, writeToStencilMat);
            // Draw high res texture hit
            cmdBufferAfterEverything.DrawRenderer(eyeRenderers[i], eyeRenderers[i].sharedMaterial, 0, 3);
            cmdBufferAfterEverything.DrawRenderer(eyeRenderers[i], eyeRenderers[i].sharedMaterial, 0, 1);
        }
        cam.AddCommandBuffer(CameraEvent.AfterEverything, cmdBufferAfterEverything);
    }

    /////////////////////////////////////
    // Update camera information per frame
    /////////////////////////////////////
    private void OnPreRender()
    {
        computeShader.SetVector("_camPos", Camera.current.transform.position);
    }

    /////////////////////////////////////
    // Cleanup
    /////////////////////////////////////
    private void OnDisable()
    {
        cam.RemoveCommandBuffer(CameraEvent.BeforeForwardOpaque, cmdBufferBeforeOpaque);
        cam.RemoveCommandBuffer(CameraEvent.AfterEverything, cmdBufferAfterEverything);
        hitTex.Release();
        blendTex.Release();
        eyeDataBuffer.Dispose();
    }
}
