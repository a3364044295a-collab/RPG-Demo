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
    [Header("攻击范围")]
    public float AttackRadius = 2f;
    public float AttackAngle = 90f;
    public Vector3 AttackOffset;

    [Tooltip("本段攻击开启的武器索引")]
    public int[] WeaponIndexes;
    [Tooltip("产生的粒子")]
    public Skill_SpawnObj[] SpawnObj;
    [Tooltip("技能音效")]
    public AudioClip AudioClip;

    [Header("命中效果")]
    [Tooltip("伤害数值")]
    public float DamgeValue;
    [Tooltip("硬直时间")]
    public float HardTime;
    [Tooltip("击退程度")]
    public Vector3 RepelVelocity;
    [Tooltip("击飞击退的过渡时间")]
    public float RepelTime;
    [Tooltip("屏幕震动")]
    public float ScreenImpulseValue;
    [Tooltip("色差效果")]
    public float ChromaticAberrationValue;
    [Tooltip("卡肉效果持续时间")]
    public float FreezeFrameTime;
    [Tooltip("命中时缩放时间")]
    public float ScaleTime;
    [Tooltip("命中效果")]
    public SkillHitEFConfig SkillHitEFConfig;
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
    [Tooltip("可选。填写角色模型子物体名称后，粒子会以该挂点为坐标系生成。留空则使用角色模型根节点。")]
    public string AttachPointName;
    //位置
    public Vector3 Position;
    //旋转
    public Vector3 Rotation;
    //缩放
    public Vector3 Scale = Vector3.one;
    //延迟时间
    public float Time;
    //跳过特效前面的空白时间
    public float SkipTime;
}