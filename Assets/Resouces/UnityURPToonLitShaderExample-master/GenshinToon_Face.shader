Shader "GenshinToon/Face"
{
    Properties//开放给外界的属性
    {
        [Header(Textures)]
        _BaseMap ("Base Map", 2D) = "white"{}//基础纹理

        [Header(Shadow Options)]
        [Toggle (_USE_SDF_SHADOW)] _UseSDFShadow ("Use SDF Shadow", Range(0, 1)) = 1 // sdf开关
        _SDF ("SDF", 2D) = "white" {} // 距离场纹理
        _ShadowMask ("Shadow Mask", 2D) = "white" {} // 阴影遮罩
        _ShadowColor ("Shadow Color", Color) = (1, 0.87, 0.87, 1) // 阴影颜色

        [Header(Head Direction)]
        [HideInInspector] _HeadForward ("Head Forward", Vector) = (0, 0, 1, 0) // 面部前方
        [HideInInspector] _HeadRight ("Head Right", Vector) = (1, 0, 0, 0) // 面部右方
        [HideInInspector] _HeadUp ("Head Up", Vector) = (0, 1, 0, 0) // 面部上方

        [Header(Face Blush)]
        _FaceBlushColor ("Face Blush Color", Color) = (1, 0, 0, 1) // 腮红颜色
        _FaceBlushStrength ("Face Blush Strength", Range(0, 1)) = 0
    }
    SubShader//子着色器
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"//指定渲染管线URP
            "RenderType" = "Opaque"// 指定渲染类型：不透明
        }

        HLSLINCLUDE//公共代码块开始
            //预处理指令、头文件、常量定义、函数定义
            #pragma multi_compile _MAIN_LIGHT_SHADOWS // 主光源阴影
            #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE // 主光源阴影级联
            #pragma multi_compile _MAIN_LIGHT_SHADOWS_SCREEN // 主光源阴影屏幕空间

            #pragma multi_compile_fragment _LIGHT_LAYERS // 光照层
            #pragma multi_compile_fragment _LIGHT_COOKIES // 光照饼干
            #pragma multi_compile_fragment _SCREEN_SPACE_OCCLUSION // 屏幕空间遮挡
            #pragma multi_compile_fragment _ADDITIONAL_LIGHT_SHADOWS // 额外光源阴影
            #pragma multi_compile_fragment _SHADOWS_SOFT // 阴影软化

            #pragma shader_feature_local _USE_SDF_SHADOW // sdf开关

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // 核心库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" // 光照库

            CBUFFER_START(UnityPerMaterial)//常量缓冲区

                //Texture
                sampler2D _BaseMap;

                //Shadow Options
                sampler2D _SDF; // 距离场纹理
                sampler2D _ShadowMask; // 阴影遮罩
                float4 _ShadowColor; // 阴影颜色

                // Head Direction
                float3 _HeadForward; // 面部前方
                float3 _HeadRight; // 面部右方
                float3 _HeadUp; // 面部上方

                // Face Blush
                float4 _FaceBlushColor; // 腮红颜色
                float _FaceBlushStrength; // 腮红强度

            CBUFFER_END
            
        ENDHLSL//公共代码块结束

        Pass//渲染通道
        {
            Name "UniversalForward" //通道名称
            Tags//标签
            {
                "LightMode" = "UniversalForward" //光照模式：向前渲染
            }

            HLSLPROGRAM // 着色器程序开始

                #pragma vertex MainVS
                //声明顶点着色器函数
                #pragma fragment MainFS
                //声明片源着色器函数

                struct Attributes//顶点着色器输入参数
                {
                    float4 positionOS : POSITION; //本地空间顶点坐标
                    float2 uv0 : TEXCOORD0; //第一套纹理坐标
                    float3 normalOS : NORMAL; //本地坐标法线
                };

                struct Varyings//由顶点着色器返回，传递给片源着色器的输入参数
                {
                    float4 positionCS : SV_POSITION; //裁剪空间顶点坐标
                    float2 uv0 : TEXCOORD0; //第一套纹理坐标
                    float3 normalWS : TEXCOORD1; //本地坐标法线
                };

                //顶点着色器函数：返回裁剪空间坐标
                Varyings MainVS(Attributes input)
                {
                    Varyings output;// 定义顶点着色器的返回值

                    //position
                    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);//将本地顶点空间转换为各种顶点空间
                    output.positionCS = vertexInput.positionCS;//拿到裁剪空间的顶点坐标
                    output.uv0 = input.uv0;//拿到uv纹理坐标

                    //nomal
                    VertexNormalInputs vni = GetVertexNormalInputs(input.normalOS);//转换法线空间
                    output.normalWS = vni.normalWS;//拿到世界空间法线

                    return output;
                }
                //片源着色器函数：返回颜色（rgba）
                half4 MainFS(Varyings input) : SV_TARGET //half相当于c语言的show，精度更低，相较float占显存更少，起优化作用
                {
                    Light light = GetMainLight();//获取主光源

                    //Normalize Vector 
                    half3 N = normalize(input.normalWS);//归一化法线
                    half3 L = normalize(light.direction);//归一化光源方向
                    half NdotL = dot(N,L);//计算法线与光源方向的点积
                    half3 headUpDir = normalize(_HeadUp); // 归一化面部上方
                    half3 headForwardDir = normalize(_HeadForward); // 归一化面部前方
                    half3 headRightDir = normalize(_HeadRight); // 归一化面部上右

                    //Texture Info
                    half4 baseMap = tex2D(_BaseMap, input.uv0);//采样纹理贴图
                    half4 shadowMask = tex2D(_ShadowMask, input.uv0); // 采样阴影遮罩

                    //Lambert
                    half lambert = NdotL;//兰伯特光照（-1到1）
                    half halflambert = lambert * 0.5 + 0.5;//半兰伯特光照模型（0到1）
                    halflambert *= pow(halflambert, 2);

                    // Face Shadow
                    half3 LpU = dot(L, headUpDir) / pow(length(headUpDir), 2) * headUpDir; // 计算光源方向在面部上方的投影
                    half3 LpHeadHorizon = normalize(L- LpU); // 光照方向在头部水平面上的投影
                    half value = acos(dot(LpHeadHorizon, headRightDir)) / 3.141592654; // 计算光照方向与面部右方的夹角
                    half exposeRight = step(value, 0.5); // 判断光照是来自右侧还是左侧
                    half valueR = pow(1 - value * 2, 3); // 右侧阴影强度
                    half valueL = pow(value * 2 - 1, 3); // 左侧阴影强度
                    half mixValue = lerp(valueL, valueR, exposeRight); // 混合阴影强度
                    half sdfLeft = tex2D(_SDF, half2(1 - input.uv0.x, input.uv0.y)).r; // 左侧距离场
                    half sdfRight = tex2D(_SDF, input.uv0).r; // 右侧距离场
                    half mixSdf = lerp(sdfRight, sdfLeft, exposeRight); // 采样SDF纹理
                    half sdf = step(mixValue, mixSdf); // 计算硬边界阴影
                    sdf = lerp(0, sdf, step(0, dot(LpHeadHorizon, headForwardDir))); // 计算右侧阴影
                    sdf *= shadowMask.g; // 使用G通道控制阴影强度
                    sdf = lerp(sdf, 1, shadowMask.a); // 使用A通道作为阴影遮罩

                    // Face Blush
                    half blushStrength = lerp(0, baseMap.a, _FaceBlushStrength); // 根据BaseMap的alpha通道计算腮红的强度

                    //Merge Color 合并颜色
                    #if _USE_SDF_SHADOW
                        half3 finalColor = lerp(_ShadowColor.rgb * baseMap.rgb, baseMap.rgb, sdf); // 合并阴影颜色
                    #else
                        half3 finalColor = baseMap.rgb * halflambert; // 阴影最终颜色
                    #endif
                    finalColor = lerp(finalColor, finalColor * _FaceBlushColor.rgb, blushStrength); // 合并腮红颜色

                    return half4(finalColor, 1);
                }
            ENDHLSL
        }

        Pass 
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster" // 光照模式：阴影投射
            }

            ZWrite On // 写入深度缓冲区
            ZTest LEqual // 深度测试：小于等于
            ColorMask 0 // 不写入颜色缓冲区
            Cull Off // 不裁剪

            HLSLPROGRAM //  着色器程序开始
                
                #pragma multi_compile_instancing // 启用GPU实例化编译
                #pragma multi_compile _ DOTS_INSTANCING_ON // 启用DOTS实例化编译
                #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW // 启用点光源阴影

                #pragma vertex ShadowVS // 声明顶点着色器函数
                #pragma fragment ShadowFS // 声明片源着色器函数

                float3 _LightDirection; // 光源方向
                float3 _LightPosition; // 光源位置

                // 顶点着色器输入参数
                struct Attributes
                {
                    float4 positionOS : POSITION; // 本地空间顶点坐标
                    float3 normalOS : NORMAL; // 本地坐标法线
                };

                struct Varyings // 由顶点着色器返回，传递给片源着色器的输入参数
                {
                    float4 positionCS : SV_POSITION; // 裁剪空间顶点坐标
                };

                // 将阴影的世界空间顶点位置转换为适合阴影投射的裁剪空间位置
                float4 GetShadowPositionHClip(Attributes input)
                {
                    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz); // 将本地空间顶点坐标转换为世界空间顶点坐标
                    float3 normalWS = TransformObjectToWorldNormal(input.normalOS); // 将本地空间法线转换为世界空间法线

                    #if _CASTING_PUNCTUAL_LIGHT_SHADOW // 点光源
                        float3 lightDirectionWS = normalize(_LightPosition - positionWS); // 计算光源方向
                    #else // 平行光
                        float3 lightDirectionWS = _LightDirection; // 使用预定义的光源方向
                    #endif

                    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS)); // 应用阴影偏移

                    // 根据平台的Z缓冲区方向调整Z值
                    #if UNITY_REVERSED_Z // 反转Z缓冲区
                        positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE); // 限制Z值在近裁剪平面以下
                    #else // 正向Z缓冲区
                        positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE); // 限制Z值在远裁剪平面以上
                    #endif

                    return positionCS; // 返回裁剪空间顶点坐标
                }

                // 顶点着色器
                Varyings ShadowVS(Attributes input)
                {
                    Varyings output;
                    output.positionCS = GetShadowPositionHClip(input);
                    return output;
                }

                //片源着色器
                half4 ShadowFS(Varyings input) : SV_TARGET
                {
                    return 0;
                }

            ENDHLSL //  着色器程序结束
        }
    }
}
