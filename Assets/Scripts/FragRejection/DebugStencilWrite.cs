using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;

public class DebugStencilWrite : MonoBehaviour
{
    public Texture stencilTex1;
    public Texture stencilTex2;
    public Renderer sphere1;
    public Renderer sphere2;

    private CommandBuffer cmdBuffer;
    private Material stencilClearMat;

    void OnEnable()
    {
        Camera cam = Camera.main;

        cmdBuffer = new CommandBuffer();
        cmdBuffer.name = "Stencil Write";

        stencilClearMat = new Material(Shader.Find("Unlit/ClearStencil"));

        AddStencilBuffer(sphere1, stencilTex1, cmdBuffer);
        AddStencilBuffer(sphere2, stencilTex2, cmdBuffer);

        cam.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, cmdBuffer);
    }

    void AddStencilBuffer(Renderer rend, Texture stencilTex, CommandBuffer buffer)
    {
        Material mat = new Material(Shader.Find("Unlit/WriteToStencil"));
        mat.mainTexture = stencilTex;
        buffer.Blit(BuiltinRenderTextureType.CurrentActive, BuiltinRenderTextureType.CurrentActive, mat);
        buffer.DrawRenderer(rend, rend.material);
        buffer.Blit(BuiltinRenderTextureType.CurrentActive, BuiltinRenderTextureType.CurrentActive, stencilClearMat);
    }


    void OnDisable()
    {
        Camera cam = GetComponent<Camera>();

        cam.RemoveAllCommandBuffers();
        cmdBuffer = null;
    }
}
