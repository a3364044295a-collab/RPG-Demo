using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player_Controller : MonoBehaviour, IStateMachineOwner, ISkillOwner
{
    [SerializeField] private Player_Model player_Model;//模型脚本
    [SerializeField] private CharacterController charactercontroller;//控制器组件
    public CharacterController CharacterController { get => charactercontroller; }//控制器的属性
    public Player_Model Model { get => player_Model; }//模型脚本的属性
    private string _currentAnimName; // 记录当前播放的动画名称
    [SerializeField] private AudioSource audioSource;
    private StateMachine stateMachine;//状态机脚本

    #region 配置类的信息
    [Header("配置")]
    public float gravity = -9.8f;//重力
    public float roteteSpeed = 5;//角色旋转速度
    public float walk2RunTransition = 2;//走跑切换速度
    public bool isRunMode = false;//是否处于奔跑模式
    public float walkSpeed = 1;//走路动画播放速度
    public float runSpeed = 1;//跑步动画播放速度
    public float jumpPower = 1;//跳跃力度
    public float moveSpeedForJump = 1;//跳跃时移动的速度
    public float moveSpeedForAirDown = 1;//跳跃时下降时移动的速度
    public AudioClip[] footStepAudioClips;
    public List<string> enemyTagList;

    public SkillConfig[] standAttackConfig;
    #endregion

    private void Start()
    {
        Model.Init(this, enemyTagList);//初始化脚步声事件

        stateMachine = new StateMachine();//实例化状态机脚本
        stateMachine.Init(this);//状态机脚本初始化
        ChangeState(PlayerState.Idle);//初始切换为待机状态
    }

    /// <summary>
    /// 切换状态的方法
    /// </summary>
    /// <param name="playerState"></param>
    public void ChangeState(PlayerState playerState)
    {
        switch (playerState)
        {
            case PlayerState.Idle:
                stateMachine.ChangeState<Player_IdleState>();
                break;
            case PlayerState.Move:
                stateMachine.ChangeState<Player_MoveState>();
                break;
            case PlayerState.Jump:
                stateMachine.ChangeState<Player_JumpState>();
                break;
            case PlayerState.AirDown:
                stateMachine.ChangeState<Player_AirDownState>();
                break;
            case PlayerState.Roll:
                stateMachine.ChangeState<Player_RollState>();
                break;
            case PlayerState.Sprint:
                stateMachine.ChangeState<Player_SprintState>();
                break;
            case PlayerState.Attack:
                stateMachine.ChangeState<Player_AttackState>();
                break;
        }
    }
    #region 技能相关
    private SkillConfig currentSkillconfig;
    private int currentHitIndex = 0;

    public void StartAttack(SkillConfig skillConfig)
    {
        currentSkillconfig = skillConfig;
        currentHitIndex = 0;
        //播放动画
        PlayerAnimation(currentSkillconfig.AnimationName);
        //技能释放音效
        PlayerAudio(currentSkillconfig.ReleaseData.AudioClip);
        //技能释放物体
        SpawnSkillObject(skillConfig.ReleaseData.SpawnObj);
    }

    public void StartSkillHit(int weaponIndex)
    {
        //技能释放音效
        PlayerAudio(currentSkillconfig.AttackData[currentHitIndex].AudioClip);
        //技能释放物体
        SpawnSkillObject(currentSkillconfig.AttackData[currentHitIndex].SpawnObj);
    }

    public void StopSkillHit(int weaponIndex)
    {
        currentHitIndex += 1;
    }

    public void SkillCanSwitch()
    {
    }
    #endregion

    public void SpawnSkillObject(Skill_SpawnObj spawnObj)
    {
        if (spawnObj != null && spawnObj.Prefab != null)
        {
            StartCoroutine(DoSpawnObject(spawnObj));
        }
    }

    private IEnumerator DoSpawnObject(Skill_SpawnObj spawnObj)
    {
        //延迟时间
        yield return new WaitForSeconds(spawnObj.Time);
        GameObject skillObj = GameObject.Instantiate(spawnObj.Prefab, null);
        //一般特效的生成是相对于主角的
        skillObj.transform.position = Model.transform.position + spawnObj.Position;
        skillObj.transform.eulerAngles = Model.transform.eulerAngles + spawnObj.Rotation;
        PlayerAudio(spawnObj.AudioClip);
    }

    /// <summary>
    /// 有过渡的进入下一个动画
    /// </summary>
    /// <param name="animationName"></param>
    /// <param name="fixTransitionDuration"></param>
    public void PlayerAnimation(string animationName, float fixTransitionDuration = 0.25f)
    {
        // 如果要播放的动画和当前正在播放的一样，直接返回，避免重复调用
        if (animationName == _currentAnimName) return;

        Model.Animator.CrossFadeInFixedTime(animationName, fixTransitionDuration);
        _currentAnimName = animationName;
    }

    public void OnFootStep()
    {
        audioSource.PlayOneShot(footStepAudioClips[Random.Range(0, footStepAudioClips.Length)]);
    }

    public void PlayerAudio(AudioClip audioClip)
    {
        if (audioClip != null)
        {
            audioSource.PlayOneShot(audioClip);
        }
    }

    public void OnHit(IHurt target, Vector3 hitPositoin)
    {
        Debug.Log("我攻击到了" + ((Component)target).gameObject.name);
    }
}
