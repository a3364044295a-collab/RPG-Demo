Shader "RPG Demo/Character/Avidya Eye Unlit URP"
{
    Properties
    {
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Opacity ("Opacity", Range(0, 1)) = 1
        _Brightness ("Brightness", Range(0, 2)) = 1.08
        _Saturation ("Saturation", Range(0, 2)) = 1.1
        _IrisColorTop ("Iris Top", Color) = (0.13, 0.34, 0.62, 1)
        _IrisColorBottom ("Iris Bottom", Color) = (0.18, 0.86, 0.92, 1)
        _PupilColor ("Pupil", Color) = (0.02, 0.04, 0.11, 1)
        _IrisRadius ("Iris Radius", Range(0.05, 0.6)) = 0.30
        _PupilRadius ("Pupil Radius", Range(0.02, 0.35)) = 0.12
        _IrisCenterX ("Iris Center X", Range(0, 1)) = 0.5
        _IrisCenterY ("Iris Center Y", Range(0, 1)) = 0.5
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
            Name "AvidyaEyeUnlit"
            Tags { "LightMode" = "UniversalForward" }

            Cull Off
            ZWrite Off
            ZTest Always
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
                half _Brightness;
                half _Saturation;
                half4 _IrisColorTop;
                half4 _IrisColorBottom;
                half4 _PupilColor;
                half _IrisRadius;
                half _PupilRadius;
                half _IrisCenterX;
                half _IrisCenterY;
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
                half2 uv = input.uv;
                half2 center = half2(_IrisCenterX, _IrisCenterY);
                half2 eyeUv = (uv - center) * half2(1.0h, 1.45h);
                half dist = length(eyeUv);

                half3 sclera = half3(0.96h, 0.94h, 0.90h);
                half3 iris = lerp(_IrisColorTop.rgb, _IrisColorBottom.rgb, saturate((center.y - uv.y) * 2.0h + 0.5h));
                half irisMask = 1.0h - smoothstep(_IrisRadius * 0.92h, _IrisRadius, dist);
                half pupilMask = 1.0h - smoothstep(_PupilRadius * 0.88h, _PupilRadius, dist);
                half ringMask = smoothstep(_IrisRadius * 0.78h, _IrisRadius, dist) * irisMask;

                half3 colorRgb = lerp(sclera, iris, irisMask);
                colorRgb = lerp(colorRgb, colorRgb * 0.42h, ringMask * 0.55h);
                colorRgb = lerp(colorRgb, _PupilColor.rgb, pupilMask);

                half2 highlightUv = (uv - (center + half2(-0.10h, 0.14h))) * half2(1.7h, 2.5h);
                half highlight = 1.0h - smoothstep(0.045h, 0.075h, length(highlightUv));
                colorRgb = lerp(colorRgb, half3(1.0h, 1.0h, 1.0h), highlight * 0.85h);

                half lum = dot(colorRgb, half3(0.299h, 0.587h, 0.114h));
                colorRgb = lerp(lum.xxx, colorRgb, _Saturation) * _Brightness;

                half4 color = half4(colorRgb, _Opacity);
                color.rgb = MixFog(color.rgb, input.fogFactor);
                return color;
            }
            ENDHLSL
        }
    }
}
