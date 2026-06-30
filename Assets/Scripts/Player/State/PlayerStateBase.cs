using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

public class PlayerStateBase : StateBase
{
    protected Player_Controller player;
    protected static float MoveStatePower;
    protected static bool ResumeSprintAfterLanding;
    protected static bool ResumeAirDownAfterRoll;
    public override void Init(IStateMachineOwner owner)
    {
        base.Init(owner);
        player = (Player_Controller)owner;
    }

    protected virtual bool CheckAnimationName(string stateName, out float time)
    {
        AnimatorStateInfo nextInfo = player.Model.Animator.GetNextAnimatorStateInfo(0);

        if (nextInfo.IsName(stateName))
        {
            time = nextInfo.normalizedTime;
            return true;
        }

        AnimatorStateInfo currentInfo = player.Model.Animator.GetCurrentAnimatorStateInfo(0);
        time = currentInfo.normalizedTime;
        return currentInfo.IsName(stateName);
    }
}
