#import "MTCMapGestureZoomCenterModeViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const MTCGestureZoomCenterInitialLatitude = 1.3521;
static CLLocationDegrees const MTCGestureZoomCenterInitialLongitude = 103.8198;
static double const MTCGestureZoomCenterInitialZoomLevel = 11.5;

@interface MTCMapGestureZoomCenterModeViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;

@end

@implementation MTCMapGestureZoomCenterModeViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapGestureZoomCenterModeScreen;

    [self configureNavigationItems:NO];
    [self configureMapView];
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

#pragma mark - Event

- (void)showZoomCenterModeSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self zoomCenterModeSections]];
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

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCGestureZoomCenterInitialLatitude,
                                                                 MTCGestureZoomCenterInitialLongitude)
                            zoomLevel:MTCGestureZoomCenterInitialZoomLevel];
}

- (NSArray<ExampleSettingsSection *> *)zoomCenterModeSections {
    MTCMapGestureSettings *settings = self.mapView.gestureSettings;

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"gesture_zoom_center_section"] items:@[
            [[ExampleSettingsItem radioItemWithTitle:[self localizedStringForKey:@"gesture_zoom_center_gesture"]
                                             getter:^BOOL {
                return settings.zoomCenterMode == MTCMapGestureZoomCenterModeGestureCenter;
            } setter:^(BOOL value) {
                if (value) {
                    settings.zoomCenterMode = MTCMapGestureZoomCenterModeGestureCenter;
                }
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityRadioZoomCenterGesture],
            [[ExampleSettingsItem radioItemWithTitle:[self localizedStringForKey:@"gesture_zoom_center_screen"]
                                             getter:^BOOL {
                return settings.zoomCenterMode == MTCMapGestureZoomCenterModeScreenCenter;
            } setter:^(BOOL value) {
                if (value) {
                    settings.zoomCenterMode = MTCMapGestureZoomCenterModeScreenCenter;
                }
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityRadioZoomCenterScreen],
            [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"gesture_zoom_center_info"]],
        ]],
    ];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showZoomCenterModeSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapGestureZoomCenterModeViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showZoomCenterModeSettings];
    }
}
@end
