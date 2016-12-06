//
//  DvrMesh.swift
//  RotateDemo
//
//  Created by cfq on 2016/11/3.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

import ModelIO
import MetalKit

struct DvrMesh {
    
    // The MTKMesh class provides a container for the vertex data of a MetalKit mesh and its submeshes, suitable for rendering in a Metal application. For more information on the Model I/O objects used to generate MetalKit mesh data, see MDLMesh and MDLAsset.
    var mesh: MTKMesh!
    
    var submesh: MTKSubmesh {
        // An array of submeshes containing index buffers referencing the mesh vertices.
        return self.mesh.submeshes[0]
    }
    
    var vertexMetalBuffer: MTLBuffer {
        // vertexBuffers: An array of buffers in which mesh vertex data resides. 
        // 顶点数据所在的缓冲区数组
        return self.mesh.vertexBuffers[0].buffer
    }
    
    var vertexIndexMetalBuffer: MTLBuffer {
        // IndexBuffer (including indexCount) to render the object.
        // 索引缓冲区
        return self.mesh.submeshes[0].indexBuffer.buffer
    }
    
    var primitiveType: MTLPrimitiveType {
        return self.mesh.submeshes[0].primitiveType
    }
    
    var indexCount: Int {
        return self.mesh.submeshes[0].indexCount
    }
    
    var indexType: MTLIndexType {
        return self.mesh.submeshes[0].indexType
    }
    
    var metalVertexDescriptor: MTLVertexDescriptor!
    
    var metallicTransform: MetallicTransform!
    
