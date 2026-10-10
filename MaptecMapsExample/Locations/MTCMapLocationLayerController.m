//
//  MTCMapLocationLayerController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/10.
//

#import "MTCMapLocationLayerController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"
#import "MTCMockRouteLocationProvider.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static NSString *const MTCMapLocationLayerCustomBearingImageName = @"navi_custom";

@interface MTCMapLocationLayerController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong, nullable) UIButton *restoreFollowButton;
@property (nonatomic, assign) NSInteger markerRenderModeIndex;
@property (nonatomic, assign) NSInteger markerBearingSourceIndex;
@property (nonatomic, assign) NSInteger locationTrackingModeIndex;
@property (nonatomic, assign) NSInteger bearingTrackingModeIndex;
@property (nonatomic, assign) CGFloat accuracyAlpha;
@property (nonatomic, assign) NSInteger mockRouteIndex;
@property (nonatomic, assign, getter=isMockSmoothingEnabled) BOOL mockSmoothingEnabled;
@property (nonatomic, assign) BOOL followPausedByGesture;
@property (nonatomic, strong, nullable) MTCMockRouteLocationProvider *mockLocationProvider;
@property (nonatomic, strong, nullable) MTCPolyline *mockRoutePolyline;
@property (nonatomic, weak, nullable) ExampleSettingsSheetView *settingsSheet;

@end

@interface MTCMapLocationLayerController ()
- (void)applyLocationTrackingMode:(MTCUserLocationTrackingMode)mode;
- (void)applyBearingTrackingMode:(MTCUserBearingTrackingMode)mode;
@end

@implementation MTCMapLocationLayerController

- (void)dealloc {
    [self clearMockLocationProvider];
    [self removeMockRoutePolyline];
}
#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapLocationScreen;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self applyLocalizedTexts];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.isMovingFromParentViewController ||
        self.isBeingDismissed ||
        self.navigationController.isBeingDismissed) {
        [self clearMockLocationProvider];
        [self removeMockRoutePolyline];
    }
}

#pragma mark - protocol

