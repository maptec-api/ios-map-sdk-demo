#import "MTCMapGestureDoubleTapZoomFactorViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const MTCGestureDoubleTapZoomFactorInitialLatitude = 1.3521;
static CLLocationDegrees const MTCGestureDoubleTapZoomFactorInitialLongitude = 103.8198;
static double const MTCGestureDoubleTapZoomFactorInitialZoomLevel = 11.5;
static NSUInteger const MTCGestureDoubleTapZoomFactorMaximumLogCount = 30;
static CGFloat const MTCGestureDoubleTapZoomFactorTapMoveTolerance = 12.0;

@interface MTCMapGestureDoubleTapZoomProbeRecognizer : UIGestureRecognizer

@property (nonatomic) NSTimeInterval maximumIntervalBetweenTaps;
@property (nonatomic, copy, nullable) void (^doubleTapHandler)(void);

@end

@implementation MTCMapGestureDoubleTapZoomProbeRecognizer {
    NSUInteger _trackingTouchCount;
    CGPoint _initialCentroid;
    BOOL _tapInvalidated;
    NSTimeInterval _lastTapTimestamp;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    NSSet<UITouch *> *activeTouches = [event touchesForGestureRecognizer:self];
    _trackingTouchCount = activeTouches.count;
    _initialCentroid = [self centroidForTouches:activeTouches];
    _tapInvalidated = (_trackingTouchCount != 1);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (_tapInvalidated) {
        return;
    }

    NSSet<UITouch *> *activeTouches = [event touchesForGestureRecognizer:self];
    if (activeTouches.count != _trackingTouchCount) {
        _tapInvalidated = YES;
        return;
    }

    CGPoint centroid = [self centroidForTouches:activeTouches];
    CGFloat distance = hypot(centroid.x - _initialCentroid.x, centroid.y - _initialCentroid.y);
    if (distance > MTCGestureDoubleTapZoomFactorTapMoveTolerance) {
        _tapInvalidated = YES;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if ([self activeTouchCountForTouches:[event touchesForGestureRecognizer:self]] > 0) {
        return;
    }

    if (!_tapInvalidated) {
        [self handleCompletedTap];
    }
    self.state = UIGestureRecognizerStateFailed;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    _tapInvalidated = YES;
    self.state = UIGestureRecognizerStateCancelled;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer {
    (void)preventedGestureRecognizer;
    return NO;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer {
    (void)preventingGestureRecognizer;
    return NO;
}

- (void)reset {
    [super reset];
    _trackingTouchCount = 0;
    _initialCentroid = CGPointZero;
    _tapInvalidated = NO;
}

- (void)handleCompletedTap {
    NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate];
    BOOL isDoubleTap = (_lastTapTimestamp > 0.0 &&
                        timestamp - _lastTapTimestamp <= self.maximumIntervalBetweenTaps);
    if (isDoubleTap && self.doubleTapHandler) {
        self.doubleTapHandler();
        _lastTapTimestamp = 0.0;
        return;
    }

    _lastTapTimestamp = timestamp;
}

- (CGPoint)centroidForTouches:(NSSet<UITouch *> *)touches {
    if (touches.count == 0) {
        return CGPointZero;
    }

    CGPoint centroid = CGPointZero;
    for (UITouch *touch in touches) {
        CGPoint point = [touch locationInView:self.view];
        centroid.x += point.x;
        centroid.y += point.y;
    }
    centroid.x /= touches.count;
    centroid.y /= touches.count;
    return centroid;
}

- (NSUInteger)activeTouchCountForTouches:(NSSet<UITouch *> *)touches {
    NSUInteger count = 0;
    for (UITouch *touch in touches) {
        if (touch.phase == UITouchPhaseBegan ||
            touch.phase == UITouchPhaseMoved ||
            touch.phase == UITouchPhaseStationary) {
            count += 1;
        }
    }
    return count;
}

@end

@interface MTCMapGestureDoubleTapZoomFactorViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) MTCMapGestureDoubleTapZoomProbeRecognizer *doubleTapProbeRecognizer;
@property (nonatomic) double currentZoomLevel;
@property (nonatomic) BOOL hasCurrentZoomLevel;
@property (nonatomic) double pendingDoubleTapStartZoomLevel;
@property (nonatomic) BOOL hasPendingDoubleTapZoomLog;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, strong) NSMutableArray<NSString *> *zoomLogs;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;

@end

@implementation MTCMapGestureDoubleTapZoomFactorViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapGestureDoubleTapZoomFactorScreen;
    self.currentZoomLevel = MTCGestureDoubleTapZoomFactorInitialZoomLevel;
    self.hasCurrentZoomLevel = YES;
    self.zoomLogs = [NSMutableArray array];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureDoubleTapProbeRecognizer];
    [self applyLocalizedTexts];
}

#pragma mark - Delegate
#pragma mark -- MTCMapViewDelegate

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView
cameraDidChange:(MTCMapCamera *)camera
         reason:(MTCMapCameraChangeReason)reason
       animated:(BOOL)animated {
    (void)mapView;
    (void)reason;
    (void)animated;
    [self updateCurrentZoomLevelWithCamera:camera];
    [self.settingsSheet reloadData];
}

