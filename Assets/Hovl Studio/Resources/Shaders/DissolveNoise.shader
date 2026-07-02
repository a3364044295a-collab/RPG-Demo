Shader "Hovl/Particles/DissolveNoise"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _TextureNoise("Texture Noise", 2D) = "white" {}
        _Dissolvenoise("Dissolve noise", 2D) = "white" {}
        _NoisespeedXYEmissonZPowerW("Noise speed XY / Emisson Z / Power W", Vector) = (0.5,0,2,1)
        _DissolvespeedXY("Dissolve speed XY", Vector) = (0,0,0,0)
        _Maincolor("Main color", Color) = (0.7609469,0.8547776,0.9433962,1)
        _Noisecolor("Noise color", Color) = (0.2470588,0.3012382,0.3607843,1)
        _Dissolvecolor("Dissolve color", Color) = (1,1,1,1)
        [Toggle]_Usetexturecolor("Use texture color", Float) = 0
        [Toggle]_Usetexturedissolve("Use texture dissolve", Float) = 0
        _Opacity("Opacity", Range(0, 1)) = 1
        [Toggle] _Usedepth("Use depth?", Float) = 0
        _InvFade("Soft Particles Factor", Range(0.01,3.0)) = 1.0
        [HideInInspector] _texcoord("", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask RGB
        Cull Off
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
            TEXTURE2D(_TextureNoise); SAMPLER(sampler_TextureNoise);
            TEXTURE2D(_Dissolvenoise); SAMPLER(sampler_Dissolvenoise);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST, _TextureNoise_ST, _Dissolvenoise_ST;
                half4 _NoisespeedXYEmissonZPowerW, _DissolvespeedXY, _Maincolor, _Noisecolor, _Dissolvecolor;
                half _Usetexturecolor, _Usetexturedissolve, _Opacity, _Usedepth, _InvFade;
            CBUFFER_END

            struct Attributes { float4 positionOS:POSITION; half4 color:COLOR; float4 uv:TEXCOORD0; float4 customData:TEXCOORD1; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct Varyings { float4 positionHCS:SV_POSITION; half4 color:COLOR; float4 uv:TEXCOORD0; float4 customData:TEXCOORD1; UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_OUTPUT_STEREO };

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.color = input.color;
                output.uv = input.uv;
                output.customData = input.customData;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 mainUv = TRANSFORM_TEX(input.uv.xy, _MainTex);
                float2 noiseUv = TRANSFORM_TEX(input.uv.xy, _TextureNoise) + _Time.y * _NoisespeedXYEmissonZPowerW.xy;
                float2 dissolveUv = TRANSFORM_TEX(input.uv.xy, _Dissolvenoise) + _Time.y * _DissolvespeedXY.xy;

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, mainUv);
                half4 noise = SAMPLE_TEXTURE2D(_TextureNoise, sampler_TextureNoise, noiseUv);
                half4 dissolve = SAMPLE_TEXTURE2D(_Dissolvenoise, sampler_Dissolvenoise, dissolveUv);

                half3 baseColor = lerp(_Maincolor.rgb, mainTex.rgb * _Maincolor.rgb, saturate(_Usetexturecolor));
                half dissolveMask = lerp(dissolve.r, dissolve.a, saturate(_Usetexturedissolve));
                half dissolveEdge = smoothstep(0.25h, 0.75h, dissolveMask);
                half alpha = saturate(mainTex.a * noise.a * dissolveEdge * _Opacity * input.color.a * _Maincolor.a);
                half3 rgb = (baseColor + noise.rgb * _Noisecolor.rgb + _Dissolvecolor.rgb * (1.0h - dissolveEdge)) * _NoisespeedXYEmissonZPowerW.z;
                rgb *= input.color.rgb;
                return half4(rgb, alpha);
            }
            ENDHLSL
        }
    }
}
