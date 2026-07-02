Shader "Hovl/Particles/BlendDistort"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _Noise("Noise", 2D) = "white" {}
        _Flow("Flow", 2D) = "white" {}
        _Mask("Mask", 2D) = "white" {}
        _NormalMap("NormalMap", 2D) = "bump" {}
        _Color("Color", Color) = (0.5,0.5,0.5,1)
        _Distortionpower("Distortion power", Float) = 0
        _SpeedMainTexUVNoiseZW("Speed MainTex U/V + Noise Z/W", Vector) = (0,0,0,0)
        _DistortionSpeedXYPowerZ("Distortion Speed XY Power Z", Vector) = (0,0,0,0)
        _Emission("Emission", Float) = 2
        _Opacity("Opacity", Range(0, 3)) = 1
        [Toggle]_Usedepth("Use depth?", Float) = 1
        [Toggle]_Softedges("Soft edges", Float) = 0
        _Depthpower("Depth power", Float) = 1
        [HideInInspector] _texcoord("", 2D) = "white" {}
        [HideInInspector] _tex4coord("", 2D) = "white" {}
        [HideInInspector] __dirty("", Int) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "IsEmissive" = "true"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off
        ZTest LEqual

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_Noise);
            SAMPLER(sampler_Noise);
            TEXTURE2D(_Flow);
            SAMPLER(sampler_Flow);
            TEXTURE2D(_Mask);
            SAMPLER(sampler_Mask);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            float4 _CameraOpaqueTexture_TexelSize;

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Noise_ST;
                float4 _Flow_ST;
                float4 _Mask_ST;
                float4 _NormalMap_ST;
                half4 _Color;
                half _Distortionpower;
                half4 _SpeedMainTexUVNoiseZW;
                half4 _DistortionSpeedXYPowerZ;
                half _Emission;
                half _Opacity;
                half _Usedepth;
                half _Softedges;
                half _Depthpower;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 customData : TEXCOORD1;
                half4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 customData : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                half4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionHCS = positionInputs.positionCS;
                output.screenPos = ComputeScreenPos(output.positionHCS);
                output.uv = input.uv;
                output.customData = input.customData;
                output.color = input.color;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 screenUV = input.screenPos.xy / input.screenPos.w;

                float2 normalUv = TRANSFORM_TEX(input.uv, _NormalMap)
                    + _Time.y * _SpeedMainTexUVNoiseZW.zw;
                half3 normalSample = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, normalUv));
                float2 screenOffset = normalSample.rg * _CameraOpaqueTexture_TexelSize.xy * _Distortionpower * input.color.a;
                half3 sceneColor = SampleSceneColor(screenUV + screenOffset);

                float2 mainUv = TRANSFORM_TEX(input.uv, _MainTex)
                    + _Time.y * _SpeedMainTexUVNoiseZW.xy;
                float2 flowUv = TRANSFORM_TEX(input.customData.xy, _Flow)
                    + _Time.y * _DistortionSpeedXYPowerZ.xy;
                float2 maskUv = TRANSFORM_TEX(input.uv, _Mask);

                half4 flow = SAMPLE_TEXTURE2D(_Flow, sampler_Flow, flowUv);
                half4 mask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, maskUv);
                mainUv -= (flow.rg * mask.rg) * _DistortionSpeedXYPowerZ.z;

                float2 noiseUv = TRANSFORM_TEX(input.uv, _Noise)
                    + _Time.y * _SpeedMainTexUVNoiseZW.zw
                    + float2(input.customData.w, 0.0);
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUv);
                half4 noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, noiseUv);

                half alpha = saturate(mainTex.a * noise.a * _Color.a * input.color.a * _Opacity);
                half3 effectColor = (mainTex.rgb * noise.rgb * _Color.rgb * input.color.rgb) * _Emission * alpha;

                half blendMode = saturate(input.customData.z);
                half3 additive = sceneColor + effectColor;
                half3 multiply = sceneColor * max(effectColor, half3(0.001h, 0.001h, 0.001h));
                half3 finalColor = lerp(additive, multiply, blendMode);

                return half4(finalColor, alpha);
            }
            ENDHLSL
        }
    }
}
