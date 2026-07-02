Shader "Hovl/Particles/Explosion"
{
    Properties
    {
        _Noise("Noise", 2D) = "white" {}
        _FinalEmission("Final Emission", Float) = 1
        _Color("Color", Color) = (1,1,1,1)
        _GlowColor("Glow Color", Color) = (1,1,0,1)
        _Opacity("Opacity", Range(0, 1)) = 1
        _NoisespeedXYNoisepowerZGlowpowerW("Noise speed XY Noise power Z Glow power W", Vector) = (0.314,0.427,0.001,4)
        _MotionVector("MotionVector", 2D) = "white" {}
        _MainTex("MainTex", 2D) = "white" {}
        _TilingXY("Tiling XY", Vector) = (8,8,0,0)
        _MotionAmount("MotionAmount", Float) = 0.001
        [MaterialToggle] _Usedepth("Use depth?", Float) = 0
        _Depthpower("Depth power", Float) = 1
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

            TEXTURE2D(_Noise); SAMPLER(sampler_Noise);
            TEXTURE2D(_MotionVector); SAMPLER(sampler_MotionVector);
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _Noise_ST;
                float4 _MainTex_ST;
                half4 _Color;
                half4 _GlowColor;
                half4 _NoisespeedXYNoisepowerZGlowpowerW;
                half4 _TilingXY;
                half _FinalEmission;
                half _Opacity;
                half _MotionAmount;
                half _Usedepth;
                half _Depthpower;
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

            float2 FlipbookUV(float2 uv, float frame)
            {
                float2 tiles = max(_TilingXY.xy, 1.0.xx);
                float total = tiles.x * tiles.y;
                float index = fmod(max(frame, 0.0), total);
                float x = fmod(index, tiles.x);
                float y = floor(index / tiles.x);
                y = tiles.y - 1.0 - y;
                return (uv + float2(x, y)) / tiles;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float2 noiseUV = input.uv.xy * _Noise_ST.xy + _Noise_ST.zw;
                noiseUV += _Time.y * _NoisespeedXYNoisepowerZGlowpowerW.xy;
                half noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, noiseUV).r;

                float frame = floor(input.uv.w);
                float blend = frac(input.uv.w);
                float2 baseUV = input.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                float2 uvA = FlipbookUV(baseUV, frame);
                float2 uvB = FlipbookUV(baseUV, frame + 1.0);

                half2 motion = SAMPLE_TEXTURE2D(_MotionVector, sampler_MotionVector, uvA).rg * 2.0h - 1.0h;
                motion *= _MotionAmount;

                half4 texA = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvA + motion * blend + noise * _NoisespeedXYNoisepowerZGlowpowerW.z);
                half4 texB = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvB + motion * (blend - 1.0) + noise * _NoisespeedXYNoisepowerZGlowpowerW.z);
                half4 mainTex = lerp(texA, texB, blend);

                half3 glow = _GlowColor.rgb * input.uv.z * pow(abs(mainTex.rgb), max(_NoisespeedXYNoisepowerZGlowpowerW.w, 0.001h));
                half3 color = (mainTex.rgb + glow) * _Color.rgb * input.color.rgb * _FinalEmission;
                half alpha = mainTex.a * _Color.a * input.color.a * _Opacity;
                return half4(color, alpha);
            }
            ENDHLSL
        }
    }
}
