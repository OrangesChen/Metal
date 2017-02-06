//
//  APPLViewController.h
//  MetalVertex
//
//  Created by cfq on 2016/10/24.
//  Copyright © 2016年 Dlodlo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol APPLViewControllerDelegate;

@interface APPLViewController : UIViewController
@property (nonatomic, assign) id<APPLViewControllerDelegate> delegate;

// the time interval from the last draw
@property (nonatomic, readonly) NSTimeInterval timeSinceLastDraw;

// What vsync refresh interval to fire at. (Sets CADisplayLink frameinterval property)
// set to 1 by default, which is the CADisplayLink default setting (60 FPS).
// Setting to 2, will cause gameloop to trigger every other vsync (throttling to 30 FPS)
@property (nonatomic) NSUInteger interval;

// Used to pause and resume the controller.
@property (nonatomic, getter=isPaused) BOOL paused;

// used to fire off the main game loop
- (void)dispatchGameLoop;

// use invalidates the main game loop. when the app is set to terminate
- (void)stopGameLoop;

@end

// required view controller delegate functions.
@protocol APPLViewControllerDelegate <NSObject>
@required

// Note this method is called from the thread the main game loop is run
- (void)update:(APPLViewController *)controller;

// called whenever the main game loop is paused, such as when the app is backgrounded
- (void)viewController:(APPLViewController *)controller willPause:(BOOL)pause;
@end
