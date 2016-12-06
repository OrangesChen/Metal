//
//  DvrCamera.swift
//  RotateDemo
//
//  Created by cfq on 2016/11/3.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

import GLKit

// viewing frustrum - eye looks along z-axis towards -z direction
//                    +y-axis up
//                    +x-axis to the right

struct DvrCamera {
    
    var location: GLKVector3!
    var target: GLKVector3!
    var transform: GLKMatrix4!
    var projectionTransform: GLKMatrix4!
    
    var near: Float!
    var far: Float!
    
    var fovYDegrees: Float!
    var aspectRatioWidthOverHeight: Float!

    
    init(location:GLKVector3, target:GLKVector3, approximateUp:GLKVector3) {
        self.setTransform(location:location, target:target, approximateUp:approximateUp)
    }

    /** 
         mutating
     *mutating可变化，可改变
     
     mutating可使用到的地方:
     
     1.结构体，枚举类型中的方法声明为mutating
     
     2.extension中的方法声明为mutating
     
     3.protocol方法声明为mutating
     */
    mutating func setTransform (location:GLKVector3, target:GLKVector3, approximateUp:GLKVector3) {
        
        self.location = location
        self.target = target
        
        self.transform = makeLookAt(eye:location, target: target, approximateUp: approximateUp)
    }

    
    
   func makeLookAt(eye:GLKVector3, target:GLKVector3, approximateUp:GLKVector3) -> GLKMatrix4 {
        // GLKVector3Normalize: Returns a new vector created by normalizing the input vector to a length of 1.0. 单位向量
        // GLKVector3Add: Returns the sum of two vectors.
        // GLKVector3Negate: Returns a new vector created by negating the component values of another vector.
    let n = GLKVector3Normalize(GLKVector3Add(eye, GLKVector3Negate(target)))
    
    var crossed:GLKVector3!
    
        // Returns the cross product of two vectors. 返回两个向量的叉积
    crossed = GLKVector3CrossProduct(approximateUp, n)
    var u:GLKVector3!
    if (GLKVector3Length(crossed) > 0.0001) {
        u = GLKVector3Normalize(crossed)
    } else {
        u = crossed
    }
    
    crossed = GLKVector3CrossProduct(n, u)
    var v:GLKVector3!
    if (GLKVector3Length(crossed) > 0.0001) {
        v = GLKVector3Normalize(crossed)
    } else {
        v = crossed
    }
    
    let m = GLKMatrix4(m: (
        u.x, v.x, n.x, Float(0),
        u.y, v.y, n.y, Float(0),
        u.z, v.z, n.z, Float(0),
        GLKVector3DotProduct(GLKVector3Negate(u), eye), GLKVector3DotProduct(GLKVector3Negate(v), eye), GLKVector3DotProduct(GLKVector3Negate(n), eye), Float(1)))
    
    return m;
    }
    
     mutating func setProjection (fovYDegrees:Float, aspectRatioWidthOverHeight:Float, near:Float, far:Float) {
        
        self.fovYDegrees = fovYDegrees
        self.near = near
        self.far = far
        self.aspectRatioWidthOverHeight = aspectRatioWidthOverHeight
        self.projectionTransform = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.fovYDegrees), self.aspectRatioWidthOverHeight, self.near, self.far)
    }
    
    func createRenderPlaneTransform(distanceFromCamera: Float) -> GLKMatrix4 {
        
        var unused: Bool = true
        let _A_ = GLKMatrix4Invert(self.transform, &unused);
        let A = GLKMatrix4MakeWithColumns(GLKMatrix4GetColumn(_A_, 0), GLKMatrix4GetColumn(_A_, 1), GLKMatrix4GetColumn(_A_, 2), GLKMatrix4GetColumn(GLKMatrix4Identity, 3));
        
        // Translate rotated camera plane to camera origin.
        let B = GLKMatrix4MakeTranslation(self.location.x, self.location.y, self.location.z);
        
        // Position camera plane by translating the distance "cameraNear" along camera look-at vector.
        let direction = GLKVector3Normalize(GLKVector3Subtract(self.target, self.location));
        
        let translation = GLKVector3MultiplyScalar(direction, distanceFromCamera);
        
        let C = GLKMatrix4MakeTranslation(translation.x, translation.y, translation.z);
        
        // Concatenate.
        let transform = GLKMatrix4Multiply(C, GLKMatrix4Multiply(B, A));
        
        let dimension = distanceFromCamera * tan( GLKMathDegreesToRadians( self.fovYDegrees/2 ) )
        return transform * GLKMatrix4MakeScale(self.aspectRatioWidthOverHeight * dimension, dimension, 1)
        
    }
    
    
}
