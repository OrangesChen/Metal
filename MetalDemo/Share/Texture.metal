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

struct VertexIn{
    packed_float3 position;
    packed_float4 color;
    packed_float2 st;
};

struct VertexOut{
    float4 position [[position]];  //1
    float4 color;
    float2 st;
};

struct Uniforms{
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
};

vertex VertexOut texture_vertex(
                              const device VertexIn* vertex_array [[ buffer(0) ]],
                              const device Uniforms&  uniforms    [[ buffer(1) ]],           //1
                              unsigned int vid [[ vertex_id ]]) {
    
    float4x4 mv_Matrix = uniforms.modelMatrix;                     //2
    float4x4 proj_Matrix = uniforms.projectionMatrix;
    
    VertexIn VertexIn = vertex_array[vid];
    
    VertexOut VertexOut;
    VertexOut.position = proj_Matrix * mv_Matrix * float4(VertexIn.position,1);  //3
    VertexOut.color = VertexIn.color;
    VertexOut.st = VertexIn.st;
    return VertexOut;
}

fragment float4 texture_fragment(VertexOut frag [[stage_in]], texture2d<float> texas[[texture(0)]]) {  //1
    constexpr sampler defaultSampler;
    float4 rgba = texas.sample(defaultSampler, frag.st).rgba;
    return rgba;
}

