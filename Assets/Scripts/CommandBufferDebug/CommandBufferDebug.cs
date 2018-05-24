using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using System.Linq;

public class CommandBufferDebug : MonoBehaviour {

    private Camera cam;
    private CommandBuffer cmdBuffer;
    private List<RenderTexture> simpleScreens;
    private List<Renderer> simpleBalls;
    private Material stencilClearMat;

    private void Start()
    {
        stencilClearMat = new Material(Shader.Find("Unlit/ClearStencil"));
        cmdBuffer = new CommandBuffer();
        cam = GetComponent<Camera>();
        simpleBalls = FindObjectsOfType<SimpleBall>().Select(ball => ball.gameObject.GetComponent<Renderer>()).ToList();
        simpleScreens = FindObjectsOfType<SimpleScreen>().Select(s => s.RenTex).ToList();
        cmdBuffer.Blit(BuiltinRenderTextureType.CurrentActive, BuiltinRenderTextureType.CurrentActive, stencilClearMat);

        for (int i = 0; i < simpleBalls.Count; i++)
        {
            DrawBalls(simpleScreens[i], simpleBalls[i], cmdBuffer);
        }

        cam.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, cmdBuffer);
    }


    void DrawBalls(RenderTexture screen, Renderer ball, CommandBuffer cb)
    {
        cb.SetRenderTarget(screen);
        cb.ClearRenderTarget(true, true, Color.clear);
        cb.DrawRenderer(ball, ball.sharedMaterial);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(simpleScreens[0], destination);
    }


    private void OnDisable()
    {
        cam.RemoveCommandBuffer(CameraEvent.BeforeForwardOpaque, cmdBuffer);
    }
}
