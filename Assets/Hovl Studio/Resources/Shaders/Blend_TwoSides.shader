Shader "Hovl/Particles/Blend_TwoSides"
{
    Properties
    {
        _Cutoff("Mask Clip Value", Float) = 0.5
        _MainTex("Main Tex", 2D) = "white" {}
        _Mask("Mask", 2D) = "white" {}
        _Noise("Noise", 2D) = "white" {}
        _SpeedMainTexUVNoiseZW("Speed MainTex U/V + Noise Z/W", Vector) = (0,0,0,0)
        _Emission("Emission", Float) = 2
        [Toggle]_UseFresnel("Use Fresnel?", Float) = 1
        [Toggle]_Usesmoothcorners("Use smooth corners?", Float) = 0
        _Fresnel("Fresnel", Float) = 1
        _FresnelEmission("Fresnel Emission", Float) = 1
        [Toggle]_SeparateFresnel("SeparateFresnel", Float) = 0
        _SeparateEmission("Separate Emission", Float) = 2
        _FresnelColor("Fresnel Color", Color) = (0.3568628,0.08627451,0.08627451,1)
        _FrontFacesColor("Front Faces Color", Color) = (0,0.2313726,1,1)
        _BackFacesColor("Back Faces Color", Color) = (0,0.02397324,0.509434,1)
        _BackFresnelColor("Back Fresnel Color", Color) = (0.3568628,0.08627451,0.08627451,1)
        [Toggle]_UseBackFresnel("Use Back Fresnel?", Float) = 1
        _BackFresnel("Back Fresnel", Float) = -2
        _BackFresnelEmission("Back Fresnel Emission", Float) = 1
        [Toggle]_UseCustomData("Use Custom Data?", Float) = 0
        [Toggle]_Sideopacity("Side opacity", Float) = 0
        [HideInInspector] _texcoord("", 2D) = "white" {}
        [HideInInspector] __dirty("", Int) = 1
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "IsEmissive"="true" "PreviewType"="Plane" }
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
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
            TEXTURE2D(_Mask); SAMPLER(sampler_Mask);
            TEXTURE2D(_Noise); SAMPLER(sampler_Noise);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST, _Mask_ST, _Noise_ST;
                half4 _SpeedMainTexUVNoiseZW, _FresnelColor, _FrontFacesColor, _BackFacesColor, _BackFresnelColor;
                half _Cutoff, _Emission, _UseFresnel, _Usesmoothcorners, _Fresnel, _FresnelEmission;
                half _SeparateFresnel, _SeparateEmission, _UseBackFresnel, _BackFresnel, _BackFresnelEmission;
                half _UseCustomData, _Sideopacity;
            CBUFFER_END

            struct Attributes { float4 positionOS:POSITION; float3 normalOS:NORMAL; half4 color:COLOR; float4 uv:TEXCOORD0; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct Varyings { float4 positionHCS:SV_POSITION; float3 normalWS:TEXCOORD0; float3 viewDirWS:TEXCOORD1; half4 color:COLOR; float4 uv:TEXCOORD2; UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_OUTPUT_STEREO };

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                VertexPositionInputs pos = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionHCS = pos.positionCS;
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.viewDirWS = GetWorldSpaceViewDir(pos.positionWS);
                output.color = input.color;
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input, bool isFrontFace : SV_IsFrontFace) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 mainUv = TRANSFORM_TEX(input.uv.xy, _MainTex) + _Time.y * _SpeedMainTexUVNoiseZW.xy;
                float2 maskUv = TRANSFORM_TEX(input.uv.xy, _Mask);
                float2 noiseUv = TRANSFORM_TEX(input.uv.xy, _Noise) + _Time.y * _SpeedMainTexUVNoiseZW.zw + input.uv.w;

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUv);
                half4 mask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, maskUv);
                half4 noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, noiseUv);
                half alphaMask = saturate(mask.a * noise.a * mainTex.a);
                clip(alphaMask - _Cutoff);

                half customFade = lerp(1.0h, input.uv.z, saturate(_UseCustomData));
                half3 normalWS = normalize(input.normalWS) * (isFrontFace ? 1.0h : -1.0h);
                half3 viewDirWS = normalize(input.viewDirWS);
                half fresnelPower = max(abs(isFrontFace ? _Fresnel : _BackFresnel), 0.01h);
                half fresnel = pow(saturate(1.0h - dot(normalWS, viewDirWS)), fresnelPower);

                half4 baseColor = isFrontFace ? _FrontFacesColor : _BackFacesColor;
                half4 fresnelColor = isFrontFace ? _FresnelColor : _BackFresnelColor;
                half useFresnel = isFrontFace ? _UseFresnel : _UseBackFresnel;
                half fresnelEmission = isFrontFace ? _FresnelEmission : _BackFresnelEmission;

                half3 rgb = baseColor.rgb * mainTex.rgb;
                rgb += fresnelColor.rgb * fresnel * fresnelEmission * useFresnel;
                rgb *= _Emission * input.color.rgb;
                half alpha = saturate(alphaMask * baseColor.a * input.color.a * customFade);
                return half4(rgb, alpha);
            }
            ENDHLSL
        }
    }
}
