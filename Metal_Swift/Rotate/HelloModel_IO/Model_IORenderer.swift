//
//  Model_IORenderer.swift
//  RotateDemo
//
//  Created by cfq on 2016/11/3.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

import MetalKit
import GLKit

class Model_IORenderer: NSObject, MTKViewDelegate {

    var camera: DvrCamera!

    // cube model
    var cubeModel: DvrCube!
    var cubeModelTexture: MTLTexture!
    var cubeModelPipelineState: MTLRenderPipelineState!

    var frontTexture: MTLTexture!
    var backTexture: MTLTexture!
    
    // cone 
    var coneModel: DvrCone
    var coneTexture: MTLTexture!
    var conePipelineState: MTLRenderPipelineState!

    // plane
    var renderPlane: DvrPlane!
    var renderPlaneTexture: MTLTexture!
    var renderPlanePipelineState: MTLRenderPipelineState!
    
    var depthStencilState: MTLDepthStencilState!

    var commandQueue: MTLCommandQueue!

    init(view: MTKView, device: MTLDevice) {

        let library = device.newDefaultLibrary()

        camera = DvrCamera(location:GLKVector3(v:(0, 0, 1000)), target:GLKVector3(v:(0, 0, 0)), approximateUp:GLKVector3(v:(0, 1, 0)))

        // 立方体
        cubeModel = DvrCube(device: device, xExtent: 150, yExtent: 150, zExtent: 150, xTesselation: 32, yTesselation: 32, zTesselation: 32)
        
        // 球体
         coneModel = DvrSphere(device: device, xExtent: 100, yExtent: 100, zExtent: 1, uTesselation: 64, vTesselation: 64)

        // 柱体
        // cubeModel = DvrCylinder(device: device, height: 100, xExtent: 100, yExtent: 100, radia: 50,  vTesselation: 64)
        
        // 锥体
        //coneModel = DvrCone(device: device, height: 100, xExtent: 100, yExtent: 100, count: 5, vTesselation: 64)
        
        // 二十面体
        // cubeModel = DvrIcosahed(device: device, radius: 100)

        do {
            cubeModelTexture = try makeTexture(device: device, name: "mandrill")
        } catch {
            fatalError("Error: Can not load texture")
        }

        do {
            frontTexture = try makeTexture(device: device, name: "mandrill")
        } catch {
            fatalError("Error: Can not load texture")
        }

        do {
            backTexture = try makeTexture(device: device, name: "mobile")
        } catch {
            fatalError("Error: Can not load texture")
        }

        do {
            cubeModelPipelineState =
                    try device.makeRenderPipelineState(descriptor:MTLRenderPipelineDescriptor(view:view,
                            library:library!,
                            vertexShaderName:"textureTwoSidedMIOVertexShader",
                            fragmentShaderName:"textureTwoSidedMIOFragmentShader",
                            doIncludeDepthAttachment: false,
                            vertexDescriptor:cubeModel.metalVertexDescriptor))
        } catch let e {
            Swift.print("\(e)")
        }

        
        // cone model
        
        do {
            coneTexture = try makeTexture(device: device, name: "lena")
        } catch {
            fatalError("Error: Can not load texture")
        }
        
        do {
            conePipelineState =
                try device.makeRenderPipelineState(descriptor:MTLRenderPipelineDescriptor(view:view,
                                                                                          library:library!,
                                                                                          vertexShaderName:"showMIOVertexShader",
                                                                                          fragmentShaderName:"showMIOFragmentShader",
                                                                                          doIncludeDepthAttachment: false,
                                                                                          vertexDescriptor:coneModel.metalVertexDescriptor))
        } catch let e {
            Swift.print("\(e)")
        }
        
        // render plane
        renderPlane = DvrPlane(device: device, xExtent: 2, yExtent: 2, xTesselation: 4, yTesselation: 4)

        do {
            renderPlaneTexture = try makeTexture(device: device, name: "mobile")
        } catch {
            fatalError("Error: Can not load texture")
        }

        do {
            renderPlanePipelineState =
                    try device.makeRenderPipelineState(descriptor:
                    MTLRenderPipelineDescriptor(view:view,
                            library:library!,
                            vertexShaderName:"textureTwoSidedMIOVertexShader",
                            fragmentShaderName:"textureTwoSidedMIOFragmentShader",
                            doIncludeDepthAttachment: false,
                            vertexDescriptor: renderPlane.metalVertexDescriptor))

        } catch let e {
            Swift.print("\(e)")
        }

        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        commandQueue = device.makeCommandQueue()

    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        reshape(view:view as! Model_IOMetalView)
    }

