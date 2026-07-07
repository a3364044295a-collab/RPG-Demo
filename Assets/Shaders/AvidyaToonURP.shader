Shader "RPG Demo/Character/Avidya Toon URP"
{
    Properties
    {
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)

        _Opacity ("Opacity", Range(0, 1)) = 1
        _LightingStrength ("Lighting Strength", Range(0, 1)) = 1
        _LightColorBlend ("Scene Light Blend", Range(0, 1)) = 0.35
        _AmbientColor ("Ambient Color", Color) = (0.88, 0.90, 0.96, 1)
        _AmbientStrength ("Ambient Strength", Range(0, 1)) = 0.42

        _ShadeColor ("Shadow Tint", Color) = (0.66, 0.67, 0.76, 1)
        _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0.50
        _ShadowSoftness ("Shadow Softness", Range(0.001, 0.5)) = 0.11
        _ShadowStrength ("Shadow Strength", Range(0, 1)) = 0.62

        _SpecColor ("Specular Color", Color) = (1, 0.96, 0.82, 1)
        _SpecPower ("Specular Power", Range(8, 256)) = 96
        _SpecThreshold ("Specular Threshold", Range(0, 1)) = 0.88
        _SpecStrength ("Specular Strength", Range(0, 2)) = 0.12

        _RimColor ("Rim Color", Color) = (0.62, 0.80, 1, 1)
        _RimPower ("Rim Power", Range(0.5, 8)) = 3.5
        _RimStrength ("Rim Strength", Range(0, 2)) = 0.08

        _DarkLift ("Dark Area Lift", Range(0, 1)) = 0.06
        _DarkLiftColor ("Dark Lift Color", Color) = (0.38, 0.36, 0.42, 1)
        _WhiteBoost ("White Area Boost", Range(0, 1)) = 0.03
        _WhiteBoostThreshold ("White Boost Threshold", Range(0, 1)) = 0.68
        _Saturation ("Saturation", Range(0, 2)) = 1.03

        _OutlineColor ("Outline Color", Color) = (0.055, 0.045, 0.060, 1)
        _OutlineWidth ("Outline Width", Range(0, 0.03)) = 0.0014

        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Z Test", Float) = 4
        [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.01
        _AlphaClip ("Alpha Clip", Range(0, 1)) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "AvidyaForward"
            Tags { "LightMode" = "UniversalForward" }

            Cull [_Cull]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Blend [_SrcBlend] [_DstBlend]

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _Opacity;
                half _LightingStrength;
                half _LightColorBlend;
                half4 _AmbientColor;
                half _AmbientStrength;
                half4 _ShadeColor;
                half _ShadowThreshold;
                half _ShadowSoftness;
                half _ShadowStrength;
                half4 _SpecColor;
                half _SpecPower;
                half _SpecThreshold;
                half _SpecStrength;
                half4 _RimColor;
                half _RimPower;
                half _RimStrength;
                half _DarkLift;
                half4 _DarkLiftColor;
                half _WhiteBoost;
                half _WhiteBoostThreshold;
                half _Saturation;
                half4 _OutlineColor;
                half _OutlineWidth;
                half _Cutoff;
                half _AlphaClip;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                half3 normalWS : TEXCOORD2;
                half3 viewDirWS : TEXCOORD3;
                half fogFactor : TEXCOORD4;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.normalWS = NormalizeNormalPerVertex(normalInputs.normalWS);
                output.viewDirWS = GetWorldSpaceNormalizeViewDir(positionInputs.positionWS);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.fogFactor = ComputeFogFactor(positionInputs.positionCS.z);
                return output;
            }

            half3 FixTextureColor(half3 color)
            {
                half lum = dot(color, half3(0.299h, 0.587h, 0.114h));
                half chroma = max(max(color.r, color.g), color.b) - min(min(color.r, color.g), color.b);

                half darkMask = saturate(1.0h - lum * 2.5h);
                color = lerp(color, max(color, _DarkLiftColor.rgb), darkMask * _DarkLift);

                half whiteMask = smoothstep(_WhiteBoostThreshold, 1.0h, lum) * saturate(1.0h - chroma * 2.4h);
                color = lerp(color, max(color, half3(0.98h, 0.98h, 1.0h)), whiteMask * _WhiteBoost);

                half fixedLum = dot(color, half3(0.299h, 0.587h, 0.114h));
                return lerp(fixedLum.xxx, color, _Saturation);
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 baseSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                baseSample.a *= _Opacity;
                if (_AlphaClip > 0.5h)
                {
                    clip(baseSample.a - _Cutoff);
                }

                baseSample.rgb = FixTextureColor(baseSample.rgb);

                half3 normalWS = normalize(input.normalWS);
                half3 viewDirWS = normalize(input.viewDirWS);
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS));

                half halfLambert = dot(normalWS, mainLight.direction) * 0.5h + 0.5h;
                half shadowAttenuation = lerp(1.0h, mainLight.shadowAttenuation, _ShadowStrength);
                half lightTerm = halfLambert * shadowAttenuation * mainLight.distanceAttenuation;
                half toonLight = smoothstep(_ShadowThreshold - _ShadowSoftness, _ShadowThreshold + _ShadowSoftness, lightTerm);

                half3 sceneLight = lerp(1.0h.xxx, mainLight.color, _LightColorBlend);
                half3 litColor = baseSample.rgb * sceneLight;
                half3 shadeColor = baseSample.rgb * _ShadeColor.rgb;
                half3 color = lerp(shadeColor, litColor, toonLight);

                half3 ambient = baseSample.rgb * _AmbientColor.rgb * _AmbientStrength;
                color = max(color, ambient);
                color = lerp(baseSample.rgb, color, _LightingStrength);

                half3 halfDir = normalize(mainLight.direction + viewDirWS);
                half specRaw = pow(saturate(dot(normalWS, halfDir)), _SpecPower);
                half specStep = smoothstep(_SpecThreshold, 1.0h, specRaw);
                color += specStep * _SpecColor.rgb * _SpecStrength * toonLight * _LightingStrength;

                half rim = pow(1.0h - saturate(dot(normalWS, viewDirWS)), _RimPower);
                color += rim * _RimColor.rgb * _RimStrength * toonLight * _LightingStrength;

                color = MixFog(color, input.fogFactor);
                return half4(color, baseSample.a);
            }
            ENDHLSL
        }

        Pass
        {
            Name "AvidyaOutline"
            Tags { "LightMode" = "SRPDefaultUnlit" }

            Cull Front
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _Opacity;
                half _LightingStrength;
                half _LightColorBlend;
                half4 _AmbientColor;
                half _AmbientStrength;
                half4 _ShadeColor;
                half _ShadowThreshold;
                half _ShadowSoftness;
                half _ShadowStrength;
                half4 _SpecColor;
                half _SpecPower;
                half _SpecThreshold;
                half _SpecStrength;
                half4 _RimColor;
                half _RimPower;
                half _RimStrength;
                half _DarkLift;
                half4 _DarkLiftColor;
                half _WhiteBoost;
                half _WhiteBoostThreshold;
                half _Saturation;
                half4 _OutlineColor;
                half _OutlineWidth;
                half _Cutoff;
                half _AlphaClip;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                float3 positionWS = positionInputs.positionWS + normalize(normalInputs.normalWS) * _OutlineWidth;
                output.positionCS = TransformWorldToHClip(positionWS);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                clip(_OutlineWidth - 0.00001h);
                return half4(_OutlineColor.rgb, _Opacity);
            }
            ENDHLSL
        }
    }
}
