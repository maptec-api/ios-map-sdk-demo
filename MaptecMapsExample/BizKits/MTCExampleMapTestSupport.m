#import "MTCExampleMapTestSupport.h"

#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>
#import <QuartzCore/QuartzCore.h>

@interface MTCExampleMapTestSupport ()
@property (nonatomic, strong, readwrite) UIView *mapRenderedTestView;
@property (nonatomic, strong, readwrite) UIView *overlayCountTestView;
@property (nonatomic, strong, readwrite, nullable) UIView *overlayPresenceTestView;
@end

@implementation MTCExampleMapTestSupport

- (instancetype)init {
    self = [super init];
    if (self) {
        _overlayCountValueKey = MTCExampleTestAccessibilityMarkerCountValueKey;
        _mapStateIdentifier = MTCExampleTestAccessibilityMapView;
    }
    return self;
}

- (void)installOnHostView:(UIView *)hostView {
    if (!hostView) {
        return;
    }
    if (!self.overlayCountTestView) {
        self.overlayCountTestView = [self makeHiddenTestViewWithIdentifier:self.mapStateIdentifier originX:0.0];
        [hostView addSubview:self.overlayCountTestView];
    }
    if (self.overlayPresenceIdentifier.length > 0 && !self.overlayPresenceTestView) {
        self.overlayPresenceTestView =
            [self makeHiddenTestViewWithIdentifier:self.overlayPresenceIdentifier originX:2.0];
        [hostView addSubview:self.overlayPresenceTestView];
    }
    if (!self.mapRenderedTestView) {
        self.mapRenderedTestView =
            [self makeHiddenTestViewWithIdentifier:MTCExampleTestAccessibilityMapRendered originX:4.0];
        self.mapRenderedTestView.isAccessibilityElement = NO;
        self.mapRenderedTestView.accessibilityElementsHidden = YES;
        [hostView addSubview:self.mapRenderedTestView];
    }
}

- (void)markMapRenderedReady {
    if (self.mapRenderedTestView) {
        self.mapRenderedTestView.isAccessibilityElement = YES;
        self.mapRenderedTestView.accessibilityElementsHidden = NO;
        if (self.mapRenderedTestView.superview) {
            [self.mapRenderedTestView.superview bringSubviewToFront:self.mapRenderedTestView];
        }
    }
}

- (void)clearMapRenderedReady {
    if (self.mapRenderedTestView) {
        self.mapRenderedTestView.isAccessibilityElement = NO;
        self.mapRenderedTestView.accessibilityElementsHidden = YES;
    }
}

- (void)pauseMapRenderingIfUITesting:(MTCMapView *)mapView {
    if (![NSProcessInfo.processInfo.arguments containsObject:MTCExampleTestAccessibilityUITestingArgument]) {
        return;
    }
    if (!mapView) {
        return;
    }
    @try {
        id link = [mapView valueForKey:@"displayLink"];
        if ([link isKindOfClass:[CADisplayLink class]]) {
            ((CADisplayLink *)link).paused = YES;
        }
    } @catch (__unused NSException *exception) {
    }
}

- (void)syncOverlayCount:(NSUInteger)count {
    if (self.overlayCountTestView) {
        self.overlayCountTestView.accessibilityValue =
            [NSString stringWithFormat:@"%@:%lu", self.overlayCountValueKey, (unsigned long)count];
        if (self.overlayCountTestView.superview) {
            [self.overlayCountTestView.superview bringSubviewToFront:self.overlayCountTestView];
        }
    }
    if (self.overlayPresenceTestView) {
        BOOL hasOverlays = count > 0;
        self.overlayPresenceTestView.isAccessibilityElement = hasOverlays;
        self.overlayPresenceTestView.accessibilityElementsHidden = !hasOverlays;
        if (hasOverlays && self.overlayPresenceTestView.superview) {
            [self.overlayPresenceTestView.superview bringSubviewToFront:self.overlayPresenceTestView];
        }
    }
}

#pragma mark - Private

- (UIView *)makeHiddenTestViewWithIdentifier:(NSString *)identifier originX:(CGFloat)originX {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(originX, 0.0, 2.0, 2.0)];
    view.isAccessibilityElement = YES;
    view.accessibilityIdentifier = identifier;
    view.alpha = 0.01;
    view.userInteractionEnabled = NO;
    return view;
}

@end
