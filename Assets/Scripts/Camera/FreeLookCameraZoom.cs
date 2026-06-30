using Cinemachine;
using UnityEngine;

[RequireComponent(typeof(CinemachineFreeLook))]
public class FreeLookCameraZoom : MonoBehaviour
{
    [Header("缩放范围")]
    [SerializeField] private float minZoomScale = 0.6f; // 最近距离倍率
    [SerializeField] private float maxZoomScale = 2f; // 最远距离倍率

    [Header("缩放手感")]
    [SerializeField] private float scrollSensitivity = 0.15f; // 滚轮灵敏度
    [SerializeField] private float smoothTime = 0.3f; // 缩放缓动时间
    [SerializeField] private bool scaleRigHeight; // 是否同时缩放三层 Rig 高度

    private CinemachineFreeLook freeLook;
    private float[] originalRadii;
    private float[] originalHeights;
    private float currentZoomScale = 1f;
    private float targetZoomScale = 1f;
    private float zoomVelocity;

    /// <summary>
    /// 获取 FreeLook 组件并记录三层 Rig 的初始参数。
    /// </summary>
    private void Awake()
    {
        freeLook = GetComponent<CinemachineFreeLook>();

        int orbitCount = freeLook.m_Orbits.Length;
        originalRadii = new float[orbitCount];
        originalHeights = new float[orbitCount];

        for (int i = 0; i < orbitCount; i++)
        {
            originalRadii[i] = freeLook.m_Orbits[i].m_Radius;
            originalHeights[i] = freeLook.m_Orbits[i].m_Height;
        }
    }

    /// <summary>
    /// 读取鼠标滚轮并更新目标缩放倍率。
    /// </summary>
    private void Update()
    {
        float scroll = Input.mouseScrollDelta.y;
        if (Mathf.Approximately(scroll, 0f))
        {
            return;
        }

        // 滚轮向上拉近，向下拉远
        targetZoomScale -= scroll * scrollSensitivity;
        targetZoomScale = Mathf.Clamp(
            targetZoomScale,
            minZoomScale,
            maxZoomScale);
    }

    /// <summary>
    /// 平滑更新 FreeLook 三层 Rig 的半径和可选高度。
    /// </summary>
    private void LateUpdate()
    {
        currentZoomScale = Mathf.SmoothDamp(
            currentZoomScale,
            targetZoomScale,
            ref zoomVelocity,
            smoothTime);

        for (int i = 0; i < freeLook.m_Orbits.Length; i++)
        {
            var orbit = freeLook.m_Orbits[i];
            orbit.m_Radius = originalRadii[i] * currentZoomScale;

            if (scaleRigHeight)
            {
                orbit.m_Height = originalHeights[i] * currentZoomScale;
            }

            freeLook.m_Orbits[i] = orbit;
        }
    }

    /// <summary>
    /// 在 Inspector 修改参数时保持缩放范围有效。
    /// </summary>
    private void OnValidate()
    {
        minZoomScale = Mathf.Max(0.1f, minZoomScale);
        maxZoomScale = Mathf.Max(minZoomScale, maxZoomScale);
        scrollSensitivity = Mathf.Max(0.01f, scrollSensitivity);
        smoothTime = Mathf.Max(0.01f, smoothTime);
    }
}
