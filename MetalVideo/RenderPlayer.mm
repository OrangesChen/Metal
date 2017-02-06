//
//  RenderPlayer.m
//  MetalVideo
//
//  Created by cfq on 2017/1/16.
//  Copyright © 2017年 Dlodlo. All rights reserved.
//

#import "RenderPlayer.h"
#import "APPLViewController.h"
#import "APPLView.h"
#import "MakeTexture.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/ALAssetsLibrary.h>


#import <simd/simd.h>

//static const long kMaxBufferBytesPerFrame = 1024*1024;
static const long kInFlightCommandBuffers = 3;

static const float quad[] =
{
    // verticies (xyz),  texCoord (uv)
    -0.5,  0.5, 0,  1, 1,
     0.5, -0.5, 0,  0, 0,
     0.5,  0.5, 0,  0, 1,
    
    -0.5,  0.5, 0,  1, 1,
     0.5, -0.5, 0,  0, 0,
    -0.5, -0.5, 0,  1, 0,
};

struct ColorParameters
{
    simd::float3x3 yuvToRGB;
};

@interface RenderPlayer()

@property (nonatomic , strong) NSDate *mStartDate;

@property (nonatomic , strong) AVAsset *mAsset;
@property (nonatomic , strong) AVAssetReader *mReader;
@property (nonatomic , strong) AVAssetReaderTrackOutput *mReaderVideoTrackOutput;
@property (nonatomic , strong) CADisplayLink *mDisplayLink;

@end

@implementation RenderPlayer
{
    // MTLDevice represents a processor capable of data parallel computations
    // 能够进行数据并行计算的处理器
    id <MTLDevice> _device;
    // A serial queue of command buffers to be executed by the device
    // 由设备执行的命令缓冲区的串行队列, 命令提交流程
    id <MTLCommandQueue> _commandQueue;
    // The MTLLibrary protocol defines the interface for an object that represents a library of graphics or compute functions.
    id <MTLLibrary> _defaultLibrary;
    
    // 控制资源访问
    dispatch_semaphore_t _inflight_semaphore;
    
    // render stage
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLBuffer> _vertexBuffer;
    id <MTLBuffer> _vertexColorBuffer;
    id <MTLTexture> _texture;
    id<MTLSamplerState> samplerState;
    // this value will cycle from 0 to g_max_inflight_buffers whenever a display completes ensuring renderer clients
    // can synchronize between g_max_inflight_buffers count buffers, and thus avoiding a constant buffer from being overwritten between draws
    NSUInteger _constantDataBufferIndex;
    MakeTexture *quadTex ;
    
    CVMetalTextureCacheRef _videoTextureCache;
    id<MTLTexture> _videoTexture[2];
    
    CVPixelBufferRef _pixelBuffer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _constantDataBufferIndex = 0;
        // 创建一个可访问资源数为kInFlightCommandBuffers的信号量，vkInFlightCommandBuffers等于3
        _inflight_semaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
        [self setPlayer];
    }
    return self;
}

- (void)loadAsset {
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"1" withExtension:@"mp4"] options:inputOptions];
    __weak typeof(self) weakSelf = self;
    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
            AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
            if (tracksStatus != AVKeyValueStatusLoaded)
            {
                NSLog(@"error %@", error);
                return;
            }
            weakSelf.mAsset = inputAsset;
            [weakSelf processAsset];
        });
    }];
}

- (void)processAsset
{
    self.mReader = [self createAssetReader];
    
    if ([self.mReader startReading] == NO)
    {
        NSLog(@"Error reading from file at URL: %@", self.mAsset);
        return;
    }
    else {
        self.mStartDate = [NSDate dateWithTimeIntervalSinceNow:0];
        NSLog(@"Start reading success.");
    }
}

