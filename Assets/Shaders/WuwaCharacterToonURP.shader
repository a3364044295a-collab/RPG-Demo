Shader "RPG Demo/Character/Wuwa Toon URP"
{
    Properties
    {
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)

        _LightColorBlend ("Scene Light Blend", Range(0, 1)) = 0.45
        _LightingStrength ("Lighting Strength", Range(0, 1)) = 1
        _AmbientColor ("Character Ambient", Color) = (0.86, 0.88, 0.95, 1)
        _AmbientStrength ("Ambient Strength", Range(0, 1)) = 0.36

        _ShadeColor ("Shadow Tint", Color) = (0.66, 0.70, 0.86, 1)
        _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0.48
        _ShadowSoftness ("Shadow Softness", Range(0.001, 0.5)) = 0.11
        _ShadowStrength ("Shadow Strength", Range(0, 1)) = 0.72

        _SpecColor ("Specular Color", Color) = (1, 1, 1, 1)
        _SpecPower ("Specular Power", Range(8, 256)) = 80
        _SpecThreshold ("Specular Threshold", Range(0, 1)) = 0.88
        _SpecStrength ("Specular Strength", Range(0, 2)) = 0.12

        _RimColor ("Rim Color", Color) = (0.70, 0.86, 1, 1)
        _RimPower ("Rim Power", Range(0.5, 8)) = 3.2
        _RimStrength ("Rim Strength", Range(0, 2)) = 0.08

        _DarkLift ("Dark Line Lift", Range(0, 1)) = 0
        _DarkLiftColor ("Dark Line Color", Color) = (0.28, 0.30, 0.38, 1)
        _WhiteBoost ("White Area Boost", Range(0, 1)) = 0
        _WhiteBoostThreshold ("White Boost Threshold", Range(0, 1)) = 0.62
        _WhiteBoostColor ("White Boost Color", Color) = (0.94, 0.98, 1, 1)
        _Saturation ("Saturation", Range(0, 2)) = 1

        _OutlineColor ("Outline Color", Color) = (0.07, 0.055, 0.08, 1)
        _OutlineWidth ("Outline Width", Range(0, 0.03)) = 0.002

        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.08
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
            Name "ToonForward"
            Tags { "LightMode" = "UniversalForward" }

            Cull Back
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _LightColorBlend;
                half _LightingStrength;
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
                half4 _WhiteBoostColor;
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

            half3 ApplyTextureFixups(half3 color)
            {
                half luminance = dot(color, half3(0.299h, 0.587h, 0.114h));
                half chroma = max(max(color.r, color.g), color.b) - min(min(color.r, color.g), color.b);

                half darkMask = saturate(1.0h - luminance * 2.35h);
                color = lerp(color, max(color, _DarkLiftColor.rgb), darkMask * _DarkLift);

                half whiteMask = smoothstep(_WhiteBoostThreshold, 1.0h, luminance) * saturate(1.0h - chroma * 3.0h);
                color = lerp(color, max(color, _WhiteBoostColor.rgb), whiteMask * _WhiteBoost);

                half fixedLum = dot(color, half3(0.299h, 0.587h, 0.114h));
                color = lerp(fixedLum.xxx, color, _Saturation);
                return color;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 baseSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                if (_AlphaClip > 0.5h)
                {
                    clip(baseSample.a - _Cutoff);
                }

                baseSample.rgb = ApplyTextureFixups(baseSample.rgb);

                half3 normalWS = normalize(input.normalWS);
                half3 viewDirWS = normalize(input.viewDirWS);

                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                Light mainLight = GetMainLight(shadowCoord);

                half ndotl = dot(normalWS, mainLight.direction) * 0.5h + 0.5h;
                half shadowAttenuation = lerp(1.0h, mainLight.shadowAttenuation, _ShadowStrength);
                half lightTerm = ndotl * shadowAttenuation * mainLight.distanceAttenuation;
                half toonLight = smoothstep(_ShadowThreshold - _ShadowSoftness, _ShadowThreshold + _ShadowSoftness, lightTerm);

                half3 sceneLightColor = lerp(1.0h.xxx, mainLight.color, _LightColorBlend);
                half3 litColor = baseSample.rgb * sceneLightColor;
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
                color += rim * _RimColor.rgb * _RimStrength * _LightingStrength;

                #if defined(_ADDITIONAL_LIGHTS)
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                    {
                        Light light = GetAdditionalLight(lightIndex, input.positionWS);
                        half addNdotL = saturate(dot(normalWS, light.direction));
                        half addStep = smoothstep(0.5h, 0.72h, addNdotL);
                        color += baseSample.rgb * light.color * addStep * light.distanceAttenuation * 0.18h * _LightingStrength;
                    }
                #endif

                color = MixFog(color, input.fogFactor);
                return half4(color, baseSample.a);
            }
            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            Tags { "LightMode" = "SRPDefaultUnlit" }

            Cull Front
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _LightColorBlend;
                half _LightingStrength;
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
                half4 _WhiteBoostColor;
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
                half fogFactor : TEXCOORD0;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                float3 positionWS = positionInputs.positionWS + normalize(normalInputs.normalWS) * _OutlineWidth;
                output.positionCS = TransformWorldToHClip(positionWS);
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half3 color = MixFog(_OutlineColor.rgb, input.fogFactor);
                return half4(color, _OutlineColor.a);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _LightColorBlend;
                half _LightingStrength;
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
                half4 _WhiteBoostColor;
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
            };

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionInputs.positionWS, normalInputs.normalWS, _MainLightPosition.xyz));
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_Target
            {
                if (_AlphaClip > 0.5h)
                {
                    half alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).a * _BaseColor.a;
                    clip(alpha - _Cutoff);
                }
                return 0;
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
