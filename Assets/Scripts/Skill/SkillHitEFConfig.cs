using UnityEngine;

[CreateAssetMenu(menuName = "Config/SkillHitEF")]
public class SkillHitEFConfig : ScriptableObject
{
    //产生的粒子物体
    public Skill_SpawnObj[] SpawnObj;
    //命中时音效
    public AudioClip AudioClip;
}