- (AVAssetReader*)createAssetReader
{
    NSError *error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:self.mAsset error:&error];
    
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    
    [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    self.mReaderVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[self.mAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
    self.mReaderVideoTrackOutput.alwaysCopiesSampleData = NO;
    [assetReader addOutput:self.mReaderVideoTrackOutput];
    
    return assetReader;
}

- (void)displayLinkCallback:(CADisplayLink *)sender
{
    CMSampleBufferRef sampleBuffer = [self.mReaderVideoTrackOutput copyNextSampleBuffer];
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (pixelBuffer) {
        //self.mLabel.text = [NSString stringWithFormat:@"播放%.f秒", [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSinceDate:self.mStartDate]];
        [self display:pixelBuffer];
        if (pixelBuffer != NULL) {
            CFRelease(pixelBuffer);
        }
    }
    else {
        NSLog(@"播放完成");
       [self.mDisplayLink setPaused:YES];
    }
}

- (void)setPlayer {
        self.mDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        self.mDisplayLink.preferredFramesPerSecond = 30; //FPS=30
        [[self mDisplayLink] addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self loadAsset];
}

- (void)makeYUVTexture:(CVPixelBufferRef)pixelBuffer {
    CVMetalTextureRef y_texture ;
    float y_width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    float y_height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, nil, MTLPixelFormatR8Unorm, y_width, y_height, 0, &y_texture);
    
    CVMetalTextureRef uv_texture;
    float uv_width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    float uv_height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, nil, MTLPixelFormatRG8Unorm, uv_width, uv_height, 1, &uv_texture);
    
    id<MTLTexture> luma = CVMetalTextureGetTexture(y_texture);
    id<MTLTexture> chroma = CVMetalTextureGetTexture(uv_texture);
    
    _videoTexture[0] = luma;
    _videoTexture[1] = chroma;
    
    CVBufferRelease(y_texture);
    CVBufferRelease(uv_texture);
}

- (void)display:(CVPixelBufferRef)overlay {
    if (!overlay) {
        return;
    }
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        return;
    }
    [self makeYUVTexture:overlay];
}

- (void)setVideoTexture {
    CVMetalTextureCacheFlush(_videoTextureCache, 0);
    CVReturn err = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, _device, NULL, &_videoTextureCache);
    if (err) {
        NSLog(@">> ERROR: Could not create a texture cache");
        assert(0);
    }
}


#pragma mark RENDER VIEW DELEGATE METHODS

- (void)configure:(APPLView *)view
{
    // 设备，find a usable Device
    _device = view.device;
    
    // setup view with drawable formats
    view.depthPixelFormat   = MTLPixelFormatInvalid;
    view.stencilPixelFormat = MTLPixelFormatInvalid;
    view.sampleCount        = 1;
    
    // create a new command queue，命令提交流程
    _commandQueue = [_device newCommandQueue];
    
    // 库和函数，顶点+分段函数
    // 通过调用device.newDefaultLibrary方法获得的MTLibrary对象访问到你项目中的预编译shaders。然后你能够通过名字检索每个shader。
    _defaultLibrary = [_device newDefaultLibrary];
    if(!_defaultLibrary) {
        NSLog(@">> ERROR: Couldnt create a default shader library");
        // assert here becuase if the shader libary isn't loading, nothing good will happen
        assert(0);
    }
    
    if (![self preparePipelineState:view])
    {
        NSLog(@">> ERROR: Couldnt create a valid pipeline state");
        
        // cannot render anything without a valid compiled pipeline state object.
        assert(0);
    }
    
    // set the vertex shader and buffers defined in the shader source, in this case we have 2 inputs. A position buffer and a color buffer
    // Allocate a buffer to store vertex position data (we'll quad buffer this one)
    _vertexBuffer = [_device newBufferWithBytes: quad length: sizeof(quad) options:0];
    _vertexBuffer.label = @"Vertices";
    
    ////    // Single static buffer for color information
    //    _vertexColorBuffer = [_device newBufferWithBytes: vertexColorData length: sizeof(vertexColorData) options:MTLResourceOptionCPUCacheModeDefault];
    //    _vertexColorBuffer.label = @"colors";
    
    
    quadTex = [[MakeTexture alloc] initWithResourceName:@"lena" extension:@"png"];
    BOOL loaded = [quadTex loadIntoTextureWithDevice:_device];
    if (!loaded) {
        NSLog(@"Failed to load texture");
    }
        [self setVideoTexture];
 
    
}

