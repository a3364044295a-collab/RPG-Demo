using UnityEngine;

public class PlayerWeaponVisibility : MonoBehaviour
{
    [SerializeField] private Animator animator; // 角色动画控制器
    [SerializeField] private GameObject[] weapons; // 左右手武器对象

    private bool areWeaponsVisible;

    /// <summary>
    /// 自动获取 Animator，并初始化武器显示状态。
    /// </summary>
    private void Awake()
    {
        if (animator == null)
        {
            animator = GetComponentInChildren<Animator>();
        }

        SetWeaponsVisible(true);
    }

    /// <summary>
    /// 根据当前动画和过渡目标控制武器显隐。
    /// </summary>
    private void LateUpdate()
    {
        if (animator == null)
        {
            return;
        }

        bool shouldHide = ShouldHideWeapons(
            animator.GetCurrentAnimatorStateInfo(0));

        // 动画过渡期间提前隐藏，避免进入跳跃时短暂露出武器
        if (animator.IsInTransition(0))
        {
            shouldHide |= ShouldHideWeapons(
                animator.GetNextAnimatorStateInfo(0));
        }

        SetWeaponsVisible(!shouldHide);
    }

    /// <summary>
    /// 判断指定动画状态是否需要隐藏武器。
    /// </summary>
    /// <param name="stateInfo">需要检查的 Animator 状态信息。</param>
    /// <returns>处于 JumpStart 或 JumpEnd 时返回 true。</returns>
    private static bool ShouldHideWeapons(AnimatorStateInfo stateInfo)
    {
        return stateInfo.IsName("JumpStart")
            || stateInfo.IsName("JumpEnd")
            || stateInfo.IsName("RunStop");
    }

    /// <summary>
    /// 设置所有武器对象的显示状态。
    /// </summary>
    /// <param name="visible">为 true 时显示武器，否则隐藏武器。</param>
    private void SetWeaponsVisible(bool visible)
    {
        if (areWeaponsVisible == visible)
        {
            return;
        }

        areWeaponsVisible = visible;

        foreach (GameObject weapon in weapons)
        {
            if (weapon != null)
            {
                weapon.GetComponentInChildren<Renderer>().enabled = visible;
            }
        }
    }
}
