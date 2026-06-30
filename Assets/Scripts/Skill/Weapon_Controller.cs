using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Weapon_Controller : MonoBehaviour
{
    [SerializeField] private new Collider collider;//武器碰撞体
    [SerializeField] private MeleeWeaponTrail weaponTrail;//刀光脚本
    private List<string> enemyTagList;//可以被打到的标签列表

    private List<IHurt> enemyList = new List<IHurt>();//受到伤害的列表，防止重复伤害
    private Action<IHurt, Vector3> onHitAction;//受到伤害的事件

    public void Init(List<string> enemyTagList, Action<IHurt, Vector3> onHitAction)
    {
        collider.enabled = false;
        this.enemyTagList = enemyTagList;
        this.onHitAction = onHitAction;
        weaponTrail.Emit = false;
    }

    public void StartSkillHit()
    {
        collider.enabled = true;
        weaponTrail.Emit = true;
    } 
    
    public void StopSkillHit()
    {
        collider.enabled = false;
        weaponTrail.Emit = false;
        enemyList.Clear();
    }

    private void OnTriggerStay(Collider other)
    {
        //检测打击对象标签
        if (enemyTagList.Contains(other.tag))
        {
            IHurt enemy = other.GetComponentInParent<IHurt>();
            if (enemy != null && !enemyList.Contains(enemy))
            {
                Debug.Log("我攻击到了!");
                //添加到伤害列表，防止反复触发
                enemyList.Add(enemy);
                //通知上级(模型层)处理命中
                onHitAction?.Invoke(enemy, other.ClosestPoint(transform.position));//ClosestPoint是输入一个世界空间坐标点，返回该碰撞体表面上，距离输入点最近的那个点的世界坐标
            }
        }
    }
}
