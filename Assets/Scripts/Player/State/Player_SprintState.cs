using UnityEngine;

public class Player_SprintState : PlayerStateBase
{
    private const float SprintJumpMovePower = 2.5f; // 冲刺跳跃的前进惯性
    private const float SprintStopDistanceMultiplier = 1.5f; // 冲刺急停距离倍率

    private enum SprintChildState
    {
        Sprint,
        Stop
    }

    private SprintChildState sprintState;

    private SprintChildState SprintState
    {
        get => sprintState;
        set
        {
            sprintState = value;

            switch (sprintState)
            {
                case SprintChildState.Sprint:
                    player.PlayerAnimation("Sprint", 0.12f);
                    player.Model.SetRootMotionAction(OnRootMotion);
                    break;
                case SprintChildState.Stop:
                    player.PlayerAnimation("RunStop", 0.1f);
                    break;
            }
        }
    }

    /// <summary>
    /// 进入冲刺跑状态。
    /// </summary>
    public override void Enter()
    {
        SprintState = SprintChildState.Sprint;
    }

    /// <summary>
    /// 检测移动输入以及状态切换。
    /// </summary>
    public override void Update()
    {
        //检测攻击
        if (Input.GetMouseButtonDown(0))
        {
            player.ChangeState(PlayerState.Attack);
            return;
        }

        // 冲刺过程中允许继续使用右键闪避
        if (Input.GetKeyDown(KeyCode.LeftShift) || Input.GetMouseButtonDown(1))
        {
            player.ChangeState(PlayerState.Roll);
            return;
        }

        // 冲刺时保留更强的前进惯性进入跳跃
        if (Input.GetKeyDown(KeyCode.Space))
        {
            MoveStatePower = SprintJumpMovePower;
            ResumeSprintAfterLanding = true;
            player.ChangeState(PlayerState.Jump);
            return;
        }

        if (!player.CharacterController.isGrounded)
        {
            player.ChangeState(PlayerState.AirDown);
            return;
        }

        switch (sprintState)
        {
            case SprintChildState.Sprint:
                SprintOnUpdate();
                break;
            case SprintChildState.Stop:
                StopOnUpdate();
                break;
        }
    }

    /// <summary>
    /// 处理持续冲刺期间的输入、转向和急停触发。
    /// </summary>
    private void SprintOnUpdate()
    {
        float horizontal = Input.GetAxisRaw("Horizontal");
        float vertical = Input.GetAxisRaw("Vertical");

        // 松开全部方向键时播放急停，改按其他方向时回到普通移动
        if (vertical <= 0f)
        {
            bool hasMoveInput = horizontal != 0f || vertical != 0f;

            if (hasMoveInput)
            {
                player.ChangeState(PlayerState.Move);
            }
            else
            {
                SprintState = SprintChildState.Stop;
            }

            return;
        }

        // 根据相机朝向调整 Sprint 方向
        Vector3 input = new Vector3(horizontal, 0f, vertical);
        float cameraY = Camera.main.transform.rotation.eulerAngles.y;
        Vector3 targetDirection =
            Quaternion.Euler(0f, cameraY, 0f) * input;

        if (targetDirection.sqrMagnitude > 0.01f)
        {
            Quaternion targetRotation =
                Quaternion.LookRotation(targetDirection);

            player.Model.transform.rotation = Quaternion.Slerp(
                player.Model.transform.rotation,
                targetRotation,
                Time.deltaTime * player.roteteSpeed);
        }
    }

    /// <summary>
    /// 等待急停动画结束，并允许玩家提前恢复移动。
    /// </summary>
    private void StopOnUpdate()
    {
        float horizontal = Input.GetAxisRaw("Horizontal");
        float vertical = Input.GetAxisRaw("Vertical");

        if (horizontal != 0f || vertical != 0f)
        {
            player.ChangeState(PlayerState.Move);
            return;
        }

        if (CheckAnimationName("RunStop", out float animationTime) && animationTime >= 1f)
        {
            player.ChangeState(PlayerState.Idle);
        }
    }

    /// <summary>
    /// 退出冲刺跑状态。
    /// </summary>
    public override void Exit()
    {
        player.Model.ClearRootMotionAction();
    }

    /// <summary>
    /// 应用 Sprint 动画产生的根运动。
    /// </summary>
    private void OnRootMotion(
        Vector3 deltaPosition,
        Quaternion deltaRotation)
    {
        // 仅放大急停动画的水平根运动，不影响正常冲刺距离
        if (sprintState == SprintChildState.Stop)
        {
            deltaPosition.x *= SprintStopDistanceMultiplier;
            deltaPosition.z *= SprintStopDistanceMultiplier;
        }

        deltaPosition.y = player.gravity * Time.deltaTime;
        player.CharacterController.Move(deltaPosition);
    }
}
