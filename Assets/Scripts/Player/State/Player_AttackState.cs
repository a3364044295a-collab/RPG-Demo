using UnityEngine;

public class Player_AttackState : PlayerStateBase
{
    //当前普攻为第几段
    private int currentAttackIndex;

    public int CurrentAttackIndex
    {
        get => currentAttackIndex;
        set
        {
            if (value > player.standAttackConfig.Length - 1)
            {
                currentAttackIndex = 0;
            }
            else
                currentAttackIndex = value;
        }
    }

    public override void Enter()
    {
        currentAttackIndex = 0;
        //注册根运动
        player.Model.SetRootMotionAction(OnRootMotion);
        //播放攻击动画
        StandAttack();
    }

    public override void Exit()
    {
        player.OnSkillOver();
    }

    private void StandAttack()
    {
        //实现连续普攻
        player.StartAttack(player.standAttackConfig[currentAttackIndex]);
    }

    public override void Update()
    {
        //待机检测
        if (CheckAnimationName(player.standAttackConfig[currentAttackIndex].AnimationName, out float animationTime) && animationTime > 0.9f)
        {
            //回到待机
            player.ChangeState(PlayerState.Idle);
        }

        //攻击检测
        if (CheckStandAttack())
        {
            CurrentAttackIndex = currentAttackIndex + 1;
            //播放攻击动画
            StandAttack();
        }
    }

    private bool CheckStandAttack()
    {
        return Input.GetMouseButtonDown(0) && player.CanSwitchSkill;
    }

    private void OnRootMotion(Vector3 deltaPostion, Quaternion deltaRotation)
    {
        deltaPostion.y = player.gravity * Time.deltaTime;
        player.CharacterController.Move(deltaPostion);
    }
}
