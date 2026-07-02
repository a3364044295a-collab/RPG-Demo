Shader "Hovl/Particles/Add_Fresnel"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _Noise("Noise", 2D) = "white" {}
        _Color("Color", Color) = (0.5,0.5,0.5,1)
        _Emission("Emission", Float) = 2
        _SpeedMainTexUVNoiseZW("Speed MainTex U/V + Noise Z/W", Vector) = (0,0,0,0)
        _Flow("Flow", 2D) = "white" {}
        _Mask("Mask", 2D) = "white" {}
        _Distortionpower("Distortion power", Float) = 0.2
        _Fresnelscale("Fresnel scale", Float) = 3
        _Fresnelpower("Fresnel power", Float) = 3
        _Depthpower("Depth power", Float) = 0.2
        [Toggle]_Useonlycolor("Use only color", Float) = 0
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
                half4 _Color;
                half4 _SpeedMainTexUVNoiseZW;
                half _Emission;
                half _Distortionpower;
                half _Fresnelscale;
                half _Fresnelpower;
                half _Depthpower;
                half _Useonlycolor;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                half4 color : COLOR;
                float4 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half4 color : COLOR;
                float4 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                half3 normalWS : TEXCOORD2;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.color = input.color;
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float2 flowUV = input.uv.xy * _Flow_ST.xy + _Flow_ST.zw;
                flowUV += _Time.y * _SpeedMainTexUVNoiseZW.zw;
                half2 flow = SAMPLE_TEXTURE2D(_Flow, sampler_Flow, flowUV).rg;

                half mask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, input.uv.xy * _Mask_ST.xy + _Mask_ST.zw).a;
                float2 mainUV = input.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                mainUV += _Time.y * _SpeedMainTexUVNoiseZW.xy;
                mainUV -= flow * mask * _Distortionpower;

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUV);
                half4 noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, input.uv.xy * _Noise_ST.xy + _Noise_ST.zw);

                half3 normalWS = normalize(input.normalWS);
                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                half fresnel = saturate(_Fresnelscale * pow(1.0h - saturate(dot(normalWS, viewDirWS)), max(_Fresnelpower, 0.001h)));
                half alpha = mainTex.a * noise.a * _Color.a * input.color.a * saturate(fresnel + _Depthpower);
                half3 texColor = mainTex.rgb * noise.rgb * _Color.rgb * input.color.rgb;
                half3 color = lerp(texColor, _Color.rgb * input.color.rgb, saturate(_Useonlycolor)) * _Emission;

                return half4(color, alpha);
            }
            ENDHLSL
        }
    }
}
