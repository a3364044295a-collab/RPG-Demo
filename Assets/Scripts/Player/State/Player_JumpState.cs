using UnityEngine;

public class Player_JumpState : PlayerStateBase
{
    public override void Enter()
    {
        player.PlayerAnimation("JumpStart");
        //注册根运动
        player.Model.SetRootMotionAction(OnRootMotion);
    }

    public override void Exit()
    {
        player.Model.ClearRootMotionAction();
    }

    public override void Update()
    {
        //if (CheckAnimationName("JumpStart", out float animationTime) && animationTime >= 0.9f)
        //{
        //    player.ChangeState(PlayerState.Idle);
        //}


        //第一次执行Update时，也许当前动画还不是Jump
        //确定当前是Jump动画
        AnimatorStateInfo stateInfo = player.Model.Animator.GetCurrentAnimatorStateInfo(0);
        if (player.Model.Animator.GetCurrentAnimatorStateInfo(0).IsName("JumpStart"))
        {
            //获取动画的进度
            float animationProgress = stateInfo.normalizedTime;
            //只允许在0.1~0.6的播放速度下进行位移旋转
            if (animationProgress > 0.1f && animationProgress < 0.6f)
            {
                // 根据输入判断水平移动方向


                //ToDo：攻击检测
            }
            else if (animationProgress >= 0.9f)
            {
                player.ChangeState(PlayerState.AirDown);
            }
        }
    }

    private void OnRootMotion(Vector3 deltaPostion, Quaternion deltaRotation)
    {
        deltaPostion.y *= player.jumpPower;
        Vector3 offest = MoveStatePower * Time.deltaTime * player.moveSpeedForJump * player.Model.transform.forward;
        player.CharacterController.Move(deltaPostion + offest);
    }
}
