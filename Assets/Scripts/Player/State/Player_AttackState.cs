using UnityEngine;

public class Player_AttackState : PlayerStateBase
{
    public override void Enter()
    {
        //注册根运动
        player.Model.SetRootMotionAction(OnRootMotion);
        //播放攻击动画
        StandAttack();
    }

    private void StandAttack()
    {
        //实现连续普攻
        player.StartAttack(player.standAttackConfig[0]);
    }

    public override void Update()
    {
        if (CheckAnimationName(player.standAttackConfig[0].AnimationName, out float animationTime) && animationTime > 0.9f)
        {
            //回到待机
            player.ChangeState(PlayerState.Idle);
        }
    }

    private void OnRootMotion(Vector3 deltaPostion, Quaternion deltaRotation)
    {
        deltaPostion.y = player.gravity * Time.deltaTime;
        player.CharacterController.Move(deltaPostion);
    }
}
