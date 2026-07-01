using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PostProcessManager : SingletonMono<PostProcessManager>
{
    public Volume volume;
    private ChromaticAberration chromaticAberration;
    private float value;
    [SerializeField]private float speed;
    void Start()
    {
        volume.profile.TryGet(out chromaticAberration);
    }

    /// <summary>
    /// 色差效果
    /// </summary>
    /// <param name="value"></param>
    public void ChromaticAberrationEF(float value)
    {
        StopAllCoroutines();//避免多次触发
        StartCoroutine(StartChromaticAberrationEF(value));
    }

    IEnumerator StartChromaticAberrationEF(float value)
    {
        //递增到value
        while (chromaticAberration.intensity.value < value)
        {
            yield return null;
            chromaticAberration.intensity.value += Time.deltaTime * speed;
        }
        //递减到0
        while (chromaticAberration.intensity.value > 0)
        {
            yield return null;
            chromaticAberration.intensity.value -= Time.deltaTime * speed;
        }
    }

}
