//
//  MTCMapEventListViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/10.
//

#import "MTCMapEventListViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const MTCMapEventInitialLatitude = 1.3521;
static CLLocationDegrees const MTCMapEventInitialLongitude = 103.8198;
static double const MTCMapEventInitialZoomLevel = 11.5;

@interface MTCMapEventListViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) NSMutableArray<NSString *> *logs;
@property (nonatomic) BOOL cameraMovingLogEnabled;
@property (nonatomic) BOOL mapLongPressLogEnabled;
@property (nonatomic) BOOL flingLogEnabled;
@property (nonatomic) BOOL cameraIdleLogEnabled;
@property (nonatomic) BOOL cameraStartLogEnabled;
@property (nonatomic) BOOL mapTapLogEnabled;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;

@end

@implementation MTCMapEventListViewController

- (void)dealloc {
}
#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapEventScreen;
    self.logs = [[NSMutableArray alloc] init];
    self.cameraMovingLogEnabled = YES;
    self.mapLongPressLogEnabled = YES;
    self.flingLogEnabled = YES;
    self.cameraIdleLogEnabled = YES;
    self.cameraStartLogEnabled = YES;
    self.mapTapLogEnabled = YES;

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self applyLocalizedTexts];
}

#pragma mark - protocol

#pragma mark - Delegate
#pragma mark -- MTCMapViewDelegate

- (void)mapView:(MTCMapView *)mapView cameraWillChangeWithReason:(MTCMapCameraChangeReason)reason animated:(BOOL)animated {
    (void)mapView;
    if (!self.cameraStartLogEnabled) {
        return;
    }
    [self appendLog:[NSString stringWithFormat:@"视角开始移动 reason=%@ animated=%@", [self cameraReasonText:reason], animated ? @"YES" : @"NO"]];
}

- (void)mapView:(MTCMapView *)mapView cameraDidChange:(MTCMapCamera *)camera reason:(MTCMapCameraChangeReason)reason animated:(BOOL)animated {
    (void)mapView;
    if (!self.cameraMovingLogEnabled) {
        return;
    }
    [self appendLog:[NSString stringWithFormat:@"地图视角移动中 lat=%.5f lng=%.5f zoom=%.2f reason=%@ animated=%@",
                     camera.centerCoordinate.latitude,
                     camera.centerCoordinate.longitude,
                     camera.zoomLevel,
                     [self cameraReasonText:reason],
                     animated ? @"YES" : @"NO"]];
}

- (void)mapView:(MTCMapView *)mapView
cameraDidBecomeIdle:(MTCMapCamera *)camera
         reason:(MTCMapCameraChangeReason)reason
       animated:(BOOL)animated {
    (void)mapView;
    if (!self.cameraIdleLogEnabled) {
        return;
    }
    [self appendLog:[NSString stringWithFormat:@"视角停止移动 lat=%.5f lng=%.5f zoom=%.2f reason=%@ animated=%@",
                     camera.centerCoordinate.latitude,
                     camera.centerCoordinate.longitude,
                     camera.zoomLevel,
                     [self cameraReasonText:reason],
                     animated ? @"YES" : @"NO"]];
}

- (void)mapView:(MTCMapView *)mapView didStartFlingWithVelocity:(CGPoint)velocity {
    (void)mapView;
    if (!self.flingLogEnabled) {
        return;
    }
    [self appendLog:[NSString stringWithFormat:@"快速滑动开始 velocity=(%.1f, %.1f)", velocity.x, velocity.y]];
}

- (void)mapViewDidEndFling:(MTCMapView *)mapView {
    (void)mapView;
    if (!self.flingLogEnabled) {
        return;
    }
    [self appendLog:@"快速滑动结束"];
}

- (void)mapView:(MTCMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    (void)mapView;
    if (!self.mapTapLogEnabled) {
        return;
    }
    [self appendLog:[NSString stringWithFormat:@"地图点击事件 lat=%.5f lng=%.5f", coordinate.latitude, coordinate.longitude]];
}

