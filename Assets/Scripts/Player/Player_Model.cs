using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player_Model : MonoBehaviour
{
    [SerializeField] private Animator animator;
    public Animator Animator { get { return animator; } }
    private ISkillOwner skillOwner;
    [SerializeField] Weapon_Controller[] weapons;

    public void Init(ISkillOwner skillOwner, List<string> enemyTagList)
    {
        //this.footStepAction = footStepAction;
        this.skillOwner = skillOwner;
        for (int i = 0; i < weapons.Length; i++)
        {
            weapons[i].Init(enemyTagList, skillOwner.OnHit);
        }
    }

    #region 根运动
    private Action<Vector3, Quaternion> rootMotionAction;

    public void SetRootMotionAction(Action<Vector3, Quaternion> rootMotionAction)
    {
        this.rootMotionAction = rootMotionAction;
    }

    public void ClearRootMotionAction()
    {
        rootMotionAction = null;
    }

    private void OnAnimatorMove()
    {
        rootMotionAction?.Invoke(animator.deltaPosition, animator.deltaRotation);
    }
    #endregion

    #region 动画事件
    private void FootStep()
    {
        skillOwner.OnFootStep();
    }

    private void StartSkillHit(int attackDataIndex)
    {
        skillOwner.StartSkillHit(attackDataIndex);//实现音效特效等

        //SkillAttackData attackData = skillOwner.GetAttackData(attackDataIndex);//获取该段攻击的配置

        //foreach (int weaponIndex in attackData.WeaponIndexes)
        //{
        //    weapons[weaponIndex].StartSkillHit();
        //}
    }

    private void StopSkillHit(int attackDataIndex)
    {
        skillOwner.StopSkillHit(attackDataIndex);

        //SkillAttackData attackData = skillOwner.GetAttackData(attackDataIndex);

        //foreach (int weaponIndex in attackData.WeaponIndexes)
        //{
        //    weapons[weaponIndex].StopSkillHit();
        //}
    }

    private void SkillCanSwitch()
    {
        skillOwner.SkillCanSwitch();
    }

    #endregion
}
