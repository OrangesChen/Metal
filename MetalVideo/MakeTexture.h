//
//  MakeTexture.h
//  MetalVideo
//
//  Created by cfq on 2016/11/22.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

@interface MakeTexture : NSObject

@property (readonly) id<MTLTexture> texture;
@property (readonly) uint32_t width;
@property (readonly) uint32_t height;
@property (readonly) uint32_t depth;
@property (readonly) uint32_t target;
@property (readonly) uint32_t pixelFormat;
@property (readonly) BOOL hasAlpha;
@property (readonly) NSString *pathToTextureFile;

- (id)initWithResourceName:(NSString *)name extension:(NSString *)ext;
- (BOOL)loadIntoTextureWithDevice:(id<MTLDevice>)device;

@end
