Shader "Hovl/Particles/Distortion"
{
    Properties
    {
        _NormalMap("Normal Map", 2D) = "bump" {}
        _Distortionpower("Distortion power", Float) = 0.05
        _InvFade("Soft Particles Factor", Range(0.01, 3.0)) = 1.0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
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

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            float4 _CameraOpaqueTexture_TexelSize;

            CBUFFER_START(UnityPerMaterial)
                float4 _NormalMap_ST;
                half _Distortionpower;
                half _InvFade;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                half4 color : COLOR;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half4 color : COLOR;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
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
                output.uv = TRANSFORM_TEX(input.uv, _NormalMap);
                output.color = input.color;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half3 normalSample = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv));
                half mask = saturate((abs(normalSample.r) + abs(normalSample.g)) * 30.0h - 0.03h);

                float2 screenUV = input.screenPos.xy / input.screenPos.w;
                float2 offset = normalSample.rg * _CameraOpaqueTexture_TexelSize.xy * _Distortionpower * input.color.a;
                half3 sceneColor = SampleSceneColor(screenUV + offset);

                return half4(sceneColor, mask * input.color.a);
            }
            ENDHLSL
        }
    }
}
