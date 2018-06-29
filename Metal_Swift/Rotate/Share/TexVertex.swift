//
//  TexVertex.swift
//  RotateDemo
//
//  Created by cfq on 2016/11/1.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

struct TexVertex {
    var x, y, z: Float // position data
    var r, g, b, a: Float // color data
    var s, t: Float // texcoord data
    
    func floatBuffer() -> [Float] {
        return [x, y, z, r, g, b, a, s, t]
    }
}
