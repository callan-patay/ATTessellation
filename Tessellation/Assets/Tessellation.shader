Shader "Custom/Tessellation" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_DispTex ("Disp Texture", 2D) = "gray" {}
		_NormalMap("Normalmap", 2D) = "bump" {}
		_Displacement("Displacement", Range(0, 5.0)) = 0.3
		_Tess ("Tessellation", Range(1, 100)) = 4
		_SpecColor("Spec color", color) = (0.5, 0.5, 0.5, 0.5)
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 300
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:disp tessellate:tessFixed nolightmap

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
		#include "Tessellation.cginc"

		struct appdata {
			float4 vertex: POSITION;
			float4 tangent: TANGENT;
			float3 normal: NORMAL;
			float2 texcoord: TEXCOORD0;

		};


		float _Tess;

		float4 tessFixed()
		{
			return _Tess;

		}

		float4 tessDistance (appdata v0, appdata v1, appdata v2)
		{
			float minDistance = 10.0;
			float maxDist = 25.0;
			return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDistance, maxDist, _Tess);
		}

		sampler2D _DispTex;
		float _Displacement;

		void disp (inout appdata v)
		{
			float d = tex2Dlod(_DispTex, float4(v.texcoord.xy,0,0)).r * _Displacement;
			v.vertex.xyz += v.normal * d;

		}

		struct Input {
			float2 uv_MainTex;
		};

		sampler2D _MainTex;
		sampler2D _NormalMap;
		fixed4 _Color;


		void surf (Input IN, inout SurfaceOutput o) {
			// Albedo comes from a texture tinted by color
			half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Specular = 0.2;
			o.Gloss = 1.0;
			o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
		}
		ENDCG
	}
	FallBack "Diffuse"
}
