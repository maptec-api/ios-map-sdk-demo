//
//  MTCMapGestureInertialScrollDurationViewController.m
//  MaptecMapsExample
//
//  Created by Codex on 2026/7/14.
//

#import "MTCMapGestureInertialScrollDurationViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const MTCGestureInertialScrollDurationInitialLatitude = 1.3521;
static CLLocationDegrees const MTCGestureInertialScrollDurationInitialLongitude = 103.8198;
static double const MTCGestureInertialScrollDurationInitialZoomLevel = 11.5;

@interface MTCMapGestureInertialScrollDurationViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;

@end

@implementation MTCMapGestureInertialScrollDurationViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapGestureInertialScrollDurationScreen;

    [self configureNavigationItems:NO];
    [self configureMapView];
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

- (void)showInertialScrollDurationSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self inertialScrollDurationSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:NO];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCGestureInertialScrollDurationInitialLatitude,
                                                                 MTCGestureInertialScrollDurationInitialLongitude)
                            zoomLevel:MTCGestureInertialScrollDurationInitialZoomLevel];
}

- (NSArray<ExampleSettingsSection *> *)inertialScrollDurationSections {
    MTCMapGestureSettings *settings = self.mapView.gestureSettings;

    return @[
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"gesture_inertial_enable"]
                                            getter:^BOOL { return settings.inertialScrollEnabled; }
                                            setter:^(BOOL value) { settings.inertialScrollEnabled = value; }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"gesture_inertial_duration"]
                                             minimum:0.0
                                             maximum:5.0
                                                step:0.05
                                              getter:^double { return settings.inertialDuration; }
                                              setter:^(double value) { settings.inertialDuration = value; }
                                           formatter:^NSString * _Nonnull(double value) {
                return [NSString stringWithFormat:@"%.0f ms", value * 1000.0];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderInertialScrollDuration],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"gesture_inertial_velocity"]
                                            minimum:0.0
                                            maximum:5000.0
                                               step:50.0
                                             getter:^double { return settings.inertialScrollMinimumVelocity; }
                                             setter:^(double value) { settings.inertialScrollMinimumVelocity = value; }
                                          formatter:^NSString * _Nonnull(double value) {
                return [NSString stringWithFormat:@"%.0f pt/s", value];
            }],
            [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"gesture_inertial_info"]],
        ]],
    ];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showInertialScrollDurationSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapGestureInertialScrollDurationViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showInertialScrollDurationSettings];
    }
}
@end
