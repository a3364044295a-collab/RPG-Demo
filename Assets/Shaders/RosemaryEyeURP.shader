Shader "RPG Demo/Character/Rosemary Eye URP"
{
    Properties
    {
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Opacity ("Opacity", Range(0, 1)) = 1
        _DarkLift ("Dark Area Lift", Range(0, 1)) = 0.12
        _DarkLiftColor ("Dark Lift Color", Color) = (0.45, 0.34, 0.36, 1)
        _WhiteBoost ("White Boost", Range(0, 1)) = 0.08
        _Saturation ("Saturation", Range(0, 2)) = 1.03
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.01
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "EyeTransparent"
            Tags { "LightMode" = "UniversalForward" }

            Cull Off
            ZWrite Off
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _Opacity;
                half _DarkLift;
                half4 _DarkLiftColor;
                half _WhiteBoost;
                half _Saturation;
                half _Cutoff;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                half fogFactor : TEXCOORD1;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.fogFactor = ComputeFogFactor(positionInputs.positionCS.z);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                clip(tex.a - _Cutoff);

                half lum = dot(tex.rgb, half3(0.299h, 0.587h, 0.114h));
                half darkMask = saturate(1.0h - lum * 2.25h);
                tex.rgb = lerp(tex.rgb, max(tex.rgb, _DarkLiftColor.rgb), darkMask * _DarkLift);

                half whiteMask = smoothstep(0.66h, 1.0h, lum);
                tex.rgb = lerp(tex.rgb, max(tex.rgb, half3(0.96h, 0.98h, 1.0h)), whiteMask * _WhiteBoost);

                half fixedLum = dot(tex.rgb, half3(0.299h, 0.587h, 0.114h));
                tex.rgb = lerp(fixedLum.xxx, tex.rgb, _Saturation);

                tex.rgb = MixFog(tex.rgb, input.fogFactor);
                tex.a *= _Opacity;
                return tex;
            }
            ENDHLSL
        }
    }
}
