//
//  Node.swift
//  RotateDemo
//
//  Created by cfq on 2016/10/31.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

// 创建三角形子类，继承于Node类
import Foundation
import Metal

class Triangle: Node {
  
  init(device: MTLDevice){
    
    let V0 = Vertex(x:  0.0, y:   1.0, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
    let V1 = Vertex(x: -1.0, y:  -1.0, z:   0.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0)
    let V2 = Vertex(x:  1.0, y:  -1.0, z:   0.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0)
    
    let verticesArray = [V0,V1,V2]
    // 这里的Triangle继承于刚刚创建的Node类，在构造函数里有三个关于三角形顶点的常量，最后打包为一个数组并传递给了父类的构造函数中。
    super.init(name: "Triangle", vertices: verticesArray, device: device)
  }
    
    override func updateWithDelta(delta: CFTimeInterval) {
        
        super.updateWithDelta(delta: delta)
        
        let secsPerMove: Float = 6.0
        rotationY = sinf( Float(time) * 2.0 * Float(M_PI) / secsPerMove)
        rotationX = sinf( Float(time) * 2.0 * Float(M_PI) / secsPerMove)
    }
  
}
