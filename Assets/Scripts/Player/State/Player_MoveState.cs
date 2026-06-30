using UnityEngine;

public class Player_MoveState : PlayerStateBase
{
    private enum MoveChildState
    {
        Move,
        Stop
    }

    private float Walk2runTransition;//0~1
    private MoveChildState moveState;

    private MoveChildState MoveState
    {
        get => moveState;
        set
        {
            moveState = value;
            //状态进入
            switch (moveState)
            {
                case MoveChildState.Move:
                    //播放角色待机动画
                    player.PlayerAnimation("Move");
                    break;
                case MoveChildState.Stop:
                    player.PlayerAnimation("RunStop");
                    break;
            }
        }
    }

    public override void Enter()
    {
        MoveState = MoveChildState.Move;
        //传入根节点与旋转值
        player.Model.SetRootMotionAction(OnRootMotion);
    }

    public override void Update()
    {
        //ToDo：检测攻击
        if (Input.GetMouseButtonDown(0))
        {
            player.ChangeState(PlayerState.Attack);
            return;
        }

        //ToDo：检测跳跃
        if (Input.GetKeyDown(KeyCode.Space))
        {
            //切换到移动状态
            MoveStatePower = Walk2runTransition + 1;
            player.ChangeState(PlayerState.Jump);
            return;
        }

        //检测翻滚
        if (Input.GetKeyDown(KeyCode.LeftShift) || Input.GetMouseButtonDown(1))
        {
            MoveStatePower = Walk2runTransition + 1;
            player.ChangeState(PlayerState.Roll);
            return;
        }

        //检测下落
        if (player.CharacterController.isGrounded == false)
        {
            player.ChangeState(PlayerState.AirDown);
            return;
        }

        switch (moveState)
        {
            case MoveChildState.Move:
                MoveOnUpdate();
                break;
            case MoveChildState.Stop:
                StopOnUpdate();
                break;
        }
    }

    private void MoveOnUpdate()
    {
        //检测玩家移动，玩家不输入就切回待机
        float h = Input.GetAxis("Horizontal");
        float v = Input.GetAxis("Vertical");

        float rawh = Input.GetAxisRaw("Horizontal");
        float rawv = Input.GetAxisRaw("Vertical");

        if (rawh == 0f && rawv == 0f)
        {
            if (Walk2runTransition > 0.4f)
            {
                //进入急停
                MoveState = MoveChildState.Stop;
                return;
            }
            else if (h == 0 && v == 0)
            {
                player.ChangeState(PlayerState.Idle);
                return;
            }
        }
        else
        {
            //处理走到跑的过渡
            if (Input.GetKeyDown(KeyCode.LeftControl))
            {
                player.isRunMode = !player.isRunMode;
            }
            float targetMoveValue = player.isRunMode ? 1f : 0f;
            Walk2runTransition = Mathf.MoveTowards(Walk2runTransition, targetMoveValue, Time.deltaTime * player.walk2RunTransition);

            player.Model.Animator.SetFloat("Move", Walk2runTransition);
            //通过修改动画的播放速度来达到实际的位移变化
            player.Model.Animator.speed = Mathf.Lerp(player.walkSpeed, player.runSpeed, Walk2runTransition);

            if (h != 0 || v != 0)
            {
                //处理旋转的控制
                Vector3 input = new Vector3(h, 0, v);
                //获取相机的旋转值y
                float y = Camera.main.transform.rotation.eulerAngles.y;
                // 让四元数与向量相乘，表示这个向量按照四元数所表达的角度进行旋转后得到新的向量
                Vector3 targetDir = Quaternion.Euler(0, y, 0) * input;
                player.Model.transform.rotation = Quaternion.Slerp(player.Model.transform.rotation, Quaternion.LookRotation(targetDir), Time.deltaTime * player.roteteSpeed);
            }
        }
    }

    private void StopOnUpdate()
    {
        //检测当期玩家的进度，如果播放完毕了，则切换到待机
        if (CheckAnimationName("RunStop", out float animationTime))
        {
            if (animationTime >= 1)
            {
                player.ChangeState(PlayerState.Idle);
            }
        }
    }

    public override void Exit()
    {
        Walk2runTransition = 0f;
        player.Model.ClearRootMotionAction();
        player.Model.Animator.speed = 1;
    }

    private void OnRootMotion(Vector3 deltaPostion, Quaternion deltaRotation)
    {
        deltaPostion.y = player.gravity * Time.deltaTime;
        player.CharacterController.Move(deltaPostion);
    }
}
