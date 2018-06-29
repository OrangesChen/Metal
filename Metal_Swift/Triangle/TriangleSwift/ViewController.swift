//
//  ViewController.swift
//  TriangleSwift
//
//  Created by cfq on 2016/10/26.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

/*
  七个步骤来设置metal：
 
  1、创建一个MTLDevice
  2、创建一个CAMetalLayer
  3、创建一个Vertex Buffer
  4、创建一个Vertex Shader
  5、创建一个Fragment Shader
  6、创建一个Render Pipeline
  7、创建一个Command Queue
 
 */

import UIKit
import Metal
import QuartzCore

class ViewController: UIViewController {

    // 1、创建一个MTLDevice, 你可以把一个MTLDevice想象成是你和CPU的直接连接。你将通过使用MTLDevice创建所有其他你需要的Metal对象（像是command queues，buffers，textures）。
    var device: MTLDevice! = nil
    // 2、创建一个CAMetalLayer
    var metalLayer: CAMetalLayer! = nil
    // 3、创建一个Vertex Buffer
    var vertexBuffer: MTLBuffer! = nil
    var colorBuffer: MTLBuffer! = nil
    var indexBuffer: MTLBuffer! = nil
    // 6、创建一个Render Pipeline
    var pipelineState: MTLRenderPipelineState! = nil
    // 7、创建一个Command Queue
    var commandQueue: MTLCommandQueue! = nil
    // 8、创建一个Display Link
    var timer: CADisplayLink! = nil
    var quaTexture: MTLTexture! = nil
    
    // 3.1 在CPU创建一个浮点数数组，需要通过把它移动到一个MTLBuffer，来发送这些数据到GPU。
    let vertexData:[Float] = [
//         0.0,  1.0, 0.0,
//        -1.0, -1.0, 0.0,
//         1.0, -1.0, 0.0
        //position      s, t
//        -0.5, -0.5, 0,  0, 0,
//         0.5, -0.5, 0,  1, 0,
//         0.5,  0.5, 0,  1, 1,
//        -0.5,  0.5, 0,  0, 1,
        
        -0.5, -0.5, 0,  0, 1,
         0.5, -0.5, 0,  1, 1,
         0.5,  0.5, 0,  1, 0,
        -0.5,  0.5, 0,  0, 0,
    ]
    
    let indices:[Int32] = [
        0, 1, 2,
        2, 3, 0
    ]
    
    let vertexColorData:[Float] = [
        0.0,  1.0, 0.0, 1.0,
        1.0,  1.0, 0.0, 1.0,
        1.0,  0.0, 1.0, 1.0,
        1.0,  1.0, 0.0, 1.0,
        1.0,  0.0, 1.0, 1.0,
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // 1.1 获取一个MTLDevice的引用
        device = MTLCreateSystemDefaultDevice()
        // 2.1 创建CAMetalLayer
        metalLayer = CAMetalLayer()
        // 2.2 必须明确layer使用的MTLDevice，简单地设置早前获取的device
        metalLayer.device = device
        // 2.3 把像素格式（pixel format）设置为BGRA8Unorm，它代表"8字节代表蓝色、绿色、红色和透明度，通过在0到1之间单位化的值来表示"。这次两种用在CAMetalLayer的像素格式之一，一般情况下你这样写就可以了。
        metalLayer.pixelFormat = .bgra8Unorm
        // 2.4 苹果鼓励将framebufferOnly设置为true，来增强表现效率。除非你需要对从layer生成的纹理（textures）取样，或者你需要在layer绘图纹理(drawable textures)激活一些计算内核，否则你不需要设置。（大部分情况下你不用设置）
        metalLayer.framebufferOnly = true
        // 2.5 把layer的frame设置为view的frame
        metalLayer.frame = view.layer.frame
        var drawableSize = self.view.bounds.size
        drawableSize.width *= self.view.contentScaleFactor
        drawableSize.height *= self.view.contentScaleFactor
        metalLayer.drawableSize = drawableSize
        //把layer作为view.layer下的子layer添加
        view.layer.addSublayer(metalLayer)
        
        // 3.2 获取vertex data的字节大小。你通过把元素的大小和数组元素个数相乘来得到
        let dataSize = vertexData.count * 4
        // 3.3 在GPU创建一个新的buffer，从CPU里输送data
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: MTLResourceOptions(rawValue: UInt(0)))
        // 存放Vertex数组的标志
        vertexBuffer.label = "Vertices"
        
        indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * 4, options: MTLResourceOptions(rawValue: UInt(0)))
        indexBuffer.label = "Indices"

//        colorBuffer = device.makeBuffer(bytes: vertexColorData, length: vertexColorData.count * 4, options: MTLResourceOptions(rawValue: UInt(0)))
//        colorBuffer.label = "Color"

        // 6.1 通过调用device.newDefaultLibrary方法获得的MTLibrary对象访问到你项目中的预编译shaders,然后通过名字检索每个shader
        let defaultLibrary = device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary?.makeFunction(name: "texture_fragment")
        let vertextProgram = defaultLibrary?.makeFunction(name: "texture_vertex")
        
        // 6.2 这里设置你的render pipeline。它包含你想要使用的shaders、颜色附件（color attachment）的像素格式(pixel format)。（例如：你渲染到的输入缓冲区，也就是CAMetalLayer）
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertextProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // 6.3 把这个 pipeline 配置编译到一个 pipeline 状态(state)中，让它使用起来有效率。
//        var pipelineError: NSError?
        do {
       try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            print("Fail to create pipeline state")
        }
        
        
        // 加载纹理
        // 1 使用Metal
        let loaded = loadIntoTextureWithDevice(device: device, name: "lena", ext: "png")
        if !loaded {
            print("Failed to load texture")
        }
        quaTexture = texture
        
        // 2 使用MetalKit
//        do {
//            quaTexture = try makeTexture(device: device, name: "IMG_2307.PNG")
//        } catch {
//            fatalError("Error: Can not load texture")
//        }
        
        // 7.1 初始化commandQueue
        commandQueue = device.makeCommandQueue()
        
        // 8.1 初始化 timer，设置timer，让它每次刷新屏幕的时候调用一个名叫drawloop的方法
        timer = CADisplayLink(target: self, selector: #selector(ViewController.drawloop))
        timer.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        
    }

    // 渲染三角形
    /*
            五个步骤
     1、创建一个Display link。
     2、创建一个Render Pass Descriptor
     3、创建一个Command Buffer
     4、创建一个Render Command Encoder
     5、提交你Command Buffer的内容。
    */
    func render() {
        // metal layer上调用nextDrawable() ，它会返回你需要绘制到屏幕上的纹理(texture)
        let drawable = metalLayer.nextDrawable()
        
        // 8、创建一个Render Pass Descriptor，配置什么纹理会被渲染到、clear color，以及其他的配置
        let renderPassDesciptor = MTLRenderPassDescriptor()
        renderPassDesciptor.colorAttachments[0].texture = drawable?.texture
        // 设置load action为clear，也就是说在绘制之前，把纹理清空
        renderPassDesciptor.colorAttachments[0].loadAction = .clear
        // 绘制的背景颜色设置为绿色
        renderPassDesciptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.8, 0.5, 1.0)
        
        // 9、创建一个Command Buffer
        // 你可以把它想象为一系列这一帧想要执行的渲染命令。注意在你提交command buffer之前，没有事情会真正发生，这样给你对事物在何时发生有一个很好的控制。
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        // 10、创建一个渲染命令编码器(Render Command Encoder)
        // 创建一个command encoder，并指定你之前创建的pipeline和顶点
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesciptor)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
//        renderEncoder.setVertexBuffer(colorBuffer, offset: 0, at: 1);
        renderEncoder.setFragmentTexture(quaTexture, at: 0)
        // 根据索引画图
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
       
        /**
         绘制图形
         - parameter type:          画三角形
         - parameter vertexStart:   从vertex buffer 下标为0的顶点开始
         - parameter vertexCount:   顶点数
         - parameter instanceCount: 总共有1个三角形
         */
        //        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        // 完成后，调用endEncoding()
        renderEncoder.endEncoding()
        
        // 保证新纹理会在绘制完成后立即出现
        commandBuffer.present(drawable!)
        // 提交事务(transaction), 把任务交给GPU
        commandBuffer.commit()
    }
    
    func drawloop() {
        self.render()
       
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

