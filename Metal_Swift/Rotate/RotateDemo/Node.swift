//
//  Node.swift
//  RotateDemo
//
//  Created by cfq on 2016/10/31.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

import Foundation
import Metal
import QuartzCore

class Node {
    
    var time:CFTimeInterval = 0.0
    
    let name: String
    var vertexCount: Int
    var vertexBuffer: MTLBuffer
    var uniformBuffer: MTLBuffer?
    var device: MTLDevice
    
    var positionX:Float = 0.0
    var positionY:Float = 0.0
    var positionZ:Float = 0.0
    
    var rotationX:Float = 0.0
    var rotationY:Float = 0.0
    var rotationZ:Float = 0.0
    var scale:Float     = 0.8
    
    init(name: String, vertices: Array<Vertex>, device: MTLDevice){
        // 1  遍历每个顶点并将其序列化为一堆float数据放在一个buffer中
        var vertexData = Array<Float>()
        for vertex in vertices{
            vertexData += vertex.floatBuffer()
        }
        
        // 2 用上面的buffer中的数据来创建一个新的顶点buffer
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
        vertexBuffer.label = "Vertex"
        
        // 3 为实例中的各变量赋值
        self.name = name
        self.device = device
        vertexCount = vertices.count
    }
    
    /* 将数据存放在顶点buffer中
     * @param name       绘制的图形
     * @param vertices   顶点数据
     * @param device     设备
     *
     */
    init(name: String, vertices: Array<TexVertex>, device: MTLDevice){
        // 1  遍历每个顶点并将其序列化为一堆float数据放在一个buffer中
        var vertexData = Array<Float>()
        for vertex in vertices{
            vertexData += vertex.floatBuffer()
        }
        
        // 2 用上面的buffer中的数据来创建一个新的顶点buffer
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
        vertexBuffer.label = "Vertex"
        
        // 3 为实例中的各变量赋值
        self.name = name
        self.device = device
        vertexCount = vertices.count
    }
    
    // 渲染配置
    func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: Matrix4, projectionMatrix: Matrix4, clearColor: MTLClearColor?){
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
//        renderPassDescriptor.colorAttachments[0].storeAction = .store
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
        // 2  向设备申请一个内存区作为Buffer并共享给CPU和GPU
        uniformBuffer =  device.makeBuffer(length: MemoryLayout<Float>.size * Matrix4.numberOfElements() * 2, options: [])
        // 3 生成Buffer区的初始指针(类似于OC中的void *)
        let bufferPointer = uniformBuffer?.contents()
        // 4 将矩阵中的数据拷贝进Buffer
        memcpy(bufferPointer!, nodeModelMatrix.raw(), MemoryLayout<Float>.size*Matrix4.numberOfElements())
        memcpy(bufferPointer! + MemoryLayout<Float>.size*Matrix4.numberOfElements(), projectionMatrix.raw(), MemoryLayout<Float>.size*Matrix4.numberOfElements())
        // 5 将uniformBuffer传递给着色器(以及所指数据)，有点类似于把buffer传进特殊的顶点数据一样，只不过在这里索引atIndex的值是1而不是0
        renderEncoder.setVertexBuffer(self.uniformBuffer, offset: 0, at: 1)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func modelMatrix() -> Matrix4 {
        let matrix = Matrix4()
        matrix?.translate(positionX, y: positionY, z: positionZ)
        matrix?.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
        matrix?.scale(scale, y: scale, z: scale)
        return matrix!
    }
    
    func updateWithDelta(delta: CFTimeInterval){
        time += delta
    }
    
}

