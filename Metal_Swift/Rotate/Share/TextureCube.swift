//
//  TextureCube.swift
//  RotateDemo
//
//  Created by cfq on 2016/11/1.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//
import UIKit
import GLKit

class TextureCube: Node {
    var cubeTexture: MTLTexture!
    init(device: MTLDevice){
        let A = TexVertex(x: -1.0, y:   1.0, z:   1.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0, s: 0, t: 0)
        let B = TexVertex(x: -1.0, y:  -1.0, z:   1.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0, s: 1, t: 0)
        let C = TexVertex(x:  1.0, y:  -1.0, z:   1.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0, s: 0, t: 0)
        let D = TexVertex(x:  1.0, y:   1.0, z:   1.0, r:  0.1, g:  0.6, b:  0.4, a:  1.0, s: 1, t: 0)
        let Q = TexVertex(x: -1.0, y:   1.0, z:  -1.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0, s: 0, t: 1)
        let R = TexVertex(x:  1.0, y:   1.0, z:  -1.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0, s: 1, t: 1)
        let S = TexVertex(x: -1.0, y:  -1.0, z:  -1.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0, s: 1, t: 1)
        let T = TexVertex(x:  1.0, y:  -1.0, z:  -1.0, r:  0.1, g:  0.6, b:  0.4, a:  1.0, s: 0, t: 1)
        let E = TexVertex(x: -1.0, y:   1.0, z:  -1.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0, s: 0, t: 0)
        let F = TexVertex(x:  1.0, y:   1.0, z:  -1.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0, s: 1, t: 0)
        let G = TexVertex(x: -1.0, y:  -1.0, z:  -1.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0, s: 0, t: 1)
        let H = TexVertex(x:  1.0, y:  -1.0, z:  -1.0, r:  0.1, g:  0.6, b:  0.4, a:  1.0, s: 1, t: 1)

        let X = TexVertex(x: -1.0, y:   1.0, z:   1.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0, s: 0, t: 0)
        let Y = TexVertex(x: -1.0, y:  -1.0, z:   1.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0, s: 0, t: 1)
        let Z = TexVertex(x:  1.0, y:  -1.0, z:   1.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0, s: 1, t: 1)
        let W = TexVertex(x:  1.0, y:   1.0, z:   1.0, r:  0.1, g:  0.6, b:  0.4, a:  1.0, s: 1, t: 0)

        let verticesArray:Array<TexVertex> = [
            X,Y,Z ,X,Z,W,   //Front
            F,H,G ,E,F,G,   //Back
            
            Q,S,B ,Q,B,A,   //Left
            D,C,T ,D,T,R,   //Right
            
            Q,A,D ,Q,D,R,   //Top
            B,S,T ,B,T,C    //Bot
        ]
//
        super.init(name: "TextureCube", vertices: verticesArray, device: device)
    }
    
    override func updateWithDelta(delta: CFTimeInterval) {
        
        super.updateWithDelta(delta: delta)
        
//        let secsPerMove: Float = 1.0
//        rotationY = sinf( Float(time) * 2.0 * Float(M_PI) / secsPerMove)
//        rotationX = sinf( Float(time) * 2.0 * Float(M_PI) / secsPerMove)
    }
    
    // 渲染配置
    override func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: Matrix4, projectionMatrix: Matrix4, clearColor: MTLClearColor?){
        let renderPassDescriptor = MTLRenderPassDescriptor(clearColor: MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0), clearDepth: 1.0)
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        let commandBuffer = commandQueue.makeCommandBuffer()
        let renderEncoderOpt = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        let  renderEncoder = renderEncoderOpt
        //For now cull mode is used instead of depth buffer
        renderEncoder.setCullMode(MTLCullMode.front)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
        // 1 获取旋转矩阵
        let nodeModelMatrix = self.modelMatrix()
        nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
        // 2 向设备申请一个内存区作为Buffer并共享给CPU和GPU
        uniformBuffer =  device.makeBuffer(length: MemoryLayout<Float>.size * Matrix4.numberOfElements() * 2, options: [])
        // 3 生成Buffer区的初始指针(类似于OC中的void *)
        let bufferPointer = uniformBuffer?.contents()
        // 4 将矩阵中的数据拷贝进Buffer
        memcpy(bufferPointer!, nodeModelMatrix.raw(), MemoryLayout<Float>.size*Matrix4.numberOfElements())
        memcpy(bufferPointer! + MemoryLayout<Float>.size*Matrix4.numberOfElements(), projectionMatrix.raw(), MemoryLayout<Float>.size*Matrix4.numberOfElements())
        // 5 将uniformBuffer传递给着色器(以及所指数据)，有点类似于把buffer传进特殊的顶点数据一样，只不过在这里索引atIndex的值是1而不是0
        renderEncoder.setVertexBuffer(self.uniformBuffer, offset: 0, at: 1)
        // 设置片段着色器函数的纹理
        renderEncoder.setFragmentTexture(cubeTexture, at: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }


}
