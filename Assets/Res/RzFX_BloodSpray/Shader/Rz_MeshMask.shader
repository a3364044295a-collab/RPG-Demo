Shader "RyanShader/Rz_MeshMask"
{
    Properties
    {
        _Cutoff("Mask Clip Value", Float) = 0.5
        _MainTex("MainTex", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
        _Emission("Emission", Range(0, 1)) = 0
        _Metallic("Metallic", Range(0, 1)) = 0
        _Roughness("Roughness", Range(0, 1)) = 0
        _T_BloodNoise_01_normal("T_BloodNoise_01_normal", 2D) = "white" {}
        _NormalValue("NormalValue", Float) = 1
        _FlowSpeed("FlowSpeed", Float) = 1
        [HideInInspector] _texcoord("", 2D) = "white" {}
        [HideInInspector] _texcoord2("", 2D) = "white" {}
        [HideInInspector] __dirty("", Int) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "TransparentCutout"
            "Queue" = "AlphaTest"
            "IgnoreProjector" = "True"
        }

        Cull Back
        ZWrite On
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

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_T_BloodNoise_01_normal);
            SAMPLER(sampler_T_BloodNoise_01_normal);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _T_BloodNoise_01_normal_ST;
                half4 _Color;
                half _Emission;
                half _Metallic;
                half _Roughness;
                half _NormalValue;
                half _FlowSpeed;
                half _Cutoff;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                half4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
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

                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.uv2 = input.uv2;
                output.color = input.color;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 flowUv = input.uv + (_Time.y * _FlowSpeed * float2(0.0, -0.2));
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, flowUv);

                half mask = step((1.0h - input.uv2.x) * 1.01h, ((input.uv.y * mainTex.a) + mainTex.a) * 0.5h);
                clip(mask - _Cutoff);

                half alphaFactor = (mainTex.a + 1.0h) * 0.5h;
                half4 color = _Color * alphaFactor * input.color;
                color.rgb += color.rgb * _Emission;
                color.a = 1.0h;
                return color;
            }
            ENDHLSL
        }
    }
}
