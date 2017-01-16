//
//  MakeTexture.swift
//  RotateDemo
//
//  Created by cfq on 2016/11/1.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

import MetalKit

enum TextureError: Error {
    case UIImageCreationError
    case MTKTextureLoaderError
}

func makeTexture(device: MTLDevice, name: String) throws -> MTLTexture {
    guard let image = UIImage(named: name) else {
        throw TextureError.UIImageCreationError
    }
    
    do {
        let textureLoader = MTKTextureLoader(device: device)
        let textureLoaderOption:[String: NSNumber] = [ MTKTextureLoaderOptionSRGB: false]
        
        // 异步加载
//        try textureLoader.newTexture(with: image.cgImage!, options: textureLoaderOption, completionHandler: { (<#MTLTexture?#>, <#Error?#>) in
//            
//        })
        
        // 同步根据图片创建新的Metal纹理
        // Synchronously loads image data and creates a new Metal texturefrom a given bitmap image.
        return try textureLoader.newTexture(with: image.cgImage!, options: textureLoaderOption)
        
        
        
    }
}
