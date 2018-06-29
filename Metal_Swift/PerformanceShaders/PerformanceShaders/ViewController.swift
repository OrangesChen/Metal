//
//  ViewController.swift
//  PerformanceShaders
//
//  Created by cfq on 2016/11/21.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

// iOS9在MetalKit中新增了MetalPerformanceShaders类，可以使用GPU进行高效的图像计算，比如高斯模糊，图像直方图计算，索贝尔边缘检测算法等

import UIKit
import MetalKit
import MetalPerformanceShaders

/*
 ----------MetalPerformanceShaders的使用流程--------
 1、配置MTKView用来承载模糊的结果
 2、为MTKView创建新的命令队列MTLCommandQueue
 3、读取资源数据,创建MTLTexture，作为高斯模糊的数据源。
 4、创建高斯模糊对象
 5、运行高斯模糊，并绘制结果到MTKView
 
 */

// 使ViewController遵循MTKViewDelegate协议
class ViewController: UIViewController, MTKViewDelegate {

    var metalView: MTKView!
    var commandQueue: MTLCommandQueue!
    var sourceTexture: MTLTexture!
    
    @IBOutlet weak var blurRadius: UISlider!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        setUpMetalView()
        loadAssets()
    }

    func setUpMetalView() {
        // 设置metalView大小，边框等属性
        metalView = MTKView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 300, height: 300)))
        metalView.center = view.center
        metalView.layer.borderColor = UIColor.white.cgColor
        metalView.layer.borderWidth = 5
        metalView.layer.cornerRadius = 20
        metalView.clipsToBounds = true
        view.addSubview(metalView)
        
        // 读取默认设备
        metalView.device = MTLCreateSystemDefaultDevice()
        
        // 确保当前设备支持MetalPerformanceShaders
        guard let metalView = metalView, MPSSupportsMTLDevice(metalView.device) else {
            print("该设备不支持MetalPerformanceShaders!")
            return
        }
        // 配置MTKView属性
        metalView.delegate = self
        metalView.depthStencilPixelFormat = .depth32Float_stencil8
        
        // 设置输入／输出数据纹理格式
        metalView.colorPixelFormat = .bgra8Unorm
        // 将currentDrawable.texture设置为可写
        metalView.framebufferOnly = false
    }
    
    func loadAssets() {
        // 创建新的命令队列
        commandQueue = metalView.device?.makeCommandQueue()
        
        // 设置纹理加载器
        let textureLoader = MTKTextureLoader(device: metalView.device!)
        // 对图片进行加载和设置
        let image = UIImage(named: "mandrill")
        // 将图片调整至所需大小
        let scaledImage = UIImage.scaleToSize(image!, size: CGSize(width: 600, height: 600))
        let cgimage = scaledImage.cgImage
        
        // 将图片加载到MetalPerformanceShaders的输入纹理(source texture)
        do {
            sourceTexture = try textureLoader.newTexture(with: cgimage!, options: [:])
            
        } catch let error as NSError {
            fatalError("Unexpected error ocurred: \(error.localizedDescription)")
        }
        
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func blurRadiusDidChanged(_ sender: UISlider) {
        // 每次滑块滑动后重新绘制metalView
        metalView.setNeedsDisplay()
    }
    
    
    // MARK -- MTKViewDelegate
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    // 绘制metalView
    public func draw(in view: MTKView){
        // 得到MetalPerformanceShaders需要使用的命令缓冲区
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        // 初始化MetalPerformanceShaders高斯模糊，模糊半径(sigma)为slider所设置的值
        let gaussianblur = MPSImageGaussianBlur(device: view.device!, sigma: self.blurRadius.value)
        // 运行MetalPerformanceShaders高斯模糊
        gaussianblur.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: view.currentDrawable!.texture)
        // 提交commandBuffer
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}

extension UIImage {
    class func scaleToSize(_ image: UIImage, size: CGSize)->UIImage {
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: CGPoint.zero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!

    }
}

