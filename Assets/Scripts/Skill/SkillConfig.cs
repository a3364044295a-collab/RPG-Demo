using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName ="Config/Skill")]
public class SkillConfig : ScriptableObject
{
    //技能的动画名称
    public string AnimationName;
    public Skill_ReleaseData ReleaseData;
    public SkillAttackData[] AttackData;
}

/// <summary>
/// 技能释放数据
/// </summary>
[Serializable]
public class Skill_ReleaseData
{
    //产生的粒子
    public Skill_SpawnObj SpawnObj;
    //技能音效
    public AudioClip AudioClip;
}

/// <summary>
/// 技能攻击数据
/// </summary>
[Serializable]
public class SkillAttackData
{
    //产生的粒子
    public Skill_SpawnObj SpawnObj;
    //技能音效
    public AudioClip AudioClip;
    //命中数据
}

/// <summary>
/// 技能产生的物体
/// </summary>
[Serializable]
public class Skill_SpawnObj
{
    //生成的预制体
    public GameObject Prefab;
    //生成的音效
    public AudioClip AudioClip;
    //位置
    public Vector3 Position;
    //旋转
    public Vector3 Rotation;
    //延迟时间
    public float Time;
}