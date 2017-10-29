Shader "Custom/VertexDisplacement" {
Properties 
		{
		_Color ("Main Color", Color) = (1,1,1,1)
		_RampTex ("Color Ramp", 2D) = "white" {}
		_DispTex ("Displacement Texture", 2D) = "gray" {}
		_Displacement ("Displacement", Range(0, 20.0)) = 0.1
		_ChannelFactor ("ChannelFactor (r,g,b)", Vector) = (1,0,0)
		_Range ("Range (min,max)", Vector) = (0,0.5,0)
		_ClipRange ("ClipRange [0,1]", float) = 0.8
		_Tess ("Tessellation", Range(1,32)) = 4
		}

SubShader 
{
		Tags {
		"RenderType"="Opaque"  "Queue"="Geometry"
			} 
			LOD 300
		Pass {
			Name "FORWARD"
			Tags {
			"LightMode"="ForwardBase"
			}
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma vertex vert
		#pragma fragment frag
		#pragma tessellate:tessDistance
	
		#define UNITY_PASS_FORWARDBASE
		#include "UnityCG.cginc"
		#include "AutoLight.cginc"
		#include "Lighting.cginc"
		#include "Tessellation.cginc"

		#pragma multi_compile_fwdbase_fullshadows
		#pragma multi_compile_fog
		#pragma target 4.6
		float4 _Color;
		sampler2D _DispTex;
		float4 _DispTex_ST;
		sampler2D _RampTex;
		float4 _RampTex_ST;
		float _Displacement;
		float3 _ChannelFactor;
		float2 _Range;
		float _ClipRange;
		float _Tess;

		struct VertexInput {
		float4 vertex : POSITION;       //local vertex position
		float3 normal : NORMAL;         //normal direction
		float4 tangent : TANGENT;       //tangent direction    
		float2 texcoord0 : TEXCOORD0;   //uv coordinates
		float2 texcoord1 : TEXCOORD1;   //lightmap uv coordinates
		};

		struct VertexOutput {
		float4 pos : SV_POSITION;              //screen clip space position and depth
		float2 uv0 : TEXCOORD0;                //uv coordinates
		float2 uv1 : TEXCOORD1;                //lightmap uv coordinates

		//below we create our own variables with the texcoord semantic. 
		float3 normalDir : TEXCOORD3;          //normal direction   
		float3 posWorld : TEXCOORD4;          //normal direction   
		LIGHTING_COORDS(7,8)                   //this initializes the unity lighting and shadow
		UNITY_FOG_COORDS(9)                    //this initializes the unity fog
		};

		VertexOutput vert (VertexInput v) {
			VertexOutput o = (VertexOutput)0;           
			o.uv0 = v.texcoord0;
			o.uv1 = v.texcoord1;
			o.normalDir = UnityObjectToWorldNormal(v.normal);
			UNITY_TRANSFER_FOG(o,o.pos);
			TRANSFER_VERTEX_TO_FRAGMENT(o)
			float3 dcolor = tex2Dlod (_DispTex, float4(o.uv0 * _DispTex_ST.xy,0,0));
			float d = (dcolor.r*_ChannelFactor.r + dcolor.g*_ChannelFactor.g + dcolor.b*_ChannelFactor.b);
			v.vertex.xyz += v.normal * d * _Displacement;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.posWorld = mul(unity_ObjectToWorld, v.vertex);
			return o;
		}

       float4 tessDistance (VertexInput v0, VertexInput v1, VertexInput v2) {
                float minDist = 10.0;
                float maxDist = 25.0;
                return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
        }

		float4 frag(VertexOutput i) : COLOR {
		 
			 //normal direction calculations
			 half3 normalDirection = normalize(i.normalDir);
			 
			 //diffuse color calculations
			 float3 dcolor = tex2D (_DispTex, TRANSFORM_TEX(i.uv0,_DispTex));
			 float d = (dcolor.r*_ChannelFactor.r + dcolor.g*_ChannelFactor.g + dcolor.b*_ChannelFactor.b) * (_Range.y-_Range.x) + _Range.x;
			 clip (_ClipRange-d);
			 half4 c = tex2D (_RampTex, float2(d,0.5));
			 float3 diffuseColor = c.rgb *_Color.rgb;
			 
			 //light calculations
			 float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
			 float NdotL = max(0.0, dot( normalDirection, lightDirection ));
			 //Specular calculations
			 float3 lightingModel = pow(NdotL * 0.5 + 0.5,2) * diffuseColor;
			 float attenuation = LIGHT_ATTENUATION(i);
			 float3 attenColor = attenuation * _LightColor0.rgb;
			 float4 finalDiffuse = float4(lightingModel * attenColor,1);
			 UNITY_APPLY_FOG(i.fogCoord, finalDiffuse);
			 return finalDiffuse;
		 }
		 ENDCG
		 }
	 }
	 FallBack "Diffuse"
 }