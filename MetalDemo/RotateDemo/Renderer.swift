//
//  Renderer.swift
//  RotateDemo
//
//  Created by cfq on 2016/11/1.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

import UIKit
import MetalKit
import QuartzCore
import simd

class Renderer: NSObject, MTKViewDelegate {

    var objectToDraw: TextureCube!
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    var projectionMatrix: Matrix4!
    var worldModelMatrix: Matrix4!
    var texture: MTLTexture!
    var moveBall: MoveBall!
    var drawable: CAMetalDrawable!
    var mView: MTKView!
    
    init(view: MTKView, device: MTLDevice) {
        super.init()
        let defalutLibrary = device.newDefaultLibrary()
        objectToDraw = TextureCube(device: device)
        do {
        texture = try makeTexture(device: device, name: "lena")
        } catch {
            fatalError("Error: Can not load texture")
        }
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor(view: view, library: defalutLibrary!, vertexShaderName:"texture_vertex" , fragmentShaderName: "texture_fragment", doIncludeDepthAttachment: false, vertexDescriptor: nil)
        
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch {
            print("Failed to create pipeline state, error")
        }
        drawable = view.currentDrawable
        commandQueue = device.makeCommandQueue()
        addRotation(view: view)
    }
    
    func addRotation(view: MTKView) {

        let right = UISwipeGestureRecognizer(target: self, action: #selector(Renderer.handleRotation(gesture:)))
        right.direction = .right
        view.addGestureRecognizer(right)
        
        let left = UISwipeGestureRecognizer(target: self, action: #selector(Renderer.handleRotation(gesture:)))
        left.direction = .left
        view.addGestureRecognizer(left)
        
        let up = UISwipeGestureRecognizer(target: self, action: #selector(Renderer.handleRotation(gesture:)))
        up.direction = .up
        view.addGestureRecognizer(up)
        
        let down = UISwipeGestureRecognizer(target: self, action: #selector(Renderer.handleRotation(gesture:)))
        down.direction = .down
        view.addGestureRecognizer(down)
        
    }
    
    func handleRotation(gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case UISwipeGestureRecognizerDirection.right:
            objectToDraw.rotationY += 20
            objectToDraw.updateWithDelta(delta: 0.5)
            break
        case UISwipeGestureRecognizerDirection.left:
            objectToDraw.rotationY -= 20
            objectToDraw.updateWithDelta(delta: 0.5)
            break
        case UISwipeGestureRecognizerDirection.up:
            objectToDraw.rotationX += 20
            objectToDraw.updateWithDelta(delta: 0.5)
            break
        case UISwipeGestureRecognizerDirection.down:
            objectToDraw.rotationX += 20
            objectToDraw.updateWithDelta(delta: 0.5)
            break
        default:
            break
        }
    }
    
    func render(view: MTKView) {
         mView = view
        projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 35), aspectRatio: Float(view.bounds.size.width / view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
        drawable = view.currentDrawable
        objectToDraw.cubeTexture = texture
        worldModelMatrix = Matrix4()
        worldModelMatrix?.translate(0.0, y: 0.0, z: -7.0)
//        worldModelMatrix?.rotateAroundX(Matrix4.degrees(toRad: Float(xDegree!)), y:Matrix4.degrees(toRad: Float(yDegree!)), z: 0.0)
        let color = MTLClearColorMake(0.0, 104.0/255.0, 5.0/255.0, 1.0)
        
        objectToDraw.render(commandQueue: commandQueue!, pipelineState: pipelineState!, drawable: drawable!, parentModelViewMatrix: worldModelMatrix!, projectionMatrix: projectionMatrix! ,clearColor: color)

    }
    

    /*!
     在MTKView的可绘制区域改变时会调用
     @method mtkView:drawableSizeWillChange:
     @abstract Called whenever the drawableSize of the view will change
     @discussion Delegate can recompute view and projection matricies or regenerate any buffers to be compatible with the new view size or resolution
     @param view MTKView which called this method
     @param size New drawable size in pixels
     */
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
     
    }
    
    /*!
     @method drawInMTKView:
     @abstract Called on the delegate when it is asked to render into the view
     @discussion Called on the delegate when it is asked to render into the view
     */
    public func draw(in view: MTKView){

//        objectToDraw.updateWithDelta(delta: 0.01)
        self.render(view: view)
    }
    
    func reshape(view: MTKView) {
        
        projectionMatrix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 35), aspectRatio: Float(view.bounds.size.width / view.bounds.size.height), nearZ: 200, farZ: 800)

    }
    
    
    
    
    
    
    

}