#pragma mark - Delegate

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    dispatch_async(dispatch_get_main_queue(), ^{
        (void)mapView;
        [self.mapTestSupport markMapRenderedReady];
        [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    });
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    dispatch_async(dispatch_get_main_queue(), ^{
        (void)mapView;
        (void)mapStyleID;
        [self.mapTestSupport markMapRenderedReady];
        [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    });
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    dispatch_async(dispatch_get_main_queue(), ^{
        (void)mapView;
        (void)mapStyleID;
        [self.mapTestSupport markMapRenderedReady];
        [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    });
}

- (void)mapView:(MTCMapView *)mapView
didChangeUserLocationTrackingMode:(MTCUserLocationTrackingMode)mode
       animated:(BOOL)animated {
    (void)mapView;
    (void)animated;
    self.locationTrackingModeIndex = mode;
    if (mode != MTCUserLocationTrackingModeNone) {
        self.followPausedByGesture = NO;
    }
    [self updateRestoreFollowButtonVisibility];
    [self.settingsSheet refreshVisibleItems];
}

- (void)mapView:(MTCMapView *)mapView
didChangeUserBearingTrackingMode:(MTCUserBearingTrackingMode)mode
       animated:(BOOL)animated {
    (void)mapView;
    (void)animated;
    self.bearingTrackingModeIndex = mode;
    if (mode != MTCUserBearingTrackingModeNone) {
        self.followPausedByGesture = NO;
    }
    [self updateRestoreFollowButtonVisibility];
    [self.settingsSheet refreshVisibleItems];
}
- (void)mapView:(MTCMapView *)mapView
cameraWillChangeWithReason:(MTCMapCameraChangeReason)reason
                animated:(BOOL)animated {
    (void)mapView;
    (void)animated;
    if (reason != MTCMapCameraChangeReasonGesture) {
        return;
    }
    [self pauseFollowModesForManualGestureIfNeeded];
}

- (void)mapView:(MTCMapView *)mapView didChangeUserLocationTrackingMode:(MTCUserLocationTrackingMode)mode {
    (void)mapView;
    self.locationTrackingModeIndex = mode;
    if (mode != MTCUserLocationTrackingModeNone) {
        self.followPausedByGesture = NO;
    }
    [self updateRestoreFollowButtonVisibility];
    [self.settingsSheet refreshVisibleItems];
//    if (mode == MTCUserLocationTrackingModeNone) {
//        return;
//    }

    NSArray<NSString *> *titles = [self locationTrackingModeTitles];
    if (mode >= 0 && mode < (NSInteger)titles.count) {
        NSLog(@"Location tracking: %@", titles[(NSUInteger)mode]);
//        [MTCExampleToastView showMessage:[NSString stringWithFormat:@"Location tracking: %@", titles[(NSUInteger)mode]]
//                                 inView:self.view];
    }
}

- (void)mapView:(MTCMapView *)mapView didChangeUserBearingTrackingMode:(MTCUserBearingTrackingMode)mode {
    (void)mapView;
    self.bearingTrackingModeIndex = mode;
    [self updateRestoreFollowButtonVisibility];
    [self.settingsSheet refreshVisibleItems];
//    if (mode == MTCUserBearingTrackingModeNone) {
//        return;
//    }

    NSArray<NSString *> *titles = [self bearingTrackingModeTitles];
    if (mode >= 0 && mode < (NSInteger)titles.count) {
        NSLog(@"Bearing tracking: %@", titles[(NSUInteger)mode]);

//        [MTCExampleToastView showMessage:[NSString stringWithFormat:@"Bearing tracking: %@", titles[(NSUInteger)mode]]
//                                 inView:self.view];
    }
}

#pragma mark - Event
- (void)showLocationSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"demo_title_MTCMapLocationLayerController"]
                                               sections:[self locationSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:NO];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    [self configureRestoreFollowButton];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(31.2304, 121.4737) zoomLevel:16];

    self.mapView.uiSettings.permitShowAll = YES;
    self.mapView.uiSettings.compassEnabled = YES;
    self.mapView.uiSettings.scaleBarEnabled = NO;
    self.mapView.uiSettings.logoGravity = MTCUIPositionBottom | MTCUIPositionLeft;
    self.mapView.uiSettings.zoomButtonsEnabled = YES;
    self.mapView.uiSettings.locationViewEnabled = YES;
    self.mapView.uiSettings.locationViewGravity = MTCUIPositionBottom | MTCUIPositionRight;
    self.mapView.uiSettings.locationViewSize = CGSizeMake(40.0, 40.0);
    self.mapView.uiSettings.locationViewMargins = UIEdgeInsetsMake(4.0, 4.0, 4.0, 4.0);
    self.mapView.showsUserLocation = YES;

    MTCUserLocationConfig *locationConfig = [[MTCUserLocationConfig alloc] init];
    locationConfig.renderMode = MTCUserLocationRenderModeHeading;
    locationConfig.locationTrackingMode = MTCUserLocationTrackingModeNone;
    locationConfig.bearingTrackingMode = MTCUserBearingTrackingModeNone;
    locationConfig.accuracyCircleAlpha = 0.30;
    self.mapView.userLocationConfig = locationConfig;

    self.markerRenderModeIndex = locationConfig.renderMode;
    self.markerBearingSourceIndex = locationConfig.markerBearingSource;
    self.locationTrackingModeIndex = locationConfig.locationTrackingMode;
    self.bearingTrackingModeIndex = locationConfig.bearingTrackingMode;
    self.accuracyAlpha = locationConfig.accuracyCircleAlpha;
    self.mockRouteIndex = 0;
    self.mockSmoothingEnabled = YES;
    self.followPausedByGesture = NO;
}

