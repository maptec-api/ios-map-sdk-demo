//
//  MTCMapGestureRotateBearingRangeViewController.m
//  MaptecMapsExample
//
//  Created by Codex on 2026/7/14.
//

#import "MTCMapGestureRotateBearingRangeViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const MTCGestureRotateBearingRangeInitialLatitude = 1.3521;
static CLLocationDegrees const MTCGestureRotateBearingRangeInitialLongitude = 103.8198;
static double const MTCGestureRotateBearingRangeInitialZoomLevel = 11.5;
static CLLocationDirection const MTCGestureRotateBearingRangeInitialBearing = 20.0;

static double MTCGestureRotateBearingRangeNormalize(double bearing) {
    double normalized = fmod(bearing, 360.0);
    if (normalized < 0.0) {
        normalized += 360.0;
    }
    return normalized;
}

@interface MTCMapGestureRotateBearingRangeViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic) CLLocationDirection currentBearing;
@property (nonatomic) CLLocationDirection minimumBearing;
@property (nonatomic) CLLocationDirection maximumBearing;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;

@end

@implementation MTCMapGestureRotateBearingRangeViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapGestureRotateBearingRangeScreen;
    self.currentBearing = MTCGestureRotateBearingRangeInitialBearing;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureInitialBearingRange];
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
    (void)reason;
    (void)animated;
    if (mapView != self.mapView) {
        return;
    }

    self.currentBearing = MTCGestureRotateBearingRangeNormalize(camera.bearing);
    [self.settingsSheet reloadData];
}

#pragma mark - Event

- (void)showBearingRangeSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self bearingRangeSections]];
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

    MTCMapCamera *initialCamera =
        [MTCMapCamera cameraWithCenterCoordinate:CLLocationCoordinate2DMake(MTCGestureRotateBearingRangeInitialLatitude,
                                                                           MTCGestureRotateBearingRangeInitialLongitude)
                                       zoomLevel:MTCGestureRotateBearingRangeInitialZoomLevel
                                         bearing:MTCGestureRotateBearingRangeInitialBearing
                                           pitch:0.0];
    [self.mapView setCamera:initialCamera transition:nil completion:nil];
}

- (void)configureInitialBearingRange {
    MTCMapBearingRange range = self.mapView.cameraConstraints.bearingRange;
    self.minimumBearing = range.startBearing;
    self.maximumBearing = range.endBearing;
}

- (NSArray<ExampleSettingsSection *> *)bearingRangeSections {
    __weak typeof(self) weakSelf = self;

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"gesture_bearing_section"] items:@[
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString * _Nonnull {
                __strong typeof(weakSelf) self = weakSelf;
                return [NSString stringWithFormat:[self localizedStringForKey:@"gesture_bearing_current"], self.currentBearing];
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"gesture_bearing_min"]
                                            minimum:0.0
                                            maximum:360.0
                                               step:1.0
                                             getter:^double {
                __strong typeof(weakSelf) self = weakSelf;
                return self.minimumBearing;
            } setter:^(double value) {
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) {
                    return;
                }
                self.minimumBearing = value;
                [self applyBearingRange];
            } formatter:^NSString * _Nonnull(double value) {
                return [NSString stringWithFormat:@"%.1f°", value];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderRotateBearingMin],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"gesture_bearing_max"]
                                            minimum:0.0
                                            maximum:360.0
                                               step:1.0
                                             getter:^double {
                __strong typeof(weakSelf) self = weakSelf;
                return self.maximumBearing;
            } setter:^(double value) {
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) {
                    return;
                }
                self.maximumBearing = value;
                [self applyBearingRange];
            } formatter:^NSString * _Nonnull(double value) {
                return [NSString stringWithFormat:@"%.1f°", value];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderRotateBearingMax],
            [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"gesture_bearing_info"]],
        ]],
    ];
}

- (void)applyBearingRange {
    self.mapView.cameraConstraints.bearingRange = MTCMapBearingRangeMake(self.minimumBearing, self.maximumBearing);
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showBearingRangeSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapGestureRotateBearingRangeViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showBearingRangeSettings];
    }
}
@end
