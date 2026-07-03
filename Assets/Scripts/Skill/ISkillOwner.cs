using UnityEngine;

public interface ISkillOwner
{
    void StartSkillHit(int weaponIndex);

    void StopSkillHit(int weaponIndex);

    void SkillCanSwitch();
    void OnHit(IHurt target, Vector3 hitPositoin);
    void OnFootStep();
    SkillAttackData GetAttackData(int attackDataIndex);
}