- (NSArray<ExampleSettingsSection *> *)locationSections {
    __weak typeof(self) weakSelf = self;
    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"location_layer_mock_section"] items:@[
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"location_layer_mock_source"]
                                           options:[self mockRouteTitles]
                                            getter:^NSInteger { return weakSelf.mockRouteIndex; }
                                            setter:^(NSInteger index) {
                [weakSelf selectMockRouteAtIndex:index];
            }],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"location_layer_mock_smoothing"]
                                            getter:^BOOL { return weakSelf.isMockSmoothingEnabled; }
                                            setter:^(BOOL value) {
                if ([weakSelf mockPlaybackHasStarted]) {
                    [weakSelf.settingsSheet refreshVisibleItems];
                    return;
                }
                weakSelf.mockSmoothingEnabled = value;
                [weakSelf applyMockSmoothingMode];
                [weakSelf.settingsSheet refreshVisibleItems];
            }] enabledWhen:^BOOL {
                return ![weakSelf mockPlaybackHasStarted];
            }],
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return [weakSelf mockStatusText];
            }],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"location_layer_mock_replay"]
                                             handler:^{
                [weakSelf replayMockLocation];
            }] enabledWhen:^BOOL {
                return weakSelf.mockLocationProvider != nil;
            }],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"location_layer_mock_stop"]
                                             handler:^{
                [weakSelf selectMockRouteAtIndex:0];
            }] enabledWhen:^BOOL {
                return weakSelf.mockLocationProvider != nil;
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"demo_title_MTCMapLocationLayerController"] items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"location_layer_show_marker"]
                                            getter:^BOOL { return weakSelf.mapView.showsUserLocation; }
                                            setter:^(BOOL value) {
                weakSelf.mapView.showsUserLocation = value;
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchLocationComponentEnabled],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"location_layer_accuracy_alpha"]
                                             minimum:0.0
                                             maximum:1.0
                                                step:0.05
                                              getter:^double { return weakSelf.accuracyAlpha; }
                                              setter:^(double value) {
                weakSelf.accuracyAlpha = (CGFloat)value;
                MTCUserLocationConfig *config = [weakSelf.mapView.userLocationConfig copy];
                config.accuracyCircleAlpha = (CGFloat)value;
                weakSelf.mapView.userLocationConfig = config;
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.2f", value];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderAccuracyAlpha],
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"location_layer_marker_style"]
                                           options:@[
                                               [self localizedStringForKey:@"location_layer_marker_normal"],
                                               [self localizedStringForKey:@"location_layer_marker_heading"],
                                               [self localizedStringForKey:@"location_layer_marker_custom"],
                                           ]
                                            getter:^NSInteger { return weakSelf.markerRenderModeIndex; }
                                            setter:^(NSInteger index) {
                weakSelf.markerRenderModeIndex = index;
                MTCUserLocationConfig *config = [weakSelf.mapView.userLocationConfig copy];
                config.renderMode = (MTCUserLocationRenderMode)index;
                [weakSelf applyCustomMarkerImageSetIfNeededForConfig:config];
                weakSelf.mapView.userLocationConfig = config;
            }],
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"location_layer_marker_bearing_source"]
                                           options:[self markerBearingSourceTitles]
                                            getter:^NSInteger { return weakSelf.markerBearingSourceIndex; }
                                            setter:^(NSInteger index) {
                weakSelf.markerBearingSourceIndex = index;
                MTCUserLocationConfig *config = [weakSelf.mapView.userLocationConfig copy];
                config.markerBearingSource = (MTCUserLocationMarkerBearingSource)index;
                weakSelf.mapView.userLocationConfig = config;
            }],
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"location_layer_tracking"]
                                           options:[self locationTrackingModeTitles]
                                            getter:^NSInteger { return weakSelf.locationTrackingModeIndex; }
                                            setter:^(NSInteger index) {
                [weakSelf applyLocationTrackingMode:(MTCUserLocationTrackingMode)index];
            }],
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"location_layer_bearing_tracking"]
                                           options:[self bearingTrackingModeTitles]
                                            getter:^NSInteger { return weakSelf.bearingTrackingModeIndex; }
                                            setter:^(NSInteger index) {
                [weakSelf applyBearingTrackingMode:(MTCUserBearingTrackingMode)index];
            }],
        ]],
    ];
}

- (NSArray<NSString *> *)mockRouteIDs {
    return @[
        @"",
        @"driving_city_roads",
        @"driving_expressway",
        @"cycling_city_roads",
        @"walking_city_roads",
    ];
}

- (NSArray<NSString *> *)mockRouteTitles {
    return @[
        [self localizedStringForKey:@"location_layer_mock_off"],
        [self localizedStringForKey:@"location_layer_mock_driving_city"],
        [self localizedStringForKey:@"location_layer_mock_driving_expressway"],
        [self localizedStringForKey:@"location_layer_mock_cycling_city"],
        [self localizedStringForKey:@"location_layer_mock_walking_city"],
    ];
}

