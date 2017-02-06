//
//  APPLView.h
//  MetalVertex
//
//  Created by cfq on 2016/10/24.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@protocol  APPLViewDelegate;

@interface APPLView : UIView
@property (nonatomic, assign) id <APPLViewDelegate> delegate;

// view has a handle to the metal device when create
@property (nonatomic, readonly) id <MTLDevice> device;

// the current drawable create within the view's CAMetalLayer
@property (nonatomic, readonly) id <CAMetalDrawable> currentDrawable;

// the current framebuiffer can be read by delegate during -[MetalViewDelegate render:]
// This call may block until the framebuffer is available
@property (nonatomic, readonly) MTLRenderPassDescriptor *renderPassDescriptor;

// set these pixel formats to have the main drawable framebuffer get create with depth and/or stencil attachment
@property (nonatomic) MTLPixelFormat depthPixelFormat;
@property (nonatomic) MTLPixelFormat stencilPixelFormat;
@property (nonatomic) NSUInteger     sampleCount;

// view controller will be call off the main thread
- (void) display;

// release any color/depth/stencil resources. view controller will call when pause
- (void) releaseTextures;

@end

// rendering delegate (App must implement a rendering delegate that responds to these messages

@protocol APPLViewDelegate <NSObject>

@required
// called if the view changes orientation or size, renderer can precompute its view and projection matricies here for example
- (void) reshape:(APPLView *)view;

// delegate should perform all rendering here
- (void) render:(APPLView *)view;

@end








