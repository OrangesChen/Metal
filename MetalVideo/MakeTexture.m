//
//  MakeTexture.m
//  MetalVideo
//
//  Created by cfq on 2016/11/22.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

#import "MakeTexture.h"


@interface MakeTexture ()
@property (readwrite) id <MTLTexture> texture;
@property (readwrite) uint32_t width;
@property (readwrite) uint32_t height;
@property (readwrite) uint32_t pixelFormat;
@property (readwrite) uint32_t target;
@property (readwrite) BOOL hasAlpha;
@end

@implementation MakeTexture

- (id)initWithResourceName:(NSString *)name extension:(NSString *)ext {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:ext];
    if (!path)
        return nil;
    
    self = [super init];
    if (self) {
        _pathToTextureFile = path;
        _width = _height = 0;
        _depth = 1;
    }
    return self;
}

- (BOOL)loadIntoTextureWithDevice:(id<MTLDevice>)device {
    UIImage *image = [UIImage imageWithContentsOfFile:self.pathToTextureFile];
    if (!image) {
        return NO;
    }
    self.width = (uint32_t)CGImageGetWidth(image.CGImage);
    self.height = (uint32_t)CGImageGetHeight(image.CGImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, self.width, self.height, 8, 4 * self.width, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, self.width, self.height), image.CGImage);
    MTLTextureDescriptor *texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:self.width height:self.height mipmapped:NO];
    self.target = texDesc.textureType;
    self.texture = [device newTextureWithDescriptor:texDesc];
    if (!self.texture) {
        return NO;
    }
    
    [self.texture replaceRegion:MTLRegionMake2D(0, 0, self.width, self.height) mipmapLevel:0 withBytes:CGBitmapContextGetData(context) bytesPerRow:4 * self.width];
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    return YES;
    
}




@end
