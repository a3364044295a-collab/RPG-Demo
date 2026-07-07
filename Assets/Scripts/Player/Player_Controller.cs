using Cinemachine;
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
    [SerializeField] private CinemachineImpulseSource impulseSource;//振动源
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

    public float TestValue;
    private void Update()
    {

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
    private bool canSwitchSkill;
    public bool CanSwitchSkill { get => canSwitchSkill; set => canSwitchSkill = value; }

    private List<IHurt> currentHitEnemies = new List<IHurt>();

    public void StartAttack(SkillConfig skillConfig)
    {
        CanSwitchSkill = false;//防止立即切换技能
        currentSkillconfig = skillConfig;
        currentHitIndex = 0;
        //播放动画
        PlayerAnimation(currentSkillconfig.AnimationName);
        //技能释放音效
        PlayerAudio(currentSkillconfig.ReleaseData.AudioClip);
        //技能释放物体
        SpawnSkillObject(skillConfig.ReleaseData.SpawnObj);
    }

    public void StartSkillHit(int attackDataIndex)
    {
        if (currentSkillconfig == null || currentSkillconfig.AttackData == null) return;
        if (attackDataIndex < 0 || attackDataIndex >= currentSkillconfig.AttackData.Length) return;

        currentHitIndex = attackDataIndex;
        currentHitEnemies.Clear();

        SkillAttackData attackData = currentSkillconfig.AttackData[attackDataIndex];
        //技能释放音效
        PlayerAudio(attackData.AudioClip);
        //技能释放物体
        SpawnSkillObjects(attackData.SpawnObj);
        CheckFanHit(attackData);
    }

    public void StopSkillHit(int weaponIndex)
    {

    }

    public void SkillCanSwitch()
    {
        CanSwitchSkill = true;
    }

    public void OnSkillOver()
    {
        CanSwitchSkill = true;
    }
    #endregion

    private void CheckFanHit(SkillAttackData attackData)
    {
        Vector3 center = Model.transform.TransformPoint(attackData.AttackOffset);

        Collider[] colliders = Physics.OverlapSphere(center, attackData.AttackRadius);

        foreach (Collider other in colliders)
        {
            if (!enemyTagList.Contains(other.tag)) continue;

            IHurt enemy = other.GetComponentInParent<IHurt>();
            if (enemy == null) continue;

            Vector3 dir = other.transform.position - center;
            dir.y = 0;

            if (dir.sqrMagnitude <= 0.001f) continue;

            float angle = Vector3.Angle(Model.transform.forward, dir.normalized);

            if (angle <= attackData.AttackAngle * 0.5f)
            {
                if (currentHitEnemies.Contains(enemy)) continue;

                currentHitEnemies.Add(enemy);
                Vector3 hitPoint = other.ClosestPoint(center);
                OnHit(enemy, hitPoint);
            }
        }
    }

    public void ScreenImpulse(float value)
    {
        impulseSource.GenerateImpulse(value * 2);
    }

    /// <summary>
    /// 生成单个物体
    /// </summary>
    /// <param name="spawnObj"></param>
    public void SpawnSkillObject(Skill_SpawnObj spawnObj)
    {
        if (spawnObj != null && spawnObj.Prefab != null)
        {
            StartCoroutine(DoSpawnObject(spawnObj));
        }
    }

    /// <summary>
    /// 生成所有物体
    /// </summary>
    /// <param name="spawnObjs"></param>
    public void SpawnSkillObjects(Skill_SpawnObj[] spawnObjs)
    {
        if (spawnObjs == null) return;

        foreach (Skill_SpawnObj spawnObj in spawnObjs)
        {
            SpawnSkillObject(spawnObj);
        }
    }

    private IEnumerator DoSpawnObject(Skill_SpawnObj spawnObj)
    {
        //延迟时间
        yield return new WaitForSeconds(spawnObj.Time);

        Transform spawnRoot = GetSpawnRoot(spawnObj);
        GameObject skillObj = GameObject.Instantiate(spawnObj.Prefab, player_Model.transform);
        //一般特效的生成是相对于主角或挂点的
        skillObj.transform.position = spawnRoot.TransformPoint(spawnObj.Position);
        skillObj.transform.rotation = spawnRoot.rotation * Quaternion.Euler(spawnObj.Rotation);
        skillObj.transform.localScale = GetSpawnScale(spawnObj);
        SkipParticleTime(skillObj, spawnObj.SkipTime);
        PlayerAudio(spawnObj.AudioClip);
    }

    private Transform GetSpawnRoot(Skill_SpawnObj spawnObj)
    {
        if (spawnObj == null || string.IsNullOrEmpty(spawnObj.AttachPointName))
        {
            return Model.transform;
        }

        Transform attachPoint = FindChildByName(Model.transform, spawnObj.AttachPointName);
        return attachPoint != null ? attachPoint : Model.transform;
    }

    private Transform FindChildByName(Transform root, string childName)
    {
        if (root.name == childName) return root;

        for (int i = 0; i < root.childCount; i++)
        {
            Transform found = FindChildByName(root.GetChild(i), childName);
            if (found != null) return found;
        }

        return null;
    }

    /// <summary>
    /// 如果缩放为0就默认变为1
    /// </summary>
    /// <param name="spawnObj"></param>
    /// <returns></returns>
    private Vector3 GetSpawnScale(Skill_SpawnObj spawnObj)
    {
        return spawnObj.Scale == Vector3.zero ? Vector3.one : spawnObj.Scale;
    }

    private void SkipParticleTime(GameObject effectObj, float skipTime)
    {
        if (skipTime <= 0) return;

        ParticleSystem[] particleSystems = effectObj.GetComponentsInChildren<ParticleSystem>();
        foreach (ParticleSystem particleSystem in particleSystems)
        {
            particleSystem.Simulate(skipTime, true, true);
            particleSystem.Play(true);
        }
    }

    public void OnHit(IHurt target, Vector3 hitPositoin)
    {
        //拿到该段攻击的数据
        SkillAttackData attackData = currentSkillconfig.AttackData[currentHitIndex];
        //生成基于命中配置的效果
        StartCoroutine(DoSkillHitEF(attackData.SkillHitEFConfig, hitPositoin));
        //播放效果类
        if (attackData.ScreenImpulseValue != 0) ScreenImpulse(attackData.ScreenImpulseValue);//震动效果
        if (attackData.ChromaticAberrationValue != 0) PostProcessManager.Instance.ChromaticAberrationEF(attackData.ChromaticAberrationValue);//色散效果

        StartFreezeFrame(attackData.FreezeFrameTime, attackData.ScaleTime);
        //ToDo:传递伤害数据
    }

    private void StartFreezeFrame(float time, float timeScale)
    {
        if (time > 0)
            StartCoroutine(HitStop(time, timeScale));
    }

    private IEnumerator HitStop(float time, float timeScale)
    {
        Time.timeScale = timeScale;
        yield return new WaitForSecondsRealtime(time);//这里要用真实时间，不然会受到时间缩放的影响
        Time.timeScale = 1f;
    }

    private IEnumerator DoSkillHitEF(SkillHitEFConfig hitEFConfig, Vector3 spawnPoint)
    {
        if (hitEFConfig == null) yield break;

        PlayerAudio(hitEFConfig.AudioClip);
        if (hitEFConfig.SpawnObj == null) yield break;

        foreach (Skill_SpawnObj spawnObj in hitEFConfig.SpawnObj)
        {
            StartCoroutine(DoSkillHitSpawnObj(spawnObj, spawnPoint));
        }
    }

    private IEnumerator DoSkillHitSpawnObj(Skill_SpawnObj spawnObj, Vector3 spawnPoint)
    {
        if (spawnObj == null || spawnObj.Prefab == null) yield break;

        yield return new WaitForSeconds(spawnObj.Time);

        GameObject go = Instantiate(spawnObj.Prefab);
        go.transform.position = spawnPoint + spawnObj.Position;
        go.transform.LookAt(Camera.main.transform);
        go.transform.eulerAngles += spawnObj.Rotation;
        go.transform.localScale = GetSpawnScale(spawnObj);

        SkipParticleTime(go, spawnObj.SkipTime);
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

    public SkillAttackData GetAttackData(int attackDataIndex)
    {
        return currentSkillconfig.AttackData[attackDataIndex];
    }
}
