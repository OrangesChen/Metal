//
//  MetalView.swift
//  RotateDemo
//
//  Created by cfq on 2016/11/1.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

import MetalKit

class MetalView: EIView {

     required init(coder: NSCoder) {
        super.init(coder: coder)
        renderer = Renderer(view: self, device: device!)
        delegate = renderer
    }
    

}
