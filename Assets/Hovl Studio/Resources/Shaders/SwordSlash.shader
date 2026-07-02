Shader "Hovl/Particles/SwordSlash"
{
    Properties
    {
        _MainTexture("MainTexture", 2D) = "white" {}
        _EmissionTex("EmissionTex", 2D) = "white" {}
        _Opacity("Opacity", Float) = 20
        _Dissolve("Dissolve", 2D) = "white" {}
        _SpeedMainTexUVNoiseZW("Speed MainTex U/V + Noise Z/W", Vector) = (0,0,0,0)
        _Emission("Emission", Float) = 5
        _Remap("Remap", Vector) = (-2,1,0,0)
        _AddColor("Add Color", Color) = (0,0,0,0)
        _Desaturation("Desaturation", Float) = 0
        [Toggle]_Usesmoothdissolve("Use smooth dissolve", Float) = 0
        [HideInInspector] _texcoord("", 2D) = "white" {}
        _InvFade("Soft Particles Factor", Range(0.01,3.0)) = 1.0
        [MaterialToggle] _Usedepth("Use depth?", Float) = 0
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "RenderPipeline"="UniversalPipeline" }
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask RGB
        Cull Off
        ZWrite Off
        ZTest LEqual

        Pass
        {
            Name "UniversalForward"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTexture); SAMPLER(sampler_MainTexture);
            TEXTURE2D(_EmissionTex); SAMPLER(sampler_EmissionTex);
            TEXTURE2D(_Dissolve); SAMPLER(sampler_Dissolve);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTexture_ST;
                float4 _EmissionTex_ST;
                float4 _Dissolve_ST;
                half4 _SpeedMainTexUVNoiseZW;
                half4 _Remap;
                half4 _AddColor;
                half _Opacity;
                half _Emission;
                half _Desaturation;
                half _Usesmoothdissolve;
                half _InvFade;
                half _Usedepth;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                half4 color : COLOR;
                float4 uv : TEXCOORD0;
                float4 custom1 : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half4 color : COLOR;
                float4 uv : TEXCOORD0;
                float4 custom1 : TEXCOORD1;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.color = input.color;
                output.uv = input.uv;
                output.custom1 = input.custom1;
                return output;
            }

            half3 Desaturate(half3 color, half amount)
            {
                half gray = dot(color, half3(0.299h, 0.587h, 0.114h));
                return lerp(color, gray.xxx, saturate(amount));
            }

            half4 frag(Varyings input) : SV_Target
            {
                float2 mainUV = input.custom1.xy * _MainTexture_ST.xy + _MainTexture_ST.zw;
                mainUV += _Time.y * _SpeedMainTexUVNoiseZW.xy;

                float2 dissolveUV = input.uv.xy * _Dissolve_ST.xy + _Dissolve_ST.zw;
                dissolveUV += _Time.y * _SpeedMainTexUVNoiseZW.zw;
                dissolveUV.y += input.custom1.w;

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTexture, sampler_MainTexture, mainUV);
                half4 emissionTex = SAMPLE_TEXTURE2D(_EmissionTex, sampler_EmissionTex, input.uv.xy * _EmissionTex_ST.xy + _EmissionTex_ST.zw);
                half dissolve = SAMPLE_TEXTURE2D(_Dissolve, sampler_Dissolve, dissolveUV).r;

                half3 emission = Desaturate(emissionTex.rgb, _Desaturation);
                emission = saturate(lerp(_Remap.x.xxx, _Remap.y.xxx, emission));

                half dissolveCut = lerp(input.uv.z, saturate(input.uv.z - 0.5h), saturate(_Usesmoothdissolve));
                half dissolveAlpha = smoothstep(dissolveCut, dissolveCut + 0.08h, dissolve);
                half alpha = saturate(mainTex.a * _Opacity) * dissolveAlpha * input.color.a;
                half3 color = (_AddColor.rgb * input.color.rgb) + emission * _Emission * input.color.rgb;

                return half4(color, alpha);
            }
            ENDHLSL
        }
    }
}