- (void)selectMockRouteAtIndex:(NSInteger)index {
    NSArray<NSString *> *routeIDs = [self mockRouteIDs];
    if (index < 0 || index >= (NSInteger)routeIDs.count) {
        return;
    }

    [self clearMockLocationProvider];
    [self removeMockRoutePolyline];
    self.mockRouteIndex = index;

    if (index == 0) {
        [self.settingsSheet refreshVisibleItems];
        return;
    }

    NSString *routeID = routeIDs[(NSUInteger)index];
    MTCMockRouteLocationProvider *provider = [[MTCMockRouteLocationProvider alloc] initWithRouteID:routeID];
    __weak typeof(self) weakSelf = self;
    provider.statusDidChangeHandler = ^(MTCMockRouteLocationProvider *statusProvider) {
        if (statusProvider.isFinished) {
            [weakSelf resetMockCameraPadding];
        }
        [weakSelf.settingsSheet refreshVisibleItems];
    };

    self.mockLocationProvider = provider;
    self.mapView.showsUserLocation = YES;
    [self applyMockCameraPadding];
    [self applyMockFollowCourseTrackingModes];
    if (CLLocationCoordinate2DIsValid(provider.firstCoordinate)) {
        double zoomLevel = [routeID isEqualToString:@"driving_expressway"] ? 13.0 : 15.5;
        [self.mapView setCenterCoordinate:provider.firstCoordinate zoomLevel:zoomLevel];
    }
    [self showMockRoutePolylineForProvider:provider];
    [self applyMockSmoothingMode];
    self.mapView.userLocationProvider = provider;
    [self.settingsSheet refreshVisibleItems];
}

- (void)replayMockLocation {
    [self applyMockCameraPadding];
    [self.mockLocationProvider restart];
}

- (void)pauseFollowModesForManualGestureIfNeeded {
    MTCUserLocationConfig *currentConfig = [self.mapView.userLocationConfig copy] ?: [[MTCUserLocationConfig alloc] init];
    if (currentConfig.locationTrackingMode == MTCUserLocationTrackingModeNone &&
        currentConfig.bearingTrackingMode == MTCUserBearingTrackingModeNone) {
        return;
    }

    self.followPausedByGesture = YES;
    self.locationTrackingModeIndex = MTCUserLocationTrackingModeNone;
    self.bearingTrackingModeIndex = MTCUserBearingTrackingModeNone;
    currentConfig.locationTrackingMode = MTCUserLocationTrackingModeNone;
    currentConfig.bearingTrackingMode = MTCUserBearingTrackingModeNone;
    self.mapView.userLocationConfig = currentConfig;
    [self updateRestoreFollowButtonVisibility];
    [self.settingsSheet refreshVisibleItems];
}

- (void)restoreFollowModes {
    MTCMapCamera *currentCamera = self.mapView.camera;
    CLLocation *location = self.mapView.userLocation.location;
    if (!currentCamera || !location || !CLLocationCoordinate2DIsValid(location.coordinate)) {
        return;
    }

    CLLocationDirection bearing = currentCamera.bearing;
    if (location.course >= 0.0 && location.course <= 360.0) {
        bearing = location.course;
    }

    MTCMapCamera *targetCamera = [MTCMapCamera cameraWithCenterCoordinate:location.coordinate
                                                                zoomLevel:16
                                                                  bearing:bearing
                                                                    pitch:0];
    __weak typeof(self) weakSelf = self;
    [self.mapView setCamera:targetCamera
                 transition:[MTCCameraTransition easeWithDuration:0.6]
                 completion:^(__unused BOOL finished) {
        if (!finished) {
            return;
        }
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }

        MTCUserLocationConfig *currentConfig = [self.mapView.userLocationConfig copy] ?: [[MTCUserLocationConfig alloc] init];
        currentConfig.locationTrackingMode = MTCUserLocationTrackingModeFollow;
        currentConfig.bearingTrackingMode = MTCUserBearingTrackingModeCourse;
        self.mapView.userLocationConfig = currentConfig;
        self.followPausedByGesture = NO;
        self.locationTrackingModeIndex = MTCUserLocationTrackingModeFollow;
        self.bearingTrackingModeIndex = MTCUserBearingTrackingModeCourse;
        [self updateRestoreFollowButtonVisibility];
        [self.settingsSheet refreshVisibleItems];
        [MTCExampleToastView showMessage:@"Restore follow complete" inView:self.view];
    }];
}

- (void)applyLocationTrackingMode:(MTCUserLocationTrackingMode)mode {
    self.locationTrackingModeIndex = mode;
    MTCUserLocationConfig *config = [self.mapView.userLocationConfig copy] ?: [[MTCUserLocationConfig alloc] init];
    config.locationTrackingMode = mode;
    self.mapView.userLocationConfig = config;
    if (mode != MTCUserLocationTrackingModeNone) {
        self.followPausedByGesture = NO;
    }
    [self updateRestoreFollowButtonVisibility];
    [self.settingsSheet refreshVisibleItems];
}

