//
//  MTCMapGestureResistanceThresholdViewController.m
//  MaptecMapsExample
//
//  Created by Codex on 2026/7/14.
//

#import "MTCMapGestureResistanceThresholdViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const MTCGestureResistanceThresholdInitialLatitude = 1.3521;
static CLLocationDegrees const MTCGestureResistanceThresholdInitialLongitude = 103.8198;
static double const MTCGestureResistanceThresholdInitialZoomLevel = 11.5;

@interface MTCMapGestureResistanceThresholdViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;

@end

@implementation MTCMapGestureResistanceThresholdViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapGestureThresholdScreen;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self applyLocalizedTexts];
}

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

#pragma mark - Event

- (void)showResistanceThresholdSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self resistanceThresholdSections]];
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

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCGestureResistanceThresholdInitialLatitude,
                                                                 MTCGestureResistanceThresholdInitialLongitude)
                            zoomLevel:MTCGestureResistanceThresholdInitialZoomLevel];
}

- (NSArray<ExampleSettingsSection *> *)resistanceThresholdSections {
    MTCMapGestureSettings *settings = self.mapView.gestureSettings;

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"gesture_resist_section_pan"] items:@[
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"gesture_resist_threshold"]
                                              minimum:0.0
                                              maximum:50.0
                                                 step:1.0
                                               getter:^double { return settings.panMinimumResistance; }
                                               setter:^(double value) { settings.panMinimumResistance = value; }
                                            formatter:^NSString * _Nonnull(double value) {
                return [NSString stringWithFormat:@"%.1f px", value];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderMoveThreshold],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"gesture_resist_section_rotate"] items:@[
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"gesture_resist_threshold"]
                                              minimum:0.0
                                              maximum:50.0
                                                 step:1.0
                                               getter:^double { return settings.rotatePitchThreshold; }
                                               setter:^(double value) { settings.rotatePitchThreshold = value; }
                                            formatter:^NSString * _Nonnull(double value) {
                return [NSString stringWithFormat:@"%.1f px", value];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderRotateThreshold],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"gesture_resist_factor"]
                                              minimum:0.1
                                              maximum:5.0
                                                 step:0.1
                                               getter:^double { return settings.rotateResistance; }
                                               setter:^(double value) { settings.rotateResistance = value; }
                                            formatter:^NSString * _Nonnull(double value) {
                return [NSString stringWithFormat:@"%.1f", value];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderRotateResistance],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"gesture_resist_section_pitch"] items:@[
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"gesture_resist_threshold"]
                                              minimum:0.0
                                              maximum:50.0
                                                 step:1.0
                                               getter:^double { return settings.pitchThreshold; }
                                               setter:^(double value) { settings.pitchThreshold = value; }
                                            formatter:^NSString * _Nonnull(double value) {
                return [NSString stringWithFormat:@"%.1f px", value];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderShoveThreshold],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"gesture_resist_factor"]
                                              minimum:0.1
                                              maximum:5.0
                                                 step:0.1
                                               getter:^double { return settings.pitchResistance; }
                                               setter:^(double value) { settings.pitchResistance = value; }
                                            formatter:^NSString * _Nonnull(double value) {
                return [NSString stringWithFormat:@"%.1f", value];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderShoveResistance],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"common_section_description"] items:@[
            [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"gesture_resist_info"]],
        ]],
    ];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showResistanceThresholdSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapGestureResistanceThresholdViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showResistanceThresholdSettings];
    }
}
@end
