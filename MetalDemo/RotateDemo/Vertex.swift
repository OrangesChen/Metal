//
//  Vertex.swift
//  RotateDemo
//
//  Created by cfq on 2016/10/31.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

// 创建顶点结构

/**
 *  这个结构体会存储每一个顶点的颜色信息和位置信息。其中floatBuffer()方法会按照规定的顺序返回一个float型数组，
    其中包含的是结构体的位置和颜色的信息。
 */

struct Vertex {
    var x, y, z: Float // position data
    var r, g, b, a: Float // color data
    
    func floatBuffer() -> [Float] {
        return [x, y, z, r, g, b, a]
    }
}
