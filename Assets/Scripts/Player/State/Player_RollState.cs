using UnityEngine;

public class Player_RollState : PlayerStateBase
{
    private const float RollDistanceMultiplier = 1.4f; // 翻滚水平位移倍率
    private const float RollPlaybackSpeed = 0.75f; // 翻滚动画播放速度
    private const float RollExitNormalizedTime = 0.3f; // 可退出翻滚的动画进度
    private string currentRollAnimation;//当前动画名称
    private bool isAirRoll; // 本次翻滚是否从空中开始

    /// <summary>
    /// 进入翻滚状态，播放动画并接管根运动位移。
    /// </summary>
    public override void Enter()
    {
        isAirRoll = !player.CharacterController.isGrounded;

        float horizontal = Input.GetAxisRaw("Horizontal");
        float vertical = Input.GetAxisRaw("Vertical");
        bool hasMoveInput = horizontal != 0f || vertical != 0f;//是否移动

        currentRollAnimation = hasMoveInput ? "Roll" : "RollBack";//根据是否移动选择动画

        player.Model.Animator.speed = RollPlaybackSpeed;
        player.PlayerAnimation(currentRollAnimation, 0.08f);
        player.Model.SetRootMotionAction(OnRootMotion);
    }

    /// <summary>
    /// 检测翻滚动画进度，并根据移动输入切换到移动或待机状态。
    /// </summary>
    public override void Update()
    {
        if (CheckAnimationName(currentRollAnimation, out float animationTime))
        {
            if (animationTime >= RollExitNormalizedTime)
            {
                // 空中翻滚结束后继续回到下落状态
                if (isAirRoll)
                {
                    player.ChangeState(PlayerState.AirDown);
                    return;
                }

                // 翻滚结束时保留玩家当前的移动意图
                float horizontal = Input.GetAxisRaw("Horizontal");
                float vertical = Input.GetAxisRaw("Vertical");
                bool hasMoveInput = horizontal != 0f || vertical != 0f;//是否移动

                // 向前翻滚结束并且继续按住 W，则进入 Sprint
                if (currentRollAnimation == "Roll" && vertical > 0f)
                {
                    player.ChangeState(PlayerState.Sprint);
                }
                else
                {
                    player.ChangeState(hasMoveInput
                        ? PlayerState.Move
                        : PlayerState.Idle);
                }
            }
        }
    }

    /// <summary>
    /// 退出翻滚状态，恢复动画速度并释放根运动回调。
    /// </summary>
    public override void Exit()
    {
        player.Model.Animator.speed = 1f;
        player.Model.ClearRootMotionAction();
    }

    /// <summary>
    /// 将翻滚动画产生的根运动应用到角色控制器。
    /// </summary>
    /// <param name="deltaPostion">当前帧动画产生的位移增量。</param>
    /// <param name="deltaRotation">当前帧动画产生的旋转增量。</param>
    private void OnRootMotion(Vector3 deltaPostion, Quaternion deltaRotation)
    {
        // 放大水平位移，并使用游戏重力覆盖动画的垂直位移
        deltaPostion.x *= RollDistanceMultiplier;
        deltaPostion.z *= RollDistanceMultiplier;
        deltaPostion.y = player.gravity * Time.deltaTime;
        player.CharacterController.Move(deltaPostion);
    }
}
