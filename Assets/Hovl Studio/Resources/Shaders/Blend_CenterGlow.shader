Shader "Hovl/Particles/Blend_CenterGlow"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _Noise("Noise", 2D) = "white" {}
        _Flow("Flow", 2D) = "white" {}
        _Mask("Mask", 2D) = "white" {}
        _SpeedMainTexUVNoiseZW("Speed MainTex U/V + Noise Z/W", Vector) = (0,0,0,0)
        _DistortionSpeedXYPowerZ("Distortion Speed XY Power Z", Vector) = (0,0,0,0)
        _Emission("Emission", Float) = 2
        _Color("Color", Color) = (0.5,0.5,0.5,1)
        _Opacity("Opacity", Range(0, 3)) = 1
        [Toggle]_Usecenterglow("Use center glow?", Float) = 0
        [MaterialToggle] _Usedepth("Use depth?", Float) = 0
        _Depthpower("Depth power", Float) = 1
        [Enum(Cull Off,0, Cull Front,1, Cull Back,2)] _CullMode("Culling", Float) = 0
        [HideInInspector] _texcoord("", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask RGB
        Cull [_CullMode]
        ZWrite Off
        ZTest LEqual

        Pass
        {
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_Noise); SAMPLER(sampler_Noise);
            TEXTURE2D(_Flow); SAMPLER(sampler_Flow);
            TEXTURE2D(_Mask); SAMPLER(sampler_Mask);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST, _Noise_ST, _Flow_ST, _Mask_ST;
                half4 _SpeedMainTexUVNoiseZW, _DistortionSpeedXYPowerZ, _Color;
                half _Emission, _Opacity, _Usecenterglow, _Usedepth, _Depthpower, _CullMode;
            CBUFFER_END

            struct Attributes { float4 positionOS:POSITION; half4 color:COLOR; float4 uv:TEXCOORD0; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct Varyings { float4 positionHCS:SV_POSITION; half4 color:COLOR; float4 uv:TEXCOORD0; UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_OUTPUT_STEREO };

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.color = input.color;
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 mainUv = TRANSFORM_TEX(input.uv.xy, _MainTex) + _Time.y * _SpeedMainTexUVNoiseZW.xy;
                float2 noiseUv = TRANSFORM_TEX(input.uv.xy, _Noise) + _Time.y * _SpeedMainTexUVNoiseZW.zw;
                float2 flowUv = TRANSFORM_TEX(input.uv.xy, _Flow) + _Time.y * _DistortionSpeedXYPowerZ.xy;
                float2 maskUv = TRANSFORM_TEX(input.uv.xy, _Mask);

                half4 flow = SAMPLE_TEXTURE2D(_Flow, sampler_Flow, flowUv);
                half4 mask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, maskUv);
                mainUv -= flow.rg * mask.rg * _DistortionSpeedXYPowerZ.z;

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUv);
                half4 noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, noiseUv);
                half centerGlow = lerp(1.0h, saturate(1.0h - length(input.uv.xy - 0.5h) * 2.0h), saturate(_Usecenterglow));
                half alpha = saturate(mainTex.a * noise.a * mask.a * _Color.a * input.color.a * _Opacity * centerGlow);
                half3 rgb = mainTex.rgb * noise.rgb * _Color.rgb * input.color.rgb * _Emission;
                return half4(rgb, alpha);
            }
            ENDHLSL
        }
    }
}
