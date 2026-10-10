//
//  MTCMapScreenshotPlaybackViewController.h
//  MaptecMapsExample
//
//  Created by Codex on 2026/9/2.
//

#import "MTCExampleBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTCMapScreenshotPlaybackViewController : MTCExampleBaseViewController

- (instancetype)initWithFrameURLs:(NSArray<NSURL *> *)frameURLs NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
