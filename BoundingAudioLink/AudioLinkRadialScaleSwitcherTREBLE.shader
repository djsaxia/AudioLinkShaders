Shader "Custom/AudioLinkRadialScaleSwitcherTREBLE"
{
    Properties
    {
        _MainColor ("Main Color", Color) = (1,1,1,1)

        _Duration_Offline ("Effect Duration (Offline)", Float) = 1.0
        _MinScale ("Min Scale", Float) = 1.0
        _MaxScale_Audio ("Max Scale (AudioLink)", Float) = 3.0
        _MaxScale_Offline ("Max Scale (Offline)", Float) = 1.2
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            Blend SrcAlpha One
            ZWrite Off
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float fadeT : TEXCOORD1;
            };

            fixed4 _MainColor;
            float _Duration_Offline;
            float _MinScale;
            float _MaxScale_Audio;
            float _MaxScale_Offline;

            v2f vert(appdata v)
            {
                v2f o;

                float audio = AudioLinkData(ALPASS_AUDIOLINK + ALPASS_AUDIOTREBLE).r;
                bool hasAudio = AudioLinkIsAvailable();

                float scale;
                float fadeT;

                if (hasAudio)
                {
                    // 音圧でスケール（saturateして安全に）
                    // float amp = saturate(audio * 5.0); // 0〜1に制限
                    // scale = lerp(_MinScale, _MaxScale_Audio, amp);
                    // fadeT = amp;
                    float targetAmp = pow(smoothstep(0.05, 0.4, audio), 0.5);

                    // 疑似的に波打たせて滑らかに（low-pass風）
                    float smoothing = saturate(sin(_Time.y * 3.0) * 0.5 + 0.5); // 0〜1
                    float amp = lerp(0.0, targetAmp, smoothing); // 瞬間変化を抑制

                    scale = lerp(_MinScale, _MaxScale_Audio, amp);
                    fadeT = amp;
                }
                else
                {
                    // AudioLink未対応：時間でスケーリング
                    float t = fmod(_Time.y, _Duration_Offline) / _Duration_Offline;
                    scale = lerp(_MinScale, _MaxScale_Offline, t);
                    fadeT = t;
                }

                float3 scaled = v.vertex.xyz * scale;
                o.pos = UnityObjectToClipPos(float4(scaled, 1.0));
                o.uv = v.uv;
                o.fadeT = fadeT;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float alpha = 1.0 - i.fadeT;
                return _MainColor * alpha;
            }
            ENDCG
        }
    }
    FallBack Off
}