    func reshape (view: Model_IOMetalView) {
        view.arcBall.reshape(viewBounds: view.bounds)
        camera.setProjection(fovYDegrees:Float(35), aspectRatioWidthOverHeight:Float(view.bounds.size.width / view.bounds.size.height), near: 200, far: 8000)
    }

    func update(view: Model_IOMetalView, drawableSize:CGSize) {

        if camera.fovYDegrees == nil {
            reshape(view:view)
        }
        // render plane
        renderPlane.metallicTransform.update(camera: camera, transformer: {
            return camera.createRenderPlaneTransform(distanceFromCamera: 0.75 * camera.far) * GLKMatrix4MakeRotation(GLKMathDegreesToRadians(90), 1, 0, 0)
        })

        // cube model
        cubeModel.metallicTransform.update(camera: camera, transformer: {
            return view.arcBall.rotationMatrix
        })
        
        // cone model
        coneModel.metallicTransform.update(camera: camera, transformer: {
            return   GLKMatrix4Translate(view.arcBall.rotationMatrix, 0, 200, 0)
        })

    }

    public func draw(in view: MTKView) {

        update(view: view as! Model_IOMetalView, drawableSize: view.bounds.size)

        // final pass
        if let finalPassDescriptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable {

            let commandBuffer = commandQueue.makeCommandBuffer()

            let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalPassDescriptor)
            
            renderCommandEncoder.setDepthStencilState(depthStencilState)
            
            renderCommandEncoder.setFrontFacing(.counterClockwise)
            renderCommandEncoder.setCullMode(.none)

            // render plane
            renderCommandEncoder.setTriangleFillMode(.fill)

            renderCommandEncoder.setRenderPipelineState(renderPlanePipelineState)

            renderCommandEncoder.setVertexBuffer(renderPlane.vertexMetalBuffer, offset: 0, at: 0)
            renderCommandEncoder.setVertexBuffer(renderPlane.metallicTransform.metalBuffer, offset: 0, at: 1)

            renderCommandEncoder.setFragmentTexture(renderPlaneTexture, at: 0)
            renderCommandEncoder.setFragmentTexture(renderPlaneTexture, at: 1)

            renderCommandEncoder.drawIndexedPrimitives(
                    type: renderPlane.primitiveType,
                    indexCount: Int(renderPlane.indexCount),
                    indexType: renderPlane.indexType,
                    indexBuffer: renderPlane.vertexIndexMetalBuffer,
                    indexBufferOffset: 0)

            // cone model
            renderCommandEncoder.setTriangleFillMode(.fill)
            
            renderCommandEncoder.setRenderPipelineState(conePipelineState)
            
            renderCommandEncoder.setVertexBuffer(coneModel.vertexMetalBuffer, offset: 0, at: 0)
            renderCommandEncoder.setVertexBuffer(coneModel.metallicTransform.metalBuffer, offset: 0, at: 1)
            
            renderCommandEncoder.setFragmentTexture(coneTexture, at: 0)
            renderCommandEncoder.setFragmentTexture(coneTexture, at: 1)
            
            renderCommandEncoder.drawIndexedPrimitives(
                type: coneModel.primitiveType,
                indexCount: Int(coneModel.indexCount),
                indexType: coneModel.indexType,
                indexBuffer: coneModel.vertexIndexMetalBuffer,
                indexBufferOffset: 0)

            // cube model
            renderCommandEncoder.setTriangleFillMode(.fill)

            renderCommandEncoder.setRenderPipelineState(cubeModelPipelineState)

            renderCommandEncoder.setVertexBuffer(cubeModel.vertexMetalBuffer, offset: 0, at: 0)
            renderCommandEncoder.setVertexBuffer(cubeModel.metallicTransform.metalBuffer, offset: 0, at: 1)

            renderCommandEncoder.setFragmentTexture(cubeModelTexture, at: 0)
            renderCommandEncoder.setFragmentTexture(backTexture, at: 1)

            renderCommandEncoder.drawIndexedPrimitives(
                    type: cubeModel.primitiveType,
                    indexCount: Int(cubeModel.indexCount),
                    indexType: cubeModel.indexType,
                    indexBuffer: cubeModel.vertexIndexMetalBuffer,
                    indexBufferOffset: 0)
    
            renderCommandEncoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

    }

}
