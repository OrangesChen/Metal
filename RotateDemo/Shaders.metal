//
//  ViewController.swift
//  RotateDemo
//
//  Created by cfq on 2016/10/31.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//


#include <metal_stdlib>
using namespace metal;

struct VertexIn{
    packed_float3 position;
    packed_float4 color;
};

struct VertexOut{
    //必须区分 (通过使用 [[position]] 属性) 哪一个结构体成员应该被看做是顶点位置:
    float4 position [[position]];
    float4 color;
};

struct Uniforms{
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
};

/**
 *  顶点函数
 *
 *  @param  vertex_array 在顶点数据中每个顶点被执行一次。它接收顶点列表的一个指针
 *  @param  uniforms 一个包含旋转矩阵的统一数据的引用
 *  @param  vid 一个索引，用来告诉函数当前操作的是哪个顶点
 *  @return VertexOut
 */

// 注意顶点函数的参数后面紧跟着标明它们用途的属性。在缓冲区参数中，参数中的索引对应着我们在渲染命令编码器中设置缓冲区时指定的索引。Metal 就是这样来区分哪个参数对应哪个缓冲区
vertex VertexOut basic_vertex(
                              const device VertexIn* vertex_array [[ buffer(0) ]],
                              const device Uniforms&  uniforms    [[ buffer(1) ]],
                              unsigned int vid [[ vertex_id ]]) {
    
    float4x4 mv_Matrix = uniforms.modelMatrix;
    float4x4 proj_Matrix = uniforms.projectionMatrix;
    
    VertexIn VertexIn = vertex_array[vid];
    
    VertexOut VertexOut;
    VertexOut.position = proj_Matrix * mv_Matrix * float4(VertexIn.position,1);
    // 顶点颜色则从输入参数中直接复制
    VertexOut.color = VertexIn.color;
    
    return VertexOut;
}

fragment half4 basic_fragment(VertexOut frag [[stage_in]]) {  //1
    return half4(frag.color[0], frag.color[1], frag.color[2], frag.color[3]); //2
}