- (BOOL)preparePipelineState:(APPLView*)view
{
    // load the vertex program into the library，将定点程序加载到库中
    id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:@"texture_vertex"];
    
    // load the fragment program into the library，将片段程序加载到库中
    //    id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:@"passThroughFragment1"];
    id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:@"yuv_rgb"];
    //  create a reusable pipeline state，创建可重用的管道流水线
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
    // A string to help identify this object.
    pipelineStateDescriptor.label = @"MyPipeline";
    // 存储颜色数据附件
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    // 1、每个片段的样本数。
    // 2、仅在附件支持多重采样时使用（即，它们具有type2DMultisample纹理类型）， 如果附件不支持多重采样，那么sampleCount为1，这也是默认值。
    // 3、创建MTLRenderCommandEncoder时，所有附件的纹理的sampleCount必须与此sampleCount属性匹配。
    //    pipelineStateDescriptor.sampleCount      = view.sampleCount;
    
    // 1、在渲染过程中处理单个顶点的可编程函数
    // 2、默认值为nil， 必须始终指定顶点函数。 顶点函数可以是规则顶点函数或后置曲面顶点函数。
    pipelineStateDescriptor.vertexFunction   = vertexProgram;
    
    // 1、在渲染过程中处理单个碎片的可编程函数
    // 2、默认值为nil。 如果此值为nil，则不存在片段函数，因此不会对彩色渲染目标进行写入。 深度和模板写入和可见性结果计数仍然可以继续。
    pipelineStateDescriptor.fragmentFunction = fragmentProgram;
    
    NSError *error = nil;
    // 创建编译的渲染管道
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if(!_pipelineState) {
        NSLog(@">> ERROR: Failed Aquiring pipeline state: %@", error);
        return NO;
    }
    
    // TODO
    // 采样器设置
    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    // 设置采样器集合
    samplerState = [_device newSamplerStateWithDescriptor:samplerDescriptor];
    
   // /*
     _parametersBuffer = [_device newBufferWithLength:sizeof(ColorParameters) * 2 options:MTLResourceOptionCPUCacheModeDefault];
     ColorParameters matrix;
     simd::float3 A;
     simd::float3 B;
     simd::float3 C;
     
     // 1
     //    A.x = 1;
     //    A.y = 1;
     //    A.z = 1;
     //
     //    B.x = 0;
     //    B.y = -0.343;
     //    B.z = 1.765;
     //
     //    C.x = 1.4;
     //    C.y = -0.765;
     //    C.z = 0;
     
     // 2
     //    A.x = 1.164;
     //    A.y = 1.164;
     //    A.z = 1.164;
     //
     //    B.x = 0;
     //    B.y = -0.392;
     //    B.z = 2.017;
     //
     //    C.x = 1.596;
     //    C.y = -0.813;
     //    C.z = 0;
     
     // 3
     A.x = 1.164;
     A.y = 1.164;
     A.z = 1.164;
     
     B.x = 0;
     B.y = -0.231;
     B.z = 2.112;
     
     C.x = 1.793;
     C.y = -0.533;
     C.z = 0;
     
     
     
     matrix.yuvToRGB = simd::float3x3{A, B, C};
     
     memcpy(self.parametersBuffer.contents, &matrix, sizeof(ColorParameters));
     //*/
    
    return YES;
}