- (void)mapView:(MTCMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
    (void)mapView;
    if (!self.mapLongPressLogEnabled) {
        return;
    }
    [self appendLog:[NSString stringWithFormat:@"地图长按 lat=%.5f lng=%.5f", coordinate.latitude, coordinate.longitude]];
}

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

#pragma mark - Event

- (void)showEventSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self eventSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:NO];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCMapEventInitialLatitude, MTCMapEventInitialLongitude)
                            zoomLevel:MTCMapEventInitialZoomLevel];
}

- (NSArray<ExampleSettingsSection *> *)eventSections {
    __weak typeof(self) weakSelf = self;

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"event_section_control"] items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"event_camera_moving"]
                                             getter:^BOOL {
                __strong typeof(weakSelf) self = weakSelf;
                return self.cameraMovingLogEnabled;
            } setter:^(BOOL value) {
                __strong typeof(weakSelf) self = weakSelf;
                self.cameraMovingLogEnabled = value;
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchCameraMove],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"event_long_press"]
                                             getter:^BOOL {
                __strong typeof(weakSelf) self = weakSelf;
                return self.mapLongPressLogEnabled;
            } setter:^(BOOL value) {
                __strong typeof(weakSelf) self = weakSelf;
                self.mapLongPressLogEnabled = value;
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchMapLongClick],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"event_fling"]
                                             getter:^BOOL {
                __strong typeof(weakSelf) self = weakSelf;
                return self.flingLogEnabled;
            } setter:^(BOOL value) {
                __strong typeof(weakSelf) self = weakSelf;
                self.flingLogEnabled = value;
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchFling],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"event_camera_idle"]
                                             getter:^BOOL {
                __strong typeof(weakSelf) self = weakSelf;
                return self.cameraIdleLogEnabled;
            } setter:^(BOOL value) {
                __strong typeof(weakSelf) self = weakSelf;
                self.cameraIdleLogEnabled = value;
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchCameraIdle],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"event_camera_will_move"]
                                             getter:^BOOL {
                __strong typeof(weakSelf) self = weakSelf;
                return self.cameraStartLogEnabled;
            } setter:^(BOOL value) {
                __strong typeof(weakSelf) self = weakSelf;
                self.cameraStartLogEnabled = value;
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchCameraMoveStarted],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"event_map_click"]
                                             getter:^BOOL {
                __strong typeof(weakSelf) self = weakSelf;
                return self.mapTapLogEnabled;
            } setter:^(BOOL value) {
                __strong typeof(weakSelf) self = weakSelf;
                self.mapTapLogEnabled = value;
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchMapClick],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"common_section_log"] items:@[
            [ExampleSettingsItem logItemWithTitle:@""
                                       logsGetter:^NSArray<NSString *> * _Nonnull {
                __strong typeof(weakSelf) self = weakSelf;
                return self.logs.copy;
            } clearHandler:nil],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"common_clear"] handler:^{
                __strong typeof(weakSelf) self = weakSelf;
                [self.logs removeAllObjects];
                [self.settingsSheet reloadData];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityBtnClearLogs],
        ]],
    ];
}

- (void)appendLog:(NSString *)log {
    if (log.length == 0) {
        return;
    }

    [self.logs insertObject:[NSString stringWithFormat:@"%@  %@", [self currentTimeText], log] atIndex:0];
    if (self.logs.count > 120) {
        [self.logs removeObjectsInRange:NSMakeRange(120, self.logs.count - 120)];
    }
    [self.settingsSheet reloadData];
}

- (NSString *)currentTimeText {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm:ss.SSS";
    return [formatter stringFromDate:[NSDate date]];
}

- (NSString *)cameraReasonText:(MTCMapCameraChangeReason)reason {
    switch (reason) {
        case MTCMapCameraChangeReasonProgrammatic:
            return @"programmatic";
        case MTCMapCameraChangeReasonGesture:
            return @"gesture";
        case MTCMapCameraChangeReasonInitial:
            return @"initial";
        case MTCMapCameraChangeReasonUnknown:
        default:
            return @"unknown";
    }
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showEventSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapEventListViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showEventSettings];
    }
}

#pragma mark - Getter & Setter

@end
