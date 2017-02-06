//
//  RenderPlayer.h
//  MetalVideo
//
//  Created by cfq on 2017/1/16.
//  Copyright © 2017年 Dlodlo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APPLView.h"
#import <Metal/Metal.h>


@interface RenderPlayer : NSObject<APPLViewDelegate>

// load all assets before triggering rendering
- (void)configure:(APPLView *)view;
@property (nonatomic, strong)  id<MTLBuffer> parametersBuffer;
@property (nonatomic, strong) CAMetalLayer *layer;
- (void)display:(CVPixelBufferRef)overlay;
- (void)setVideoTexture;
@end
