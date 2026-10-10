//
//  MTCMapScreenshotPlaybackViewController.m
//  MaptecMapsExample
//
//  Created by Codex on 2026/9/2.
//

#import "MTCMapScreenshotPlaybackViewController.h"

#import <QuartzCore/QuartzCore.h>

@interface MTCMapScreenshotPlaybackViewController ()

@property (nonatomic, copy) NSArray<NSURL *> *frameURLs;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong, nullable) CADisplayLink *playbackDisplayLink;
@property (nonatomic, assign) NSUInteger currentFrameIndex;

@end

@implementation MTCMapScreenshotPlaybackViewController

- (instancetype)initWithFrameURLs:(NSArray<NSURL *> *)frameURLs {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _frameURLs = [frameURLs copy];
    }
    return self;
}

- (void)dealloc {
    [self stopPlayback];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.blackColor;

    [self configureNavigationItems:YES];
    [self configureImageView];
    [self applyLocalizedTexts];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startPlayback];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopPlayback];
}

#pragma mark - Private

- (void)configureImageView {
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.backgroundColor = UIColor.blackColor;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.clipsToBounds = YES;
    [self.view addSubview:self.imageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.imageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.imageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.imageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.imageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)startPlayback {
    if (self.playbackDisplayLink || self.frameURLs.count == 0) {
        return;
    }

    self.currentFrameIndex = 0;
    [self displayFrameAtIndex:self.currentFrameIndex];
    self.currentFrameIndex = 1;

    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handlePlaybackDisplayLink:)];
    if ([displayLink respondsToSelector:@selector(setPreferredFramesPerSecond:)]) {
        displayLink.preferredFramesPerSecond = 24;
    }
    [displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    self.playbackDisplayLink = displayLink;
}

- (void)stopPlayback {
    [self.playbackDisplayLink invalidate];
    self.playbackDisplayLink = nil;
}

- (void)handlePlaybackDisplayLink:(CADisplayLink *)displayLink {
    (void)displayLink;
    if (self.currentFrameIndex >= self.frameURLs.count) {
        [self stopPlayback];
        return;
    }

    [self displayFrameAtIndex:self.currentFrameIndex];
    self.currentFrameIndex += 1;
}

- (void)displayFrameAtIndex:(NSUInteger)index {
    if (index >= self.frameURLs.count) {
        return;
    }

    NSURL *fileURL = self.frameURLs[index];
    UIImage *image = [UIImage imageWithContentsOfFile:fileURL.path];
    if (image) {
        self.imageView.image = image;
    }
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapScreenshotPlaybackViewController"];
}

@end
