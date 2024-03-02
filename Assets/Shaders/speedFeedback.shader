Shader "PostProcessing/speedFeedback"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CarSpeed ("Car Speed", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct VertexData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _CarSpeed;

            // possible functions generated by unity's shader graph
            inline float unity_noise_randomValue (float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
            }

            inline float unity_noise_interpolate (float a, float b, float t)
            {
                return (1.0-t)*a + (t*b);
            }

            inline float unity_valueNoise (float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                uv = abs(frac(uv) - 0.5);
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0 = unity_noise_randomValue(c0);
                float r1 = unity_noise_randomValue(c1);
                float r2 = unity_noise_randomValue(c2);
                float r3 = unity_noise_randomValue(c3);

                float bottomOfGrid = unity_noise_interpolate(r0, r1, f.x);
                float topOfGrid = unity_noise_interpolate(r2, r3, f.x);
                float t = unity_noise_interpolate(bottomOfGrid, topOfGrid, f.y);
                return t;
            }

            float Unity_SimpleNoise_float(float2 UV, float Scale)
            {
                float t = 0.0;

                float freq = pow(2.0, float(0));
                float amp = pow(0.5, float(3-0));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3-1));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3-2));
                t += unity_valueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

                return t;
            }

            float inverseLerp(float A, float B, float T){
                return (T - A)/(B - A);
            }

            float2 rotateRad(float2 uv, float2 center, float rotation)
            {
                uv -= center;
                float s = sin(rotation);
                float c = cos(rotation);
                float2x2 rMatrix = float2x2(c, -s, s, c);
                rMatrix *= 0.5;
                rMatrix += 0.5;
                rMatrix = rMatrix * 2 - 1;
                uv.xy = mul(uv.xy, rMatrix);
                uv += center;
                return uv;
            }
            // ---------------------------------------------------------

            v2f vert (VertexData v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // TODO: if speed = 0, return unmodified texture sample
                // If speed = 0, due to the random nature of the noise generator, we might get some small random lines when the car is meant to be stopped
                float2 rotationSpeed = 1.0f;

                // noise pattern
                float2 center = float2(0.5, 0.5);
                float radialScale = 0.05f;
                float lengthScale = 20.0f;
                float2 delta = i.uv - center;
                float radius = length(delta) * 2 * radialScale;
                float angle = atan2(delta.x, delta.y) * 1.0/6.28 * lengthScale;
                float2 polarCoords = float2(radius, angle);
                float2 rotatedPolarCoords = rotateRad(polarCoords, center, _Time * rotationSpeed);

                float noiseScale = 100;
                float noiseVal = Unity_SimpleNoise_float(rotatedPolarCoords, noiseScale);
                // ---------------------------------------------------------

                // mask
                float centerMaskSize = 0.06;
                float centerMaskEdge = clamp(1.0 - _CarSpeed/5.0, 0.5, 1.0);
                float distanceToCenter = distance(center, i.uv);
                float cleanMask = inverseLerp(centerMaskSize, centerMaskSize + centerMaskEdge, distanceToCenter);

                float lineDensity = 0.5;
                float lineMul = mul(cleanMask, lineDensity);
                float lineMax = 1 - lineMul;

                float lineFalloff = 0.25;
                float lineMin = lineMax + lineFalloff;
                float finalMask = smoothstep(lineMax, lineMin, noiseVal);

                return float4(finalMask, finalMask, finalMask, 1.0f);
            }
            ENDCG
        }
    }
}
