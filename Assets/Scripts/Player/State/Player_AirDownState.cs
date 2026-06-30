using UnityEngine;

public class Player_AirDownState : PlayerStateBase
{
    // JumpEnd 落地翻滚期间的向前移动速度
    private const float JumpEndForwardSpeed = 6f;

    // 下落状态内部包含空中循环和落地两个阶段
    private enum AirDownChildState
    {
        // 角色仍在空中持续下落
        Loop,
        // 角色接近地面并播放落地动画
        End
    }

    // 超过这个高度，才考虑播放落地动画
    private float playEndAnimationHeight = 2f;

    // 距离地面达到这个高度时，开始播放 JumpEnd
    private float endAnimationHeight = 1.8f;

    // 射线只检测 Environment 层
    private LayerMask groundLayerMask = LayerMask.GetMask("Environment");

    // 本次下落是否需要播放落地动画
    private bool needEndAnimation;

    // 当前竖直方向的下落速度
    private float verticalVelocity;

    // 当前所处的下落子状态
    private AirDownChildState airDownState;

    /// <summary>
    /// 获取或切换下落子状态，并播放对应的动画。
    /// </summary>
    private AirDownChildState AirDownState
    {
        get => airDownState;
        set
        {
            // 保存新的子状态
            airDownState = value;

            // 根据子状态播放对应动画
            switch (airDownState)
            {
                case AirDownChildState.Loop:
                    player.PlayerAnimation("JumpLoop");
                    break;

                case AirDownChildState.End:
                    player.PlayerAnimation("JumpEnd");
                    break;
            }
        }
    }

    /// <summary>
    /// 进入下落状态时初始化速度、动画和落地动画判断。
    /// </summary>
    public override void Enter()
    {
        // 从空中翻滚返回时延续下落速度，否则重新计算下落
        if (ResumeAirDownAfterRoll)
        {
            ResumeAirDownAfterRoll = false;
        }
        else
        {
            verticalVelocity = 0f;
        }

        // 默认先进入空中循环下落阶段
        AirDownState = AirDownChildState.Loop;

        // 如果较长的射线检测不到地面，说明下落高度较高，
        // 接近地面时需要播放 JumpEnd。
        needEndAnimation = !CheckGround(playEndAnimationHeight);
    }

    /// <summary>
    /// 每帧处理落地检测，并执行当前下落子状态的逻辑。
    /// </summary>
    public override void Update()
    {
        // 高空下落阶段允许右键翻滚，并在结束后继续下落
        if (airDownState == AirDownChildState.Loop
            && Input.GetMouseButtonDown(1))
        {
            ResumeAirDownAfterRoll = true;
            player.ChangeState(PlayerState.Roll);
            return;
        }

        // 无论当前处于 Loop 还是 End，都先判断是否已经落地。
        if (player.CharacterController.isGrounded)
        {
            // End 动画需要播放到一定进度后再退出。
            if (airDownState == AirDownChildState.End)
            {
                // 接触地面后仍要继续应用落地翻滚的向前位移
                ApplyJumpEndMotion();

                if (CheckAnimationName("JumpEnd", out float animationTime)
                    && animationTime >= 0.8f)
                {
                    ChangeToGroundedState();
                }
            }
            else
            {
                ChangeToGroundedState();
            }

            return;
        }

        // 角色尚未落地时，根据当前子状态执行对应逻辑
        switch (airDownState)
        {
            case AirDownChildState.Loop:
                LoopOnUpdate();
                break;

            case AirDownChildState.End:
                EndOnUpdate();
                break;
        }
    }

    /// <summary>
    /// 处理空中循环下落阶段，并在接近地面时切换到落地阶段。
    /// </summary>
    private void LoopOnUpdate()
    {
        // 高空下落时，接近地面后播放 JumpEnd。
        if (needEndAnimation && CheckGround(endAnimationHeight))
        {
            AirDownState = AirDownChildState.End;
            player.OnFootStep();
            // 切换动画的这一帧也要继续下落。
            AirControl();
            return;
        }

        AirControl();
    }