- (void)_renderTriangle:(id <MTLRenderCommandEncoder>)renderEncoder
                   view:(APPLView *)view
                   name:(NSString *)name
{
    [renderEncoder pushDebugGroup:name];
    
    //  set context state 指定之前创建的_pipelineState和顶点
    [renderEncoder setRenderPipelineState:_pipelineState];
    
    [renderEncoder setVertexBuffer:_vertexBuffer
                            offset:0
                           atIndex:0 ];
    [renderEncoder setFragmentBuffer:_parametersBuffer offset:0 atIndex:0];
    
    //    [renderEncoder setVertexBuffer:_vertexColorBuffer offset:0 atIndex:1];
    
    //    [renderEncoder setFragmentBuffer:self.parametersBuffer offset:0 atIndex:0];
    [renderEncoder setFragmentSamplerState:samplerState atIndex:0];
    if (!_videoTexture[0] ) {
        [renderEncoder setFragmentTexture:quadTex.texture atIndex:0];
        [renderEncoder setFragmentTexture:quadTex.texture atIndex:1];
    } else {
        
        [renderEncoder setFragmentTexture:_videoTexture[0] atIndex:0];
        [renderEncoder setFragmentTexture:_videoTexture[1] atIndex:1];
    }
    
    
    // tell the render context we want to draw our primitives
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:2];
    
    [renderEncoder popDebugGroup];
}

- (void)render:(APPLView *)view
{
    // Allow the renderer to preflight 3 frames on the CPU (using a semapore as a guard) and commit them to the GPU.
    // This semaphore will get signaled once the GPU completes a frame's work via addCompletedHandler callback below,
    // signifying the CPU can go ahead and prepare another frame.
    // 检测当前信号量访问资源数，如果semaphore的value值为0的时候，线程将被阻塞，否则，semaphore的value值将--
    dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    //
    //
    //    // reset the vertex data in the shared cpu/gpu buffer each frame and just accumulate offsets below
    //    memcpy(vData,vertexData,sizeof(vertexData));
    // create a new command buffer for each renderpass to the current drawable
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // create a render command encoder so we can render into something
    MTLRenderPassDescriptor *renderPassDescriptor = view.renderPassDescriptor;
    if (renderPassDescriptor)
    {
        // 创建一个渲染命令编码器(Render Command Encoder)
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        // 在屏幕坐标系下设置一个区域，该区域是虚拟 3D 场景的投影。视口是 3D，所以它含有深度值
        // 设置窗口
        /*
         MTLViewport viewport;
         viewport.originX = 0;
         viewport.originY = 0;
         viewport.width = 500;
         viewport.height = 500;
         viewport.zfar = 100;
         viewport.znear = 0.1;
         [renderEncoder setViewport: viewport];
         */
        
        [self _renderTriangle:renderEncoder view:view name:@"Quad"];
        [renderEncoder endEncoding];
        
        // schedule a present once the framebuffer is complete
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    // call the view's completion handler which is required by the view since it will signal its semaphore and set up the next buffer
    __block dispatch_semaphore_t block_sema = _inflight_semaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        
        // GPU has completed rendering the frame and is done using the contents of any buffers previously encoded on the CPU for that frame.
        // Signal the semaphore and allow the CPU to proceed and construct the next frame.
        // 发送消息给semaphore,收到消息后，semaphore的value值会++。如果此时线程处于休眠状态，线程会被唤醒，继续处理任务。
        dispatch_semaphore_signal(block_sema);
    }];
    
    // finalize rendering here. this will push the command buffer to the GPU
    [commandBuffer commit];
    
    // This index represents the current portion of the ring buffer being used for a given frame's constant buffer updates.
    // Once the CPU has completed updating a shared CPU/GPU memory buffer region for a frame, this index should be updated so the
    // next portion of the ring buffer can be written by the CPU. Note, this should only be done *after* all writes to any
    // buffers requiring synchronization for a given frame is done in order to avoid writing a region of the ring buffer that the GPU may be reading.
    _constantDataBufferIndex = (_constantDataBufferIndex + 1) % kInFlightCommandBuffers;
}

- (MTLRenderPassDescriptor *)renderPassForDrawable:(id<CAMetalDrawable>)drawable
{
    MTLRenderPassDescriptor *renderPass = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPass.colorAttachments[0].texture = drawable.texture;
    renderPass.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPass.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPass.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1);
    return renderPass;
}


- (void)reshape:(APPLView *)view
{
    // unused in this sample
}



@end
