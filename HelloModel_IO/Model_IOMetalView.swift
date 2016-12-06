//
//  Model_IOMetalView.swift
//  RotateDemo
//
//  Created by cfq on 2016/11/3.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

import MetalKit

var userToggle: Bool = false

class Model_IOMetalView:  DvrView{
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        addGestureRecognizer(UITapGestureRecognizer.init(
            target: self,
            action: #selector(Model_IOMetalView.tapGesture)))
        
        renderer = Model_IORenderer(view: self, device: device!)
        delegate = renderer
    }
    
    func tapGesture() {
        userToggle = !userToggle
    }

}
