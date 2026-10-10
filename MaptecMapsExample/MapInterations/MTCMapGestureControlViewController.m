//
//  MTCMapGestureControlViewController.m
//  MaptecMapsExample
//
//  Created by Codex on 2026/7/13.
//

#import "MTCMapGestureControlViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const MTCGestureControlInitialLatitude = 1.3521;
static CLLocationDegrees const MTCGestureControlInitialLongitude = 103.8198;
static double const MTCGestureControlInitialZoomLevel = 11.5;

@interface MTCMapGestureControlViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;

@end

@implementation MTCMapGestureControlViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapGestureControlScreen;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureDefaultGestureSettings];
    [self applyLocalizedTexts];
}

#pragma mark - Event

- (void)showGestureControlSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"gesture_control_sheet_title"]
                                               sections:[self gestureControlSections]];
    [sheet showInView:self.view animated:NO];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    self.mapTestSupport.overlayCountValueKey = MTCExampleTestAccessibilityMarkerCountValueKey;
    [self.mapTestSupport installOnHostView:self.view];
    [self.mapTestSupport syncOverlayCount:0];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCGestureControlInitialLatitude, MTCGestureControlInitialLongitude)
                            zoomLevel:MTCGestureControlInitialZoomLevel];
}

- (void)configureDefaultGestureSettings {
    MTCMapGestureSettings *settings = self.mapView.gestureSettings;
    settings.enabled = YES;
    settings.panEnabled = YES;
    settings.pitchEnabled = YES;
    settings.rotateEnabled = YES;
    settings.pinchZoomEnabled = YES;
    settings.doubleTapZoomEnabled = YES;
}

- (NSArray<ExampleSettingsSection *> *)gestureControlSections {
    MTCMapGestureSettings *settings = self.mapView.gestureSettings;
    ExampleSettingsVisibleGetter enabledVisible = ^BOOL{
        return settings.enabled;
    };

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"gesture_control_section_switches"] items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"gesture_control_enable_all"]
                                            getter:^BOOL { return settings.enabled; }
                                            setter:^(BOOL value) { settings.enabled = value; }]
                withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchAllGesture],
            [[[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"gesture_control_enable_pan"]
                                             getter:^BOOL { return settings.panEnabled; }
                                             setter:^(BOOL value) { settings.panEnabled = value; }] visibleWhen:enabledVisible]
                withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchScrollGesture],
            [[[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"gesture_control_enable_pitch"]
                                             getter:^BOOL { return settings.pitchEnabled; }
                                             setter:^(BOOL value) { settings.pitchEnabled = value; }] visibleWhen:enabledVisible]
                withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchTiltGesture],
            [[[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"gesture_control_enable_rotate"]
                                             getter:^BOOL { return settings.rotateEnabled; }
                                             setter:^(BOOL value) { settings.rotateEnabled = value; }] visibleWhen:enabledVisible]
                withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchRotateGesture],
            [[[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"gesture_control_enable_two_finger_zoom"]
                                             getter:^BOOL { return settings.pinchZoomEnabled; }
                                             setter:^(BOOL value) { settings.pinchZoomEnabled = value; }] visibleWhen:enabledVisible]
                withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchDoubleFingerZoomGesture],
            [[[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"gesture_control_enable_double_tap_zoom"]
                                             getter:^BOOL { return settings.doubleTapZoomEnabled; }
                                             setter:^(BOOL value) { settings.doubleTapZoomEnabled = value; }] visibleWhen:enabledVisible]
                withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchDoubleClickZoomGesture],
        ]],
    ];
}

#pragma mark - MTCMapViewDelegate

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

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showGestureControlSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapGestureControlViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showGestureControlSettings];
    }
}

@end
