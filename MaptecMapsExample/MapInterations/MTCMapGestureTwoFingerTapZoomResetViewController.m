#import "MTCMapGestureTwoFingerTapZoomResetViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const MTCGestureTwoFingerTapZoomResetInitialLatitude = 1.3521;
static CLLocationDegrees const MTCGestureTwoFingerTapZoomResetInitialLongitude = 103.8198;
static double const MTCGestureTwoFingerTapZoomResetInitialZoomLevel = 11.5;

@interface MTCMapGestureTwoFingerTapZoomResetViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;

@end

@implementation MTCMapGestureTwoFingerTapZoomResetViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapGestureTwoFingerTapZoomResetScreen;

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

- (void)showTwoFingerTapZoomResetSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self twoFingerTapZoomResetSections]];
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

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCGestureTwoFingerTapZoomResetInitialLatitude,
                                                                 MTCGestureTwoFingerTapZoomResetInitialLongitude)
                            zoomLevel:MTCGestureTwoFingerTapZoomResetInitialZoomLevel];
}

- (NSArray<ExampleSettingsSection *> *)twoFingerTapZoomResetSections {
    MTCMapGestureSettings *settings = self.mapView.gestureSettings;

    return @[
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"gesture_two_finger_tap_enable"]
                                             getter:^BOOL { return settings.doubleTapZoomResetEnabled; }
                                             setter:^(BOOL value) { settings.doubleTapZoomResetEnabled = value; }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderTwoFingerTapZoomReset],
            [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"gesture_two_finger_tap_info"]],
        ]],
    ];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showTwoFingerTapZoomResetSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapGestureTwoFingerTapZoomResetViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showTwoFingerTapZoomResetSettings];
    }
}
@end
