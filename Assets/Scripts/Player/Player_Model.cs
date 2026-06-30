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

    private void StartSkillHit(int weaponIndex)
    {
        skillOwner.StartSkillHit(weaponIndex);
        weapons[weaponIndex].StartSkillHit();
    }

    private void StopSkillHit(int weaponIndex)
    {
        skillOwner.StopSkillHit(weaponIndex);
        weapons[weaponIndex].StopSkillHit();
    }

    private void SkillCanSwitch()
    {
        skillOwner.SkillCanSwitch();
    }

    #endregion
}
