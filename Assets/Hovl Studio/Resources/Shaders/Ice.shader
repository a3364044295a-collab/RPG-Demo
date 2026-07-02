Shader "Hovl/Particles/Ice"
{
    Properties
    {
        _MainTex("Main Tex", 2D) = "white" {}
        _Color("Color", Color) = (0.02352941,0.2055747,1,1)
        _UpColor("Up Color", Color) = (0.4575472,0.7381514,1,1)
        _ColorPosition("Color Position", Range(0, 1)) = 0.35
        _Emission("Emission", Float) = 1
        [HDR]_FresnelColor("Fresnel Color", Color) = (1,1,1,1)
        _FresnelPower("Fresnel Power", Float) = 6
        _FresnelScale("Fresnel Scale", Float) = 1
        [HideInInspector] _texcoord("", 2D) = "white" {}
        [HideInInspector] __dirty("", Int) = 1
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True" "IsEmissive"="true" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Back
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

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _Color;
                half4 _UpColor;
                half4 _FresnelColor;
                half _ColorPosition;
                half _Emission;
                half _FresnelPower;
                half _FresnelScale;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                half4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                half3 normalWS : TEXCOORD1;
                half3 normalOS : TEXCOORD2;
                half4 color : COLOR;
                float2 uv : TEXCOORD3;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.normalOS = input.normalOS;
                output.color = input.color;
                output.uv = input.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half gradient = saturate(input.normalOS.y + lerp(-1.0h, 1.0h, _ColorPosition));
                half4 rampColor = lerp(_Color, _UpColor, gradient);

                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                half fresnel = saturate(_FresnelScale * pow(1.0h - saturate(dot(normalize(input.normalWS), viewDirWS)), max(_FresnelPower, 0.001h)));

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                half3 color = ((mainTex.rgb * rampColor.rgb * (1.0h - fresnel)) + (fresnel * _FresnelColor.rgb)) * input.color.rgb * _Emission;
                half alpha = mainTex.a * rampColor.a * input.color.a;
                return half4(color, alpha);
            }
            ENDHLSL
        }
    }
}
