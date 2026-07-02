Shader "Hovl/Particles/Lightning"
{
    Properties
    {
        _MainTexture("Main Texture", 2D) = "white" {}
        _Noise("Noise", 2D) = "white" {}
        _FlowMap("Flow Map", 2D) = "white" {}
        _VFlowSpeed("V Flow Speed", Float) = 2
        _UFlowSpeed("U Flow Speed", Float) = 4
        _FlowStrength("Flow Strength", Float) = 0.1
        _Color("Color", Color) = (1,1,1,1)
        _Emission("Emission", Float) = 2
        _ShinnySpeed("Shinny Speed", Float) = 30
        [Toggle]_UseShinny("Use Shinny", Float) = 0
        [MaterialToggle] _Usedepth("Use depth?", Float) = 0
        _InvFade("Soft Particles Factor", Range(0.01,3.0)) = 1.0
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask RGB
        Cull Off
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

            TEXTURE2D(_MainTexture); SAMPLER(sampler_MainTexture);
            TEXTURE2D(_Noise); SAMPLER(sampler_Noise);
            TEXTURE2D(_FlowMap); SAMPLER(sampler_FlowMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTexture_ST, _Noise_ST, _FlowMap_ST;
                half4 _Color;
                half _VFlowSpeed, _UFlowSpeed, _FlowStrength, _Emission, _ShinnySpeed, _UseShinny, _Usedepth, _InvFade;
            CBUFFER_END

            struct Attributes { float4 positionOS:POSITION; half4 color:COLOR; float4 uv:TEXCOORD0; float4 customData:TEXCOORD1; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct Varyings { float4 positionHCS:SV_POSITION; half4 color:COLOR; float4 uv:TEXCOORD0; float4 customData:TEXCOORD1; UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_OUTPUT_STEREO };

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.color = input.color;
                output.uv = input.uv;
                output.customData = input.customData;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 baseUv = TRANSFORM_TEX(input.uv.xy, _MainTexture);
                float2 flowUv = TRANSFORM_TEX(input.uv.xy, _FlowMap) + _Time.y * float2(_UFlowSpeed, _VFlowSpeed);
                half4 flow = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, flowUv);
                float2 mainUv = baseUv + (flow.rg * 2.0h - 1.0h) * _FlowStrength;

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTexture, sampler_MainTexture, mainUv);
                half4 noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, TRANSFORM_TEX(input.uv.xy, _Noise) + _Time.y * 0.1h);
                half shinny = lerp(1.0h, saturate(sin(_Time.y * _ShinnySpeed + input.uv.x * 20.0h) * 0.5h + 0.5h), saturate(_UseShinny));
                half alpha = saturate(mainTex.a * noise.g * input.color.a * _Color.a);
                half3 rgb = mainTex.rgb * noise.rgb * _Color.rgb * input.color.rgb * _Emission * shinny;
                return half4(rgb, alpha);
            }
            ENDHLSL
        }
    }
}