- (void)applyBearingTrackingMode:(MTCUserBearingTrackingMode)mode {
    self.bearingTrackingModeIndex = mode;
    MTCUserLocationConfig *config = [self.mapView.userLocationConfig copy] ?: [[MTCUserLocationConfig alloc] init];
    config.bearingTrackingMode = mode;
    self.mapView.userLocationConfig = config;
    if (mode != MTCUserBearingTrackingModeNone) {
        self.followPausedByGesture = NO;
    }
    [self updateRestoreFollowButtonVisibility];
    [self.settingsSheet refreshVisibleItems];
}

- (void)applyCustomMarkerImageSetIfNeededForConfig:(MTCUserLocationConfig *)config {
    if (config.renderMode != MTCUserLocationRenderModeCustom) {
        config.customMarkerImageSet = nil;
        return;
    }

    MTCUserLocationMarkerImageSet *imageSet = [[MTCUserLocationMarkerImageSet alloc] init];
    imageSet.bearingImage = [UIImage imageNamed:MTCMapLocationLayerCustomBearingImageName];
    config.customMarkerImageSet = imageSet;
}

- (BOOL)mockPlaybackHasStarted {
    MTCMockRouteLocationProvider *provider = self.mockLocationProvider;
    return provider && (provider.isUpdating || provider.isFinished || provider.currentPointIndex >= 0);
}

- (void)applyMockSmoothingMode {
    if (!self.mockLocationProvider) {
        return;
    }
    self.mapView.userLocationSmoothingMode = self.mockSmoothingEnabled
        ? MTCUserLocationSmoothingModeBuffered
        : MTCUserLocationSmoothingModeDefault;
}

- (void)applyMockFollowCourseTrackingModes {
    MTCUserLocationConfig *currentConfig = [self.mapView.userLocationConfig copy] ?: [[MTCUserLocationConfig alloc] init];
    self.followPausedByGesture = NO;
    self.locationTrackingModeIndex = MTCUserLocationTrackingModeFollow;
    self.bearingTrackingModeIndex = MTCUserBearingTrackingModeCourse;
    currentConfig.locationTrackingMode = MTCUserLocationTrackingModeFollow;
    currentConfig.bearingTrackingMode = MTCUserBearingTrackingModeCourse;
    self.mapView.userLocationConfig = currentConfig;
    [self updateRestoreFollowButtonVisibility];
}

- (void)applyMockCameraPadding {
    CGFloat topPadding = CGRectGetHeight(self.mapView.bounds) * 0.5;
    self.mapView.cameraPadding = UIEdgeInsetsMake(topPadding, 0.0, 0.0, 0.0);
}

- (void)resetMockCameraPadding {
    self.mapView.cameraPadding = UIEdgeInsetsZero;
}

- (void)configureRestoreFollowButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.hidden = YES;
    button.alpha = 0.0;
    button.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.92];
    button.tintColor = UIColor.whiteColor;
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.65] forState:UIControlStateHighlighted];
    button.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    button.layer.cornerRadius = 20.0;
    button.contentEdgeInsets = UIEdgeInsetsMake(11.0, 16.0, 11.0, 16.0);
    [button addTarget:self action:@selector(restoreFollowModes) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [button.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [button.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-20.0],
        [button.leadingAnchor constraintGreaterThanOrEqualToAnchor:safeArea.leadingAnchor constant:16.0],
        [button.trailingAnchor constraintLessThanOrEqualToAnchor:safeArea.trailingAnchor constant:-16.0],
    ]];

    self.restoreFollowButton = button;
    [self updateRestoreFollowButtonVisibility];
}

- (void)updateRestoreFollowButtonVisibility {
    BOOL shouldShow = self.followPausedByGesture && [self mockPlaybackHasStarted];
    self.restoreFollowButton.hidden = !shouldShow;
    self.restoreFollowButton.alpha = shouldShow ? 1.0 : 0.0;
}

