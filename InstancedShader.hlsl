#if OPENGL
#define SV_POSITION POSITION
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_1
#endif


#define MAXLIGHT 20


float3 PointLightPosition[MAXLIGHT];
float4 PointLightColor[MAXLIGHT];
float PointLightIntensity[MAXLIGHT];
float PointLightRadius[MAXLIGHT];
int MaxLightsRendered = 0;

float4 CalcDiffuseLight(float3 normal, float3 lightDirection, float4 lightColor, float lightIntensity)
{

    return saturate(dot(normal, -lightDirection)) * lightIntensity * lightColor;
}

float4 CalcSpecularLight(float3 normal, float3 lightDirection, float3 cameraDirection, float4 lightColor, float lightIntensity)
{
    float3 halfVector = normalize(-lightDirection + -cameraDirection);
    float specular = saturate(dot(halfVector, normal));

    float specularPower = 20;

    return lightIntensity * lightColor * pow(abs(specular), specularPower);
}

float lengthSquared(float3 v1)
{
    return v1.x * v1.x + v1.y * v1.y + v1.z * v1.z;
}

float3 CameraPosition;
float3 SunLightDirection;
float4 SunLightColor;
float SunLightIntensity;

float3 FogColor;
    float FogEnabled;
    float FogAmount;

float4x4 View;
float4x4 Projection;
//  1 means we should only accept non-transparent pixels.
// -1 means only accept transparent pixels.
float alphaTestDirection = 1.0f;
float alphaTestThreshold = 0.95f;



struct VS_MODEL_ShaderInput
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : NORMAL;
    float4 Color: COLOR0;
};
struct VertexShaderOutput
{
    float4 Position : POSITION;
    float3 Normal : TEXCOORD1;
    float2 TexCoord : TEXCOORD0;
      float4 WorldPosition : COLOR1;
    float4 Color : COLOR0;
    float2 Fog: TEXCOORD2;
};

Texture2D Texture;
sampler textureSampler = sampler_state
{
    Texture = <Texture>;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = Point;
    MaxAnisotropy = 16;
};


float ComputeFogFactor(float4 position, float4 fogVector)
{
    return saturate(dot(position, fogVector));
}


float4 ApplyFog(float4 color, float fogFactor)
{
   // fogFactor = 1.0f;
   if(FogEnabled < 1.0f)
   {
    return color;
   }
    color.rgb = lerp(color.rgb, FogColor * color.a, fogFactor) * FogEnabled;
    return color;
}
/// <summary>
/// Sets a vector which can be dotted with the object space vertex position to compute fog amount.
/// </summary>
float4  SetFogVector(float4 worldView, float fogStart, float fogEnd)
{
    float4 fogVector;
    if (fogStart == fogEnd)
    {
        // Degenerate case: force everything to 100% fogged if start and end are the same.
        fogVector = float4(0, 0, 0, 1);
    }
    else
    {
        // We want to transform vertex positions into view space, take the resulting
        // Z value, then scale and offset according to the fog start/end distances.
        // Because we only care about the Z component, the shader can do all this
        // with a single dot product, using only the Z row of the world+view matrix.
        
        float scale = 1.0f / (fogStart - fogEnd);

        fogVector.x = worldView.x * scale;
        fogVector.y = worldView.y * scale;
        fogVector.z = worldView.z * scale;
        fogVector.w = (worldView.w + fogStart) * scale;
    }

    return fogVector;
}
VertexShaderOutput VertexShaderCommon(VS_MODEL_ShaderInput input, float4x4 instanceTransform)
{
    VertexShaderOutput output;

    // Apply the world and camera matrices to compute the output position.
     output.WorldPosition= mul(input.Position, instanceTransform);
    float4 viewPosition = mul( output.WorldPosition, View);
    output.Position = mul(viewPosition, Projection);



  output.TexCoord = input.TexCoord;

    output.Normal= mul(input.Normal, instanceTransform);

     float4 fogVector = SetFogVector(viewPosition,0.0f, FogAmount);
    output.Fog = float2(ComputeFogFactor(  output.WorldPosition, fogVector),1.0f);

     output.Color = input.Color;
    // Copy across the input texture coordinate.
  
    return output;
}

VertexShaderOutput Model_InstancingVS(VS_MODEL_ShaderInput input, float4x4 instanceTransform : BLENDWEIGHT)
{
    return VertexShaderCommon(input,transpose(instanceTransform));


}

float4 LightingPS(VertexShaderOutput input) : COLOR0
{
 float4 outColor = tex2D(textureSampler, input.TexCoord) * input.Color;

    clip((outColor.a - alphaTestThreshold) * alphaTestDirection);

    
 float4 diffuseLight = float4(0.5, 0.5, 0.5, 1.0);
    float4 specularLight = float4(0, 0, 0, 0);
    ////calculate our pointLights

    float3 cameraDirection = normalize((float3) input.WorldPosition - CameraPosition);
    diffuseLight += CalcDiffuseLight(input.Normal, SunLightDirection, SunLightColor, SunLightIntensity);
    specularLight += CalcSpecularLight(input.Normal, SunLightDirection, cameraDirection, SunLightColor, SunLightIntensity);

    [loop]
    for (int i = 0; i < MaxLightsRendered; i++) 
    {
        float3 PointLightDirection = (float3) input.WorldPosition - PointLightPosition[i] ;
        float DistanceSq = lengthSquared(PointLightDirection);
        float radius = PointLightRadius[i];
        [branch]
        if (DistanceSq < abs(radius * radius))
        {
            float Distance = sqrt(DistanceSq);

            PointLightDirection /= Distance;

            float du = Distance / (1.0 - DistanceSq / (radius * radius - 1));

            float denom = du / abs(radius) + 1.0;

            //The attenuation is the falloff of the light depending on distance basically
            float attenuation = 1.0 / (denom * denom);

            diffuseLight += CalcDiffuseLight(input.Normal, PointLightDirection, PointLightColor[i], PointLightIntensity[i]) * attenuation;
            
           specularLight += CalcSpecularLight(input.Normal, PointLightDirection, cameraDirection, PointLightColor[i], PointLightIntensity[i]) * attenuation;
        }
    }

float4 result = outColor  ;


result = ApplyFog(result, input.Fog.x) * (diffuseLight + specularLight);
return result;
return min(result, outColor);

}
float4 NormalPS(VertexShaderOutput input) : COLOR0
{

    return tex2D(textureSampler, input.TexCoord);

}


technique LightingModelInstancing
{
    pass P0
    {
        VertexShader = compile vs_3_0 Model_InstancingVS();
        PixelShader = compile PS_SHADERMODEL LightingPS();
    }
};

technique ModelInstancing
{
    pass P0
    {
        VertexShader = compile vs_3_0 Model_InstancingVS();
        PixelShader = compile PS_SHADERMODEL NormalPS();
    }
};


