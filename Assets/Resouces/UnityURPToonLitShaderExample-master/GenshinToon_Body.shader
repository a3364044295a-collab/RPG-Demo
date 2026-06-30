Shader "GenshinToon/Body"
{
    Properties//开放给外界的属性
    {
        [Header(Textures)]
        _BaseMap ("Base Map", 2D) = "white"{}//基础纹理
        _LightMap ("Light Map",2D) = "white"{}//光照贴图
        [Toggle(_USE_LIGHTMAP_AO)] _UseLightMapAO ("Use LightMap AO",Range(0, 1)) = 1 // AO开关
        _RampTex ("Ramp Tex", 2D) = "white" {} // 色阶阴影贴图
       

        [Header(Remp Shadow)]
         [Toggle(_USE_RAMP_SHADOW)] _UseRampShadow ("Use Ramp Shadow", Range(0, 1)) = 1 // 色阶阴影开关
        _ShadowRampWidth ("Shadow Ramp width", Float) = 1 // 阴影边缘宽度
        _ShadowPosition ("Shadow Position", Float) = 0.55 // 阴影位置
        _ShadowSoftness ("Shadow Softness", Float) = 0.5 //阴影柔和度
        [Toggle] _UseRampShadow2 ("Use Ramp Shadow 2", Range(0, 1)) = 1 // 使用第2行Ramp阴影开关
        [Toggle] _UseRampShadow3 ("Use Ramp Shadow 3", Range(0, 1)) = 1 // 使用第3行Ramp阴影开关
        [Toggle] _UseRampShadow4 ("Use Ramp Shadow 4", Range(0, 1)) = 1 // 使用第4行Ramp阴影开关
        [Toggle] _UseRampShadow5 ("Use Ramp Shadow 5", Range(0, 1)) = 1 // 使用第5行Ramp阴影开关

        [Header(Lighting Options)]
        _DayOrNight ("Day Or Night", Range(0, 1)) = 0 // 日夜切换参数
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

            #pragma shader_feature_local _USE_LIGHTMAP_AO // AO开关
            #pragma shader_feature_local _USE_RAMP_SHADOW // 色阶阴影开关

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // 核心库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" // 光照库

            CBUFFER_START(UnityPerMaterial)// 常量缓冲区开始

                // Textures
                sampler2D _BaseMap;// 基础纹理
                sampler2D _LightMap;// 光照贴图
                sampler2D _RampTex; // 色阶阴影贴图
                float _ShadowRampWidth; //阴影边缘宽度 
                float _ShadowPosition; // 阴影位置
                float _ShadowSoftness; // 阴影柔和度
                float _UseRampShadow2; // 使用第2行Ramp阴影开关
                float _UseRampShadow3; // 使用第3行Ramp阴影开关
                float _UseRampShadow4; // 使用第4行Ramp阴影开关
                float _UseRampShadow5; // 使用第5行Ramp阴影开关

                // Lighting Options
                float _DayOrNight; // 日夜切换参数

            CBUFFER_END // 常量缓冲区结束

            //根据LightMap的Alpha通道选择ramp行
            // 官方版本的RampShadowID函数
            float RampShadowID(float input, float useShadow2, float useShadow3, float useShadow4, float useShadow5, 
                float shadowValue1, float shadowValue2, float shadowValue3, float shadowValue4, float shadowValue5)
            {
                // 根据input值将模型分为5个区域
                float v1 = step(0.6, input) * step(input, 0.8); // 0.6-0.8区域
                float v2 = step(0.4, input) * step(input, 0.6); // 0.4-0.6区域
                float v3 = step(0.2, input) * step(input, 0.4); // 0.2-0.4区域
                float v4 = step(input, 0.2);                    // 0-0.2区域

                // 根据开关控制是否使用不同材质的值
                float blend12 = lerp(shadowValue1, shadowValue2, useShadow2);
                float blend15 = lerp(shadowValue1, shadowValue5, useShadow5);
                float blend13 = lerp(shadowValue1, shadowValue3, useShadow3);
                float blend14 = lerp(shadowValue1, shadowValue4, useShadow4);

                // 根据区域选择对应的材质值
                float result = blend12;                // 默认使用材质1或2
                result = lerp(result, blend15, v1);    // 0.6-0.8区域使用材质5
                result = lerp(result, blend13, v2);    // 0.4-0.6区域使用材质3
                result = lerp(result, blend14, v3);    // 0.2-0.4区域使用材质4
                result = lerp(result, shadowValue1, v4); // 0-0.2区域使用材质1

                return result;
            }


                 struct UniversalAttributes//顶点着色器输入参数
                {
                    float4 positionOS : POSITION; // 本地空间顶点坐标
                    float2 uv0 : TEXCOORD0; // 第一套纹理坐标
                    float2 uv1 : TEXCOORD1; // 第二套纹理坐标
                    float3 normalOS : NORMAL; // 本地坐标法线
                    float4 color : COLOR0; // 顶点颜色
                };

                 struct UniversalVaryings // 由顶点着色器返回，传递给片源着色器的输入参数
                {
                    float4 positionCS : SV_POSITION; // 裁剪空间顶点坐标
                    float2 uv0 : TEXCOORD0; // 第一套纹理坐标
                    float3 normalWS : TEXCOORD1; // 本地坐标法线
                    float4 color : TEXCOORD2; // 顶点颜色
                };

                   // 顶点着色器函数：返回裁剪空间坐标
                UniversalVaryings MainVS(UniversalAttributes input)
                {
                    UniversalVaryings output;// 定义顶点着色器的返回值

                    //position
                    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);// 将本地顶点空间转换为各种顶点空间
                    output.positionCS = vertexInput.positionCS;// 拿到裁剪空间的顶点坐标

                    //uv
                    output.uv0 = input.uv0;// 拿到uv纹理坐标

                    //nomal
                    VertexNormalInputs vni = GetVertexNormalInputs(input.normalOS); // 转换法线空间
                    output.normalWS = vni.normalWS; // 拿到世界空间法线

                    //color
                    output.color = input.color; // 传递顶点颜色

                    return output;
                }

                //片源着色器函数：返回颜色（rgba）
                half4 MainFS(UniversalVaryings input) : SV_TARGET // half相当于c语言的show，精度更低，相较float占显存更少，起优化作用
                {
                    Light light = GetMainLight();// 获取主光源
                    half4 vertexColor = input.color; // 顶点颜色

                    //Normalize Vector 
                    half3 N = normalize(input.normalWS);// 归一化法线
                    half3 L = normalize(light.direction);// 归一化光源方向
                    half NdotL = dot(N,L);// 计算法线与光源方向的点积

                    //Texture Info
                    half4 baseMap = tex2D(_BaseMap, input.uv0);// 采样纹理贴图
                    half4 lightMap = tex2D(_LightMap, input.uv0);// 采样光照贴图

                    //Lambert
                    half lambert = NdotL;// 兰伯特光照（-1到1）
                    half halflambert = lambert * 0.5 + 0.5;// 半兰伯特光照模型（0到1）
                    halflambert *= pow(halflambert, 2);
                    half lamberstep = smoothstep(0.01, 0.4, halflambert); // 在[0.01，0.4]范围内进行平滑插值
                    half shadowFactor = lerp(0, halflambert, lamberstep); // 计算阴影因子

                    //AO
                    #if _USE_LIGHTMAP_AO
                        half ambient = lightMap.g; // 环境光
                    #else
                        half ambient = halflambert;
                    #endif
                    half shadow = (ambient + halflambert) * 0.5; // 环境光遮蔽 
                    //shadow = 0.95 <= ambient ? 1 : shadow;
                    //shadow = ambient <= 0.05 ? 0 : shadow;
                    shadow = lerp(shadow, 1, step(0.95, shadow)); // 非常亮的区域全亮
                    shadow = lerp(shadow, 0, step(ambient, 0.05)); // 非常暗的区域全暗
                    half isShadowArea = step(shadow, _ShadowPosition); // 判断角色是否处于阴影区域
                    half shadowDepth = saturate((_ShadowPosition - shadow) / _ShadowPosition); // 阴影深度
                    shadowDepth = pow(shadowDepth, _ShadowSoftness); // 根据柔和度调节阴影深度
                    shadowDepth = min(shadowDepth, 1); // 限制阴影深度不超过1
                    half rampWidthFactor = vertexColor.g * 2 * _ShadowRampWidth; // 使用顶点颜色G通道控制Ramp宽度
                    half shadowPosition = (_ShadowPosition - shadowFactor) / _ShadowPosition; // 带入阴影因子计算阴影位置

                    // Ramp
                    half rampU = 1 - saturate(shadowDepth / rampWidthFactor); // 计算Ramp采样的横坐标
                    // 根据LightMap的Alpha的通道选择Remp行
                    half rampID = RampShadowID(lightMap.a, _UseRampShadow2, _UseRampShadow3, _UseRampShadow4, _UseRampShadow5, 1, 2, 3, 4, 5); 
                    half rampV = 0.45 - (rampID - 1) * 0.1; // 根据rampID计算v坐标
                    half2 rampDayUV = half2(rampU, rampV + 0.5); // 构建Ramp白天的UV坐标
                    half3 rampDayColor = tex2D(_RampTex, rampDayUV); //采样白天UV
                    half2 rampNightUV = half2(rampU, rampV); // 构建Ramp夜晚的UV坐标
                    half3 rampNightColor = tex2D(_RampTex, rampNightUV); //采样夜晚UV
                    half3 rampColor = lerp(rampDayColor, rampNightColor, _DayOrNight); // 采样Ramp贴图的颜色

                    //Merge Color 合并颜色
                    #if _USE_RAMP_SHADOW
                    // 使用Ramp阴影
                        half3 finalColor = baseMap.rgb * rampColor * (isShadowArea ? 1 : 1.2); //  采样Ramp阴影
                    #else
                        half3 finalColor = baseMap.rgb * halflambert * (shadow + 0.2); // 最终颜色
                    #endif

                    return half4(finalColor.rgb, 1);
                }
            
        ENDHLSL // 公共代码块结束

        Pass//渲染通道
        {
            Name "UniversalForward" // 通道名称
            Tags // 标签
            {
                "LightMode" = "UniversalForward" // 光照模式：向前渲染
            }

            Cull Back // 剔除模式

            HLSLPROGRAM // 着色器程序开始

                #pragma vertex MainVS
                //声明顶点着色器函数
                #pragma fragment MainFS
                //声明片源着色器函数
                
            ENDHLSL
        }

        Pass//渲染通道：背面渲染
        {
            Name "UniversalForward" // 通道名称
            Tags // 标签
            {
                "LightMode" = "SRPDefaultUnlit" // 光照模式：向前渲染
                "Queue" = "Geometry+1" // 渲染队列：值越大越靠后
            }

            Cull Front // 剔除模式

             HLSLPROGRAM // 着色器程序开始

                #pragma vertex BackMainVS
                //声明顶点着色器函数
                #pragma fragment MainFS
                //声明片源着色器函数

                UniversalVaryings BackMainVS(UniversalAttributes input)
                {
                    UniversalVaryings output = MainVS(input);
                    output.uv0 = input.uv1; // 将uv0替换成uv1
                    output.normalWS = -output.normalWS; // 翻转法向
                    return output;
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
