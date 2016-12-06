//
//  DvrView.swift
//  RotateDemo
//
//  Created by cfq on 2016/11/3.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

import MetalKit

class DvrView: MTKView {
    
    var renderer: MTKViewDelegate!
    var arcBall: EIArcball!
    
    
    required public init(coder: NSCoder) {
        
        super.init(coder: coder)
        
        device = MTLCreateSystemDefaultDevice()!
        
        arcBall = EIArcball.init(view: self)
        // 添加手势
        addGestureRecognizer(UIPanGestureRecognizer.init(
            target: arcBall,
            action: #selector(EIArcball.arcBallPanHandler)))
        
    }
    


}
