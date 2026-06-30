using UnityEngine;

public class Player_IdleState : PlayerStateBase
{

    public override void Enter()
    {
        //播放角色待机动画
        player.PlayerAnimation("Idle", 0.12f);
    }

    public override void Update()
    {
        //ToDo：检测攻击
        if (Input.GetMouseButtonDown(0))
        {
            player.ChangeState(PlayerState.Attack);
            return;
        }

        //检测跳跃
        if (Input.GetKeyDown(KeyCode.Space))
        {
            //切换到移动状态
            MoveStatePower = 0;
            player.ChangeState(PlayerState.Jump);
            return;
        }

        //检测翻滚
        if (Input.GetKeyDown(KeyCode.LeftShift)||Input.GetMouseButtonDown(1))
        {
            MoveStatePower = 0;
            player.ChangeState(PlayerState.Roll);
            return;
        }

        //检测玩家移动
        player.CharacterController.Move(new Vector3(0, player.gravity * Time.deltaTime, 0));
        //检测下落
        if (player.CharacterController.isGrounded == false)
        {
            player.ChangeState(PlayerState.AirDown);
            return;
        }

        float h = Input.GetAxis("Horizontal");
        float v = Input.GetAxis("Vertical");

        if (h != 0f || v != 0f)
        {
            //切换到移动状态
            player.ChangeState(PlayerState.Move);
        }
    }
}
