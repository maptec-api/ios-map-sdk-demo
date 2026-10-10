#import "MTCMapGestureDoubleClickDelayViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>
#import <QuartzCore/QuartzCore.h>

static CLLocationDegrees const MTCGestureDoubleClickInitialLatitude = 1.3521;
static CLLocationDegrees const MTCGestureDoubleClickInitialLongitude = 103.8198;
static double const MTCGestureDoubleClickInitialZoomLevel = 11.5;
static NSUInteger const MTCGestureDoubleClickMaximumLogCount = 30;

@interface MTCMapGestureTapProbeRecognizer : UIGestureRecognizer
@property (nonatomic, copy, nullable) void (^touchHandler)(CGPoint point);
@end

@implementation MTCMapGestureTapProbeRecognizer

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = touches.anyObject;
    if (touch && self.touchHandler) {
        self.touchHandler([touch locationInView:self.view]);
    }
    self.state = UIGestureRecognizerStateFailed;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    self.state = UIGestureRecognizerStateFailed;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.state = UIGestureRecognizerStateFailed;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
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

@end

@interface MTCMapGestureDoubleClickDelayViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) MTCMapGestureTapProbeRecognizer *tapProbeRecognizer;
@property (nonatomic) BOOL customDoubleClickDetectionEnabled;
@property (nonatomic) NSTimeInterval lastTapTimestamp;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, strong) NSMutableArray<NSString *> *tapLogs;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;

@end

@implementation MTCMapGestureDoubleClickDelayViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapGestureDoubleTapDelayScreen;
    self.customDoubleClickDetectionEnabled = YES;
    self.tapLogs = [NSMutableArray array];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureTapProbeRecognizer];
    [self applyLocalizedTexts];
}

#pragma mark - Delegate

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

#pragma mark - Event

- (void)showDoubleClickDelaySettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self doubleClickDelaySections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:NO];
}

- (void)handleMapTouchAtPoint:(CGPoint)point {
    (void)point;
    if (!self.customDoubleClickDetectionEnabled) {
        return;
    }

    NSTimeInterval timestamp = CACurrentMediaTime();
    NSDate *date = [NSDate date];
    BOOL hasPreviousTap = self.lastTapTimestamp > 0.0;
    NSMutableString *message = [NSMutableString stringWithFormat:[self localizedStringForKey:@"gesture_dblclick_log_press"], [self.timeFormatter stringFromDate:date]];
    if (hasPreviousTap) {
        NSTimeInterval interval = timestamp - self.lastTapTimestamp;
        double intervalMilliseconds = round(interval * 1000.0);
        if (interval <= self.mapView.gestureSettings.doubleClickDelay) {
            [message appendFormat:[self localizedStringForKey:@"gesture_dblclick_log_interval_double"], intervalMilliseconds];
        } else {
            [message appendFormat:[self localizedStringForKey:@"gesture_dblclick_log_interval"], intervalMilliseconds];
        }
    }
    self.lastTapTimestamp = hasPreviousTap ? 0.0 : timestamp;

    [self.tapLogs insertObject:message atIndex:0];
    if (self.tapLogs.count > MTCGestureDoubleClickMaximumLogCount) {
        [self.tapLogs removeObjectsInRange:NSMakeRange(MTCGestureDoubleClickMaximumLogCount,
                                                       self.tapLogs.count - MTCGestureDoubleClickMaximumLogCount)];
    }
    [self.settingsSheet reloadData];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCGestureDoubleClickInitialLatitude,
                                                                 MTCGestureDoubleClickInitialLongitude)
                            zoomLevel:MTCGestureDoubleClickInitialZoomLevel];
}

- (void)configureTapProbeRecognizer {
    __weak typeof(self) weakSelf = self;
    self.tapProbeRecognizer = [[MTCMapGestureTapProbeRecognizer alloc] init];
    self.tapProbeRecognizer.cancelsTouchesInView = NO;
    self.tapProbeRecognizer.delaysTouchesBegan = NO;
    self.tapProbeRecognizer.delaysTouchesEnded = NO;
    self.tapProbeRecognizer.touchHandler = ^(CGPoint point) {
        [weakSelf handleMapTouchAtPoint:point];
    };
    [self.mapView addGestureRecognizer:self.tapProbeRecognizer];
}

- (NSArray<ExampleSettingsSection *> *)doubleClickDelaySections {
    __weak typeof(self) weakSelf = self;
    MTCMapGestureSettings *settings = self.mapView.gestureSettings;

    return @[
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"gesture_dblclick_enable"]
                                            getter:^BOOL { return weakSelf.customDoubleClickDetectionEnabled; }
                                            setter:^(BOOL value) {
                weakSelf.customDoubleClickDetectionEnabled = value;
                weakSelf.lastTapTimestamp = 0.0;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"gesture_dblclick_delay"]
                                             minimum:0.1
                                             maximum:1.0
                                                step:0.01
                                              getter:^double { return settings.doubleClickDelay; }
                                              setter:^(double value) { settings.doubleClickDelay = value; }
                                           formatter:^NSString * _Nonnull(double value) {
                return [NSString stringWithFormat:@"%.0f ms", value * 1000.0];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderDoubleClickDelay],
            [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"gesture_dblclick_info"]],
            [ExampleSettingsItem logItemWithTitle:[self localizedStringForKey:@"gesture_dblclick_log_title"]
                                       logsGetter:^NSArray<NSString *> * _Nonnull {
                return [weakSelf.tapLogs copy];
            } clearHandler:^{
                [weakSelf.tapLogs removeAllObjects];
                weakSelf.lastTapTimestamp = 0.0;
            }],
        ]],
    ];
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
    [self showDoubleClickDelaySettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapGestureDoubleClickDelayViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showDoubleClickDelaySettings];
    }
}
@end
