//
//  Texture.metal
//  RotateDemo
//
//  Created by cfq on 2016/11/1.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

// 添加纹理

#include <metal_stdlib>
using namespace metal;

#define YUV_SHADER_ARGS  VertexOut      inFrag    [[ stage_in ]],\
texture2d<float>  lumaTex     [[ texture(0) ]],\
texture2d<float>  chromaTex     [[ texture(1) ]],\
sampler bilinear [[ sampler(0) ]], \
 constant ColorParameters *colorParameters [[ buffer(0) ]]

struct VertexIn{
    packed_float3 position;
    packed_float2 st;
};

struct VertexOut{
    float4 position [[position]];  //1
    float2 st;
};

struct ColorParameters
{
    float3x3 yuvToRGB;
};

vertex VertexOut texture_vertex(
                              const device VertexIn* vertex_array [[ buffer(0) ]],           //1
                              unsigned int vid [[ vertex_id ]]) {
    
    
    VertexIn VertexIn = vertex_array[vid];
    
    VertexOut VertexOut;
    VertexOut.position = float4(VertexIn.position,1);  //3
    VertexOut.st = VertexIn.st;
    return VertexOut;
}

fragment float4 texture_fragment(VertexOut frag [[stage_in]], texture2d<float> texas[[texture(0)]]) {  //1
    constexpr sampler defaultSampler;
    float4 rgba = texas.sample(defaultSampler, frag.st).rgba;
    return rgba;
}

fragment half4 yuv_rgb(YUV_SHADER_ARGS)
{
    float3 yuv;
    yuv.x = lumaTex.sample(bilinear, inFrag.st).r;
    yuv.yz = chromaTex.sample(bilinear,inFrag.st).rg - float2(0.5);
    return half4(half3(colorParameters->yuvToRGB * yuv),yuv.x);
}
