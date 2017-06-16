// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Clothe/Normal AO Shadow" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_ShadowCol("ShadowCol", Float) = 1.0
		_MainTex ("Main Tex", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_AOTex ("AOTex", 2D) = "white" {}
		_BumpScale ("Bump Scale", Float) = 1.0
		_Contrast("Contrast", Range(0, 3)) = 1
		_AOContrast("AO Contrast", Range(-3, 3)) = 0.5
		//_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(0, 1)) = 1
	}
	SubShader {
		Tags{ "RenderType" = "Opaque" }
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			Cull Off
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _AOTex_ST;
			sampler2D _BumpMap;
			sampler2D _AOTex;
			float4 _BumpMap_ST;
			float _BumpScale;
			//fixed4 _Specular;
			float _ShadowCol;
			float _Gloss;
			float _Contrast;
			float _AOContrast;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				//LIGHTING_COORDS(3, 4)
				SHADOW_COORDS(3)
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 lightDir: TEXCOORD1;
				float3 viewDir : TEXCOORD2;
				float4 uv1 : TEXCOORD3;
				//LIGHTING_COORDS(5, 6)
				SHADOW_COORDS(4)
			};

			// Unity doesn't support the 'inverse' function in native shader
			// so we write one by our own
			// Note: this function is just a demonstration, not too confident on the math or the speed
			// Reference: http://answers.unity3d.com/questions/218333/shader-inversefloat4x4-function.html
			float4x4 inverse(float4x4 input) {
				#define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))
				
				float4x4 cofactors = float4x4(
				     minor(_22_23_24, _32_33_34, _42_43_44), 
				    -minor(_21_23_24, _31_33_34, _41_43_44),
				     minor(_21_22_24, _31_32_34, _41_42_44),
				    -minor(_21_22_23, _31_32_33, _41_42_43),
				    
				    -minor(_12_13_14, _32_33_34, _42_43_44),
				     minor(_11_13_14, _31_33_34, _41_43_44),
				    -minor(_11_12_14, _31_32_34, _41_42_44),
				     minor(_11_12_13, _31_32_33, _41_42_43),
				    
				     minor(_12_13_14, _22_23_24, _42_43_44),
				    -minor(_11_13_14, _21_23_24, _41_43_44),
				     minor(_11_12_14, _21_22_24, _41_42_44),
				    -minor(_11_12_13, _21_22_23, _41_42_43),
				    
				    -minor(_12_13_14, _22_23_24, _32_33_34),
				     minor(_11_13_14, _21_23_24, _31_33_34),
				    -minor(_11_12_14, _21_22_24, _31_32_34),
				     minor(_11_12_13, _21_22_23, _31_32_33)
				);
				#undef minor
				return transpose(cofactors) / determinant(input);
			}

			v2f vert(a2v v) {
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				o.uv1.xy = v.texcoord.xy * _AOTex_ST.xy + _AOTex_ST.zw;
				///
				/// Note that the code below can handle both uniform and non-uniform scales
				///

				// Construct a matrix that transforms a point/vector from tangent space to world space
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 

				float4x4 tangentToWorld = float4x4(worldTangent.x, worldBinormal.x, worldNormal.x, 0.0,
												   worldTangent.y, worldBinormal.y, worldNormal.y, 0.0,
												   worldTangent.z, worldBinormal.z, worldNormal.z, 0.0,
												   0.0, 0.0, 0.0, 1.0);
				// The matrix that transforms from world space to tangent space is inverse of tangentToWorld
				float3x3 worldToTangent = inverse(tangentToWorld);

				// Transform the light and view dir from world space to tangent space
				o.lightDir = mul(worldToTangent, WorldSpaceLightDir(v.vertex));
				o.viewDir = mul(worldToTangent, WorldSpaceViewDir(v.vertex));

				///
				/// Note that the code below can only handle uniform scales, not including non-uniform scales
				/// 

				// Compute the binormal
//				float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w;
//				// Construct a matrix which transform vectors from object space to tangent space
//				float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
				// Or just use the built-in macro
//				TANGENT_SPACE_ROTATION;
//				
//				// Transform the light direction from object space to tangent space
//				o.lightDir = mul(rotation, normalize(ObjSpaceLightDir(v.vertex))).xyz;
//				// Transform the view direction from object space to tangent space
//				o.viewDir = mul(rotation, normalize(ObjSpaceViewDir(v.vertex))).xyz;

				//TRANSFER_VERTEX_TO_FRAGMENT(o);
				TRANSFER_SHADOW(o);
				return o;
			}

			//参数inColor一般是指贴图原来的颜色
			inline fixed4 GetGray(fixed4 inColor)
			{
				return dot(inColor, fixed4(0.3, 0.6, 0.1, 1.0));

			}
			//灰度公式是Gray = R*0.299 + G*0.587 + B*0.114。使用dot的方法可以只使用一个指令就完成计算

			//_Contrast——控制对比度的权
			inline fixed4 GetContrast(fixed4 inColor)
			{
				return (inColor + (inColor -0.5) * _AOContrast);
			}

			//inline fixed4 GetSaturation(fixed4 inColor)
			//{
			//	fixed average = (inColor.r + inColor.g + inColor.b) / 3;
			//	inColor.rgb += (inColor.rgb - average) * _AOContrast;
			//	return inColor;
			//}
			
			fixed4 frag(v2f i) : SV_Target {				
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);
				
				// Get the texel in the normal map
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				fixed3 tangentNormal;
				// If the texture is not marked as "Normal map"
//				tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
//				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				
				// Or mark the texture as "Normal map", and use the built-in funciton
				tangentNormal = UnpackNormal(packedNormal);
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				fixed4 lightCol = tex2D(_AOTex, i.uv1);
				lightCol = GetContrast(lightCol);
				
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb*lightCol;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 lc = _LightColor0.rgb;
				fixed3 diffuse = lc * albedo * max(0, dot(tangentNormal, tangentLightDir));

				//fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				//fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				//float4 diffuseTerm = _LightColor0 * LIGHT_ATTENUATION(i);
				
				float attenuation = SHADOW_ATTENUATION(i);
				
				fixed4 finalColor = fixed4((ambient + diffuse), 1.0);

				return lerp(finalColor*_Gloss, finalColor, attenuation);
				//return fixed4(lightCol,1.0);
			}

			ENDCG
		}

		Pass
        {
            Name "ShadowCollector"
            Tags { "LightMode" = "ShadowCollector" }
            
            Fog {Mode Off}
            ZWrite On ZTest LEqual

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcollector

            #define SHADOW_COLLECTOR_PASS
            #include "UnityCG.cginc"

            struct appdata { float4 vertex : POSITION;};
            struct v2f { V2F_SHADOW_COLLECTOR;};

            v2f vert (appdata v)
            {
                v2f o;
                TRANSFER_SHADOW_COLLECTOR(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target { SHADOW_COLLECTOR_FRAGMENT(i)}
            ENDCG
        }
        
	} 
	FallBack "Bumped Diffuse"
}
