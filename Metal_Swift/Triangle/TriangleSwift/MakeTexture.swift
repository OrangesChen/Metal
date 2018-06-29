//
//  MakeTexture.swift
//  TriangleSwift
//
//  Created by cfq on 2016/11/25.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

import Foundation
import MetalKit

enum TextureError: Error {
    case UIImageCreationError
    case MTKTextureLoaderError
}

/*----------创建Metal纹理--------------
 *  @param device 设备
 *  @param name   图片名称
 *  @retun MTLTexture 纹理
 */

func makeTexture(device: MTLDevice, name: String) throws -> MTLTexture {
    guard let image = UIImage(named: name) else {
        throw TextureError.UIImageCreationError
    }
    
    // 处理后的图片是倒置，要先将其倒置过来才能显示出正图像
    // 当你从CGImage转化为UImage时，可调用imageWithCGImage:scale:orientation:方法生成CGImage作为对缩放性的补偿。所以这是一个解决倒置和缩放问题的自包含方法
//    let mirrorImage = UIImage(cgImage: (image.cgImage)!, scale: 1, orientation: UIImageOrientation.downMirrored)
//    let size = CGSize(width: image.size.width, height: image.size.height)
//    let scaledImage = UIImage.scaleToSize(mirrorImage, size: size)

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

// 自定义UIImage的类方法, 设置图片大小
extension UIImage {
    class func scaleToSize(_ image: UIImage, size: CGSize)->UIImage {
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: CGPoint.zero, size: size))
        // 获取当前上下文
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
        
    }
}