    mutating func initializationHelper (device: MTLDevice) -> MDLVertexDescriptor {
        
        self.metallicTransform = MetallicTransform(device: device)
        
        // Metal vertex descriptor
        self.metalVertexDescriptor = MTLVertexDescriptor()
        
        // 定点坐标设置

        // xyz 位置坐标
        metalVertexDescriptor.attributes[0].format = .float3
        metalVertexDescriptor.attributes[0].offset = 0
        metalVertexDescriptor.attributes[0].bufferIndex = 0
        
        // n 法线
        metalVertexDescriptor.attributes[1].format = .float3
        metalVertexDescriptor.attributes[1].offset = 12
        metalVertexDescriptor.attributes[1].bufferIndex = 0
        
        // st 纹理
        metalVertexDescriptor.attributes[2].format = .half2
        metalVertexDescriptor.attributes[2].offset = 24
        metalVertexDescriptor.attributes[2].bufferIndex = 0
        
        // Single interleaved buffer
        // 缓冲区中两个顶点属性数据之间的距离
        metalVertexDescriptor.layouts[0].stride = 28
        // 顶点及其属性呈现给顶点函数的间隔， 默认值为1; 如果stepRate等于1，则为每个实例提取新的属性数据; 如果stepRate等于2，则为每两个实例提取新的属性数据
        metalVertexDescriptor.layouts[0].stepRate = 1
        // stepRate值与stepFunction属性一起确定函数获取新属性数据的频率
        metalVertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // Model I/O vertex descriptor
        // 返回部分转换的模型I/O顶点描述符
        let modelIOVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(metalVertexDescriptor)
        (modelIOVertexDescriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (modelIOVertexDescriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (modelIOVertexDescriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        
        return modelIOVertexDescriptor

    }
}

//  立方体
typealias DvrCube = DvrMesh

extension DvrCube {
    init(device: MTLDevice,
         xExtent:Float,
         yExtent:Float,
         zExtent:Float,
         xTesselation:UInt32,
         yTesselation:UInt32,
         zTesselation:UInt32) {
        
        do {
            
            /**
                创建一个矩形框或者立方体形状的网格
             
             - parameter withDimensions: 包含要生成的框的宽度（x分量），高度（y分量）和深度（z分量）的向量
             - parameter segments:       沿每个维度生成的点数。 更大数量的点增加了渲染保真度，但是降低渲染性能。
             - parameter geometryType:   构造网格的几何基元的类型; 必须是三角形，四边形或线。
             - parameter inwardNormals:  true生成指向盒子内部的法线向量; false生成向外指向的法向向量。
             - parameter allocator:      负责分配网格顶点数据的对象。 如果为nil，Model I/O使用内部分配器对象。
             
             - returns: MDLMesh
             */
            
            let mdlMesh = MDLMesh.newBox(withDimensions: vector_float3(xExtent, yExtent, zExtent),
                                         segments: vector_uint3(xTesselation, yTesselation, zTesselation),
                                         geometryType: .triangles,
                                         inwardNormals: false,
                                         allocator: MTKMeshBufferAllocator(device: device))
            
            mdlMesh.vertexDescriptor = initializationHelper(device: device)
            
            self.mesh = try MTKMesh(mesh: mdlMesh, device: device)
            
        } catch {
            fatalError("Error: Can not create Metal mesh")
        }
        
    }
}

// 平面
typealias DvrPlane = DvrMesh

extension DvrPlane {
    init(device: MTLDevice,
         xExtent: Float,
         yExtent: Float,
         xTesselation: UInt32,
         yTesselation: UInt32) {
        do {
            let mdlMesh = MDLMesh.newPlane(withDimensions: vector_float2(xExtent, yExtent), segments: vector_uint2(xTesselation, yTesselation), geometryType: .triangles, allocator: MTKMeshBufferAllocator(device: device))
            mdlMesh.vertexDescriptor = self.initializationHelper(device: device)
            self.mesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            fatalError("Error: Can not create Metal mesh")
        }
    }
}

// 天空盒

typealias DvrSphere = DvrMesh

extension DvrSphere {
    init(device: MTLDevice,
         xExtent: Float,
         yExtent: Float,
         zExtent: Float,
         uTesselation: Int,
         vTesselation: Int) {
        do {
            let mdlMesh = MDLMesh.newEllipsoid(withRadii: vector_float3(xExtent, yExtent, zExtent), radialSegments: uTesselation, verticalSegments: vTesselation, geometryType: .triangles, inwardNormals: false, hemisphere: false, allocator: MTKMeshBufferAllocator(device: device))
            mdlMesh.vertexDescriptor = initializationHelper(device: device)
            self.mesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            fatalError("Error: Can not create Metal mesh")
        }
    }
}

// 圆筒
// newCylinder(withHeight height: Float, radii: vector_float2, radialSegments: Int, verticalSegments: Int, geometryType: MDLGeometryType, inwardNormals: Bool, allocator: MDLMeshBufferAllocator?)
typealias DvrCylinder = DvrMesh

extension DvrCylinder {
    init(device: MTLDevice,
         height: Float,
         xExtent: Float,
         yExtent: Float,
         radia: Int,
         vTesselation: Int) {
        do {
            let mdlMesh = MDLMesh.newCylinder(withHeight: height, radii: vector_float2(xExtent, yExtent), radialSegments: radia, verticalSegments: vTesselation, geometryType: .triangles, inwardNormals: false, allocator: MTKMeshBufferAllocator(device: device))
            mdlMesh.vertexDescriptor = initializationHelper(device: device)
            self.mesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            fatalError("Error: Can not create Metal mesh")
        }
    }
}

// 圆锥
// newEllipticalCone(withHeight height: Float, radii: vector_float2, radialSegments: Int, verticalSegments: Int, geometryType: MDLGeometryType, inwardNormals: Bool, allocator: MDLMeshBufferAllocator?)

typealias DvrCone = DvrMesh

extension DvrCone {
    init(device: MTLDevice,
         height: Float,
         xExtent: Float,
         yExtent: Float,
         count: Int,
         vTesselation: Int) {
        do {
            let mdlMesh = MDLMesh.newEllipticalCone(withHeight: height, radii: vector_float2(xExtent, yExtent), radialSegments: count, verticalSegments: vTesselation, geometryType: .triangles, inwardNormals: false, allocator: MTKMeshBufferAllocator(device: device))
            mdlMesh.vertexDescriptor = initializationHelper(device: device)
            /*
            //newSubdividedMesh:  细分网格
            let newmesh = MDLMesh.newSubdividedMesh(mdlMesh, submeshIndex: 0, subdivisionLevels: 0)
            self.mesh = try MTKMesh(mesh: newmesh!, device: device)
          */
            self.mesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            fatalError("Error: Can not create Metal mesh")
        }
    }
}

// 二十面体
// newIcosahedron(withRadius radius: Float, inwardNormals: Bool, allocator: MDLMeshBufferAllocator?)

typealias DvrIcosahed = DvrMesh

extension DvrIcosahed {
    init(device: MTLDevice, radius: Float) {
        do {
            let mdlMesh = MDLMesh.newIcosahedron(withRadius: radius, inwardNormals: true, allocator: MTKMeshBufferAllocator(device: device))
            mdlMesh.vertexDescriptor = initializationHelper(device: device)
            self.mesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            fatalError("Error: Can not create Metal mesh")
        }
    }
}