- (void)mapView:(MTCMapView *)mapView
cameraDidBecomeIdle:(MTCMapCamera *)camera
         reason:(MTCMapCameraChangeReason)reason
       animated:(BOOL)animated {
    (void)mapView;
    (void)reason;
    (void)animated;
    [self updateCurrentZoomLevelWithCamera:camera];
    [self appendPendingDoubleTapZoomLogIfNeededWithZoomLevel:camera.zoomLevel];
    [self.settingsSheet reloadData];
}

#pragma mark - Event

- (void)showDoubleTapZoomFactorSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self doubleTapZoomFactorSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:NO];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCGestureDoubleTapZoomFactorInitialLatitude,
                                                                 MTCGestureDoubleTapZoomFactorInitialLongitude)
                            zoomLevel:MTCGestureDoubleTapZoomFactorInitialZoomLevel];
}

- (void)configureDoubleTapProbeRecognizer {
    __weak typeof(self) weakSelf = self;
    self.doubleTapProbeRecognizer = [[MTCMapGestureDoubleTapZoomProbeRecognizer alloc] init];
    self.doubleTapProbeRecognizer.cancelsTouchesInView = NO;
    self.doubleTapProbeRecognizer.delaysTouchesBegan = NO;
    self.doubleTapProbeRecognizer.delaysTouchesEnded = NO;
    self.doubleTapProbeRecognizer.maximumIntervalBetweenTaps = self.mapView.gestureSettings.doubleClickDelay;
    self.doubleTapProbeRecognizer.doubleTapHandler = ^{
        [weakSelf prepareDoubleTapZoomLog];
    };
    [self.mapView addGestureRecognizer:self.doubleTapProbeRecognizer];
}

- (NSArray<ExampleSettingsSection *> *)doubleTapZoomFactorSections {
    __weak typeof(self) weakSelf = self;
    MTCMapGestureSettings *settings = self.mapView.gestureSettings;

    return @[
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"gesture_zoom_factor_label"]
                                             minimum:1.1
                                             maximum:5.0
                                                step:0.1
                                              getter:^double { return settings.doubleTapZoomFactor; }
                                              setter:^(double value) { settings.doubleTapZoomFactor = value; }
                                           formatter:^NSString * _Nonnull(double value) {
                return [NSString stringWithFormat:@"%.1fx", value];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderDoubleTapZoomFactor],
            [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"gesture_zoom_factor_info1"]],
            [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"gesture_zoom_factor_info2"]],
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString * _Nonnull {
                __strong typeof(weakSelf) self = weakSelf;
                return self ? [self currentZoomLevelText] : [weakSelf localizedStringForKey:@"gesture_zoom_level_unknown"];
            }],
            [ExampleSettingsItem logItemWithTitle:[self localizedStringForKey:@"gesture_zoom_factor_log_title"]
                                       logsGetter:^NSArray<NSString *> * _Nonnull {
                __strong typeof(weakSelf) self = weakSelf;
                return self ? [self.zoomLogs copy] : @[];
            } clearHandler:^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) {
                    return;
                }
                [self.zoomLogs removeAllObjects];
                self.hasPendingDoubleTapZoomLog = NO;
            }],
        ]],
    ];
}

- (void)prepareDoubleTapZoomLog {
    self.pendingDoubleTapStartZoomLevel = self.currentZoomLevel;
    self.hasPendingDoubleTapZoomLog = YES;
}

- (void)updateCurrentZoomLevelWithCamera:(MTCMapCamera *)camera {
    self.currentZoomLevel = camera.zoomLevel;
    self.hasCurrentZoomLevel = YES;
}

- (void)appendPendingDoubleTapZoomLogIfNeededWithZoomLevel:(double)zoomLevel {
    if (!self.hasPendingDoubleTapZoomLog) {
        return;
    }
    self.hasPendingDoubleTapZoomLog = NO;

    double previousZoomLevel = self.pendingDoubleTapStartZoomLevel;
    double delta = zoomLevel - previousZoomLevel;
    if (fabs(delta) < 0.01) {
        return;
    }

    NSString *message = [NSString stringWithFormat:[self localizedStringForKey:@"gesture_zoom_factor_log_line"],
                         [self.timeFormatter stringFromDate:[NSDate date]],
                         previousZoomLevel,
                         zoomLevel,
                         delta];
    [self.zoomLogs insertObject:message atIndex:0];
    if (self.zoomLogs.count > MTCGestureDoubleTapZoomFactorMaximumLogCount) {
        [self.zoomLogs removeObjectsInRange:NSMakeRange(MTCGestureDoubleTapZoomFactorMaximumLogCount,
                                                        self.zoomLogs.count - MTCGestureDoubleTapZoomFactorMaximumLogCount)];
    }
}

- (NSString *)currentZoomLevelText {
    if (!self.hasCurrentZoomLevel) {
        return [self localizedStringForKey:@"gesture_zoom_level_unknown"];
    }
    return [NSString stringWithFormat:[self localizedStringForKey:@"gesture_zoom_level_value"], self.currentZoomLevel];
}

- (NSDateFormatter *)timeFormatter {
    if (_timeFormatter) {
        return _timeFormatter;
    }

    _timeFormatter = [[NSDateFormatter alloc] init];
    _timeFormatter.dateFormat = @"HH:mm:ss.SSS";
    return _timeFormatter;
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showDoubleTapZoomFactorSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapGestureDoubleTapZoomFactorViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showDoubleTapZoomFactorSettings];
    }
}
@end