- (NSString *)mockStatusText {
    MTCMockRouteLocationProvider *provider = self.mockLocationProvider;
    if (!provider) {
        return [self localizedStringForKey:@"location_layer_mock_status_off"];
    }

    NSString *state = [self localizedStringForKey:@"location_layer_mock_status_paused"];
    if (provider.isFinished) {
        state = [self localizedStringForKey:@"location_layer_mock_status_finished"];
    } else if (provider.isUpdating) {
        state = [self localizedStringForKey:@"location_layer_mock_status_playing"];
    } else if (provider.currentPointIndex < 0) {
        state = [self localizedStringForKey:@"location_layer_mock_status_selected"];
    }

    NSString *routeTitle = [self mockRouteTitles][(NSUInteger)self.mockRouteIndex];
    if (provider.currentPointIndex < 0) {
        return [NSString stringWithFormat:@"%@\n%@: %@\n%@: %@",
                                          routeTitle,
                                          [self localizedStringForKey:@"location_layer_mock_status_label"],
                                          state,
                                          [self localizedStringForKey:@"location_layer_mock_point_label"],
                                          [NSString stringWithFormat:@"0/%lu", (unsigned long)provider.pointCount]];
    }

    return [NSString stringWithFormat:@"%@\n%@: %@\n%@: %ld/%lu · %.1fs\n%@: %.1f km/h\n%@: %.0f°",
                                      routeTitle,
                                      [self localizedStringForKey:@"location_layer_mock_status_label"],
                                      state,
                                      [self localizedStringForKey:@"location_layer_mock_point_label"],
                                      (long)provider.currentPointIndex + 1,
                                      (unsigned long)provider.pointCount,
                                      provider.currentElapsedTime,
                                      [self localizedStringForKey:@"location_layer_mock_speed_label"],
                                      provider.currentSpeedKmh,
                                      [self localizedStringForKey:@"location_layer_mock_heading_label"],
                                      provider.currentHeading];
}

- (void)clearMockLocationProvider {
    [self.mockLocationProvider stopUpdatingLocation];
    self.mockLocationProvider.statusDidChangeHandler = nil;
    self.mockLocationProvider = nil;
    [self resetMockCameraPadding];
    self.mapView.userLocationSmoothingMode = MTCUserLocationSmoothingModeDefault;
    self.mapView.userLocationProvider = nil;
    self.followPausedByGesture = NO;
    [self updateRestoreFollowButtonVisibility];
}

- (void)showMockRoutePolylineForProvider:(MTCMockRouteLocationProvider *)provider {
    [self removeMockRoutePolyline];

    NSData *coordinateData = provider.routeCoordinateData;
    NSUInteger coordinateCount = coordinateData.length / sizeof(CLLocationCoordinate2D);
    if (coordinateCount < 2) {
        return;
    }

    MTCPolyline *polyline = [[MTCPolyline alloc] initWithCoordinates:(const CLLocationCoordinate2D *)coordinateData.bytes
                                                               count:coordinateCount];
    MTCPolylineStyle *style = [[MTCPolylineStyle alloc] init];
    style.strokeColor = [UIColor colorWithRed:0.05 green:0.48 blue:0.92 alpha:1.0];
    style.strokeWeight = 6.0;
    style.strokeOpacity = 0.82;
    style.startLineCapType = MTCLineCapTypeRound;
    style.endLineCapType = MTCLineCapTypeRound;
    style.lineJoinType = MTCLineJoinTypeRound;
    polyline.style = style;
    polyline.clickable = NO;
    polyline.draggable = NO;
    polyline.zIndex = 1;
    self.mockRoutePolyline = polyline;
    [self.mapView addOverlay:polyline];
}

- (void)removeMockRoutePolyline {
    if (!self.mockRoutePolyline) {
        return;
    }
    [self.mapView removeOverlay:self.mockRoutePolyline];
    self.mockRoutePolyline = nil;
}

- (NSArray<NSString *> *)markerBearingSourceTitles {
    return @[
        [self localizedStringForKey:@"location_layer_marker_bearing_auto"],
        [self localizedStringForKey:@"location_layer_marker_bearing_heading"],
        [self localizedStringForKey:@"location_layer_marker_bearing_course"],
        [self localizedStringForKey:@"location_layer_marker_bearing_none"],
    ];
}

- (NSArray<NSString *> *)locationTrackingModeTitles {
    return @[
        [self localizedStringForKey:@"location_layer_track_none"],
        [self localizedStringForKey:@"location_layer_track_follow"],
    ];
}

- (NSArray<NSString *> *)bearingTrackingModeTitles {
    return @[
        [self localizedStringForKey:@"location_layer_bearing_none"],
        [self localizedStringForKey:@"location_layer_bearing_north"],
        [self localizedStringForKey:@"location_layer_bearing_heading"],
        [self localizedStringForKey:@"location_layer_bearing_course"],
    ];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showLocationSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapLocationLayerController"];
    [self.restoreFollowButton setTitle:[self localizedStringForKey:@"location_layer_restore_follow"] forState:UIControlStateNormal];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showLocationSettings];
    }
}

#pragma mark - Getter & Setter

@end