    /// <summary>
    /// 处理落地动画阶段，并根据动画进度和落地情况决定后续状态。
    /// </summary>
    private void EndOnUpdate()
    {
        // JumpEnd 播放期间持续向角色面朝方向移动
        ApplyJumpEndMotion();

        if (!CheckAnimationName("JumpEnd", out float animationTime))
        {
            return;
        }

        if (animationTime >= 0.8f)
        {
            if (player.CharacterController.isGrounded)
            {
                ChangeToGroundedState();
            }
            else
            {
                // JumpEnd 播放过早但仍未落地，回到 Loop。
                // 同时禁止再次立即进入 End，避免 Loop/End 反复切换。
                needEndAnimation = false;
                AirDownState = AirDownChildState.Loop;
            }
        }
    }

    /// <summary>
    /// 在 JumpEnd 落地翻滚期间施加向前位移和基础重力。
    /// </summary>
    private void ApplyJumpEndMotion()
    {
        // 根据 JumpEnd 进度让速度从快到慢平滑衰减
        float normalizedTime = 0f;
        if (CheckAnimationName("JumpEnd", out float animationTime))
        {
            normalizedTime = Mathf.Clamp01(animationTime / 0.8f);
        }

        float speedFactor =
            1f - Mathf.SmoothStep(0f, 1f, normalizedTime);

        Vector3 motion =
            player.Model.transform.forward *
            JumpEndForwardSpeed *
            speedFactor *
            Time.deltaTime;

        motion.y = player.gravity * Time.deltaTime;
        player.CharacterController.Move(motion);
    }

    /// <summary>
    /// 处理空中的重力、水平移动和角色转向。
    /// </summary>
    private void AirControl()
    {
        // 获取水平和垂直方向的输入
        float h = Input.GetAxis("Horizontal");
        float v = Input.GetAxis("Vertical");

        // 让下落速度随时间增加，而不是保持固定速度。
        verticalVelocity += player.gravity * Time.deltaTime;

        Vector3 motion = new Vector3(
            0f,
            verticalVelocity * Time.deltaTime,
            0f
        );

        // 限制输入向量长度，避免斜向移动速度更快
        Vector3 input = new Vector3(h, 0f, v);
        input = Vector3.ClampMagnitude(input, 1f);

        // 有方向输入时，处理空中水平移动和转向
        if (input.sqrMagnitude > 0.001f)
        {
            // 把输入方向转换成以相机朝向为基准的世界方向
            float cameraY = Camera.main.transform.rotation.eulerAngles.y;
            Vector3 targetDir =
                Quaternion.Euler(0f, cameraY, 0f) * input;

            // 计算水平方向的空中位移
            motion.x =
                targetDir.x *
                player.moveSpeedForAirDown *
                Time.deltaTime;

            motion.z =
                targetDir.z *
                player.moveSpeedForAirDown *
                Time.deltaTime;

            // 让模型平滑转向当前移动方向
            player.Model.transform.rotation = Quaternion.Slerp(
                player.Model.transform.rotation,
                Quaternion.LookRotation(targetDir),
                Time.deltaTime * player.roteteSpeed
            );
        }

        // 通过 CharacterController 应用这一帧的最终位移
        player.CharacterController.Move(motion);
    }

    /// <summary>
    /// 根据起跳前的状态决定落地后返回 Sprint 还是 Idle。
    /// </summary>
    private void ChangeToGroundedState()
    {
        if (ResumeSprintAfterLanding)
        {
            ResumeSprintAfterLanding = false;
            player.ChangeState(PlayerState.Sprint);
            return;
        }

        player.ChangeState(PlayerState.Idle);
    }

    /// <summary>
    /// 向角色下方发射射线，检查指定高度范围内是否存在地面。
    /// </summary>
    /// <param name="height">需要检测的地面高度范围。</param>
    /// <returns>检测到 Environment 层地面时返回 true，否则返回 false。</returns>
    private bool CheckGround(float height)
    {
        // 从角色位置上方 0.5 米处开始发射射线
        Vector3 origin =
            player.transform.position + new Vector3(0f, 0.5f, 0f);

        // 补偿射线起点向上偏移的 0.5 米
        float distance = height + 0.5f;

        // 沿角色下方向检测 Environment 层
        return Physics.Raycast(
            origin,
            -player.transform.up,
            distance,
            groundLayerMask
        );
    }
}
