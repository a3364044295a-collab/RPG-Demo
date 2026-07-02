Shader "Hovl/Particles/Scroll"
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
        _Opacity("Opacity", Range(0, 1)) = 1
        _PathSet0ifyouuseinPS("Path(Set 0 if you use in PS)", Range(0, 1)) = 0
        _Noisedistortpower("Noise distort power", Float) = 1
        [Toggle]_UsePScustomdataW("Use PS custom data W", Float) = 1
        [MaterialToggle] _Usedepth("Use depth?", Float) = 0
        _InvFade("Soft Particles Factor", Range(0.01,3.0)) = 1.0
        [HideInInspector] _texcoord("", 2D) = "white" {}
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

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_Noise); SAMPLER(sampler_Noise);
            TEXTURE2D(_Flow); SAMPLER(sampler_Flow);
            TEXTURE2D(_Mask); SAMPLER(sampler_Mask);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Noise_ST;
                float4 _Flow_ST;
                float4 _Mask_ST;
                half4 _SpeedMainTexUVNoiseZW;
                half4 _DistortionSpeedXYPowerZ;
                half4 _Color;
                half _Emission;
                half _Opacity;
                half _PathSet0ifyouuseinPS;
                half _Noisedistortpower;
                half _UsePScustomdataW;
                half _Usedepth;
                half _InvFade;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                half4 color : COLOR;
                float4 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half4 color : COLOR;
                float4 uv : TEXCOORD0;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.color = input.color;
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float2 mainUV = input.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                mainUV += _Time.y * _SpeedMainTexUVNoiseZW.xy;

                float2 flowUV = input.uv.xy * _Flow_ST.xy + _Flow_ST.zw;
                flowUV += _Time.y * _DistortionSpeedXYPowerZ.xy;
                half2 flow = SAMPLE_TEXTURE2D(_Flow, sampler_Flow, flowUV).rg * _DistortionSpeedXYPowerZ.z;

                float2 noiseUV = input.uv.xy * _Noise_ST.xy + _Noise_ST.zw;
                noiseUV += _Time.y * _SpeedMainTexUVNoiseZW.zw;
                noiseUV.y = saturate(noiseUV.y - _PathSet0ifyouuseinPS - input.uv.z);

                half4 noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, noiseUV - flow);
                half noiseAlpha = saturate(pow(saturate(noise.a - 0.1h), max(_Noisedistortpower + input.uv.w * _UsePScustomdataW * 10.0h, 0.001h)));
                half alphaRamp = saturate(1.0h - pow(1.0h - input.uv.y, 40.0h));

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUV - flow);
                half mask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, input.uv.xy * _Mask_ST.xy + _Mask_ST.zw).a;

                half alpha = noiseAlpha * alphaRamp * _Color.a * input.color.a * _Opacity * mask;
                half3 color = mainTex.rgb * saturate(noise.rgb) * _Color.rgb * input.color.rgb * alphaRamp * _Emission;
                return half4(color, alpha);
            }
            ENDHLSL
        }
    }
}
