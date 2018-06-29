//
//  MakeTexture.swift
//  TriangleSwift
//
//  Created by cfq on 2016/11/25.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

import Metal
import UIKit
import CoreGraphics

/*
 首先要说的是，在iOS的不同framework中使用着不同的坐标系：
 
 UIKit － y轴向下
 Core Graphics(Quartz) － y轴向上
 OpenGL ES － y轴向上
 UIKit是iPhone SDK的Cocoa Touch层的核心framework，是iPhone应用程序图形界面和事件驱动的基础，它和传统的
 windows桌面一样，坐标系是y轴向下的; Core Graphics(Quartz)一个基于2D的图形绘制引擎，它的坐标系则是y轴向上
 的；而OpenGL ES是iPhone SDK的2D和3D绘制引擎，它使用左手坐标系，它的坐标系也是y轴向上的，如果不考虑z轴，在
 二维下它的坐标系和Quartz是一样的。
 
 当通过CGContextDrawImage绘制图片到一个context中时，如果传入的是UIImage的CGImageRef，因为UIKit和CG坐
 标系y轴相反，所以图片绘制将会上下颠倒。解决方法有以下几种，
 
 解决方法一：在绘制到context前通过矩阵垂直翻转坐标系
 
 解决方法二：使用UIImage的drawInRect函数，该函数内部能自动处理图片的正确方向
 
 解决方法三：垂直翻转投影矩阵
 这种方法通过设置上下颠倒的投影矩阵，使得原本y轴向上的GL坐标系看起来变成了y轴向下，并且坐标原点从屏幕左下角移到
 了屏幕左上角。如果你习惯使用y轴向下的坐标系进行二维操作，可以使用这种方法，同时原本颠倒的图片经过再次颠倒后回到
 了正确的方向：
 
 
 */



var type: MTLTextureType!
var texture: MTLTexture!
// 在处理贴图上使用CGImage在CGContext上draw的方法来取得图像, 但是通过draw方法绘制的图像是上下颠倒的，可以通过UIImage的drawInRect函数，该函数内部能自动处理图片的正确方向，然后调用makeTexture()方法生成纹理
func loadIntoTextureWithDevice(device: MTLDevice, name: String, ext: String) -> Bool {
    
    let path = Bundle.main.path(forResource: name, ofType: ext)
    if !(path != nil) {
        return false
    }
    let image = UIImage(contentsOfFile: path!)
    let width = (image?.cgImage)!.width
    let height = (image?.cgImage)!.height
    let dataSize = width * height * 4
    let data = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 4 * width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue);
    context?.draw((image?.cgImage)!, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
    // 通过UIImage的drawInRect函数，该函数内部能自动处理图片的正确方向 //不知道是不是API更新了 已经不需要这一步处理图片方向了
//    UIGraphicsPushContext(context!);
//    image?.draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
    
    let textDes = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: Int(width), height: Int(height), mipmapped: false)
    type = textDes.textureType
    texture = device.makeTexture(descriptor: textDes)
    if !(texture != nil) {
        return false
    }
    texture.replace(region: MTLRegionMake2D(0, 0, Int(width), Int(height)), mipmapLevel: 0, withBytes: context!.data!, bytesPerRow: width * 4)
//    UIGraphicsPopContext()
    free(data)
    return true
}

